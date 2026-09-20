# Maple Preview in opencode - setup notes

Date: 2026-09-18

## Goal

Run deepgrove Maple Preview (20B-A1B MoE reasoning model) locally and use it
in opencode as model `maple/maple-preview`.

## Why plain Ollama does not work

- `ollama pull hf.co/deepgrove/maple-preview-GGUF:latest` downloads fine, but
  loading fails with:
  `unsupported tensor "blk.0.ffn_down_exps.weight" size overflows`
- Ollama 0.34.1 fetched the TQ1_0 + FP16 variant (5.4 GB blob, sha256
  c20ecf619b2f...) while the intended file was TQ2_0 + Q4_K head (5.9 GB).
- Even the right variant would not load: the model uses custom ternary
  quantization (TQ1_0/TQ2_0) and a custom "maple" architecture that only the
  deepgrove llama.cpp fork implements.
- The model card points to https://github.com/deepgrove-ai/llama.cpp for a
  custom build; Ollama cannot run it.

## Hardware note

This machine is x86_64 (Intel i7-10750H, 6C/12T, 16 GB RAM, no discrete GPU
used). The fork's README shows M5 Pro numbers; on this CPU decode runs at
about 27-30 tokens/s, prompt eval about 100 tokens/s, with 6 threads.

## Step 1: build the fork

```bash
python3 -m venv /tmp/opencode/maple-build-env
/tmp/opencode/maple-build-env/bin/pip install cmake
git clone --depth 1 https://github.com/deepgrove-ai/llama.cpp.git \
  ~/.local/share/maple-llama.cpp
cd ~/.local/share/maple-llama.cpp
/tmp/opencode/maple-build-env/bin/cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_METAL=OFF \
  -DLLAMA_BUILD_TESTS=OFF \
  -DLLAMA_BUILD_EXAMPLES=OFF \
  -DLLAMA_BUILD_SERVER=ON
/tmp/opencode/maple-build-env/bin/cmake --build build --target llama-server -j 6
```

Notes:

- There are no GitHub releases for the fork, so building from source is the
  only option (docker images referenced in docs are the upstream ggml-org
  images, which do not include the maple changes).
- cmake came from pip because the system had none; build tools g++/make were
  already installed.
- The first build attempt hit the bash tool timeout mid-compile; re-running
  the same build command resumed and finished (llama-server built OK).
- Build tree at commit 7e30f3a (ggml 0.18.1). Binary:
  `~/.local/share/maple-llama.cpp/build/bin/llama-server`
- The build also compiles a web UI with npm/vite, which is slow; most of the
  build time went there. `--no-webui` disables it at runtime.

## Step 2: download the GGUF

Pulled the exact file by URL instead of via ollama (which had grabbed the
wrong variant):

```bash
curl -fL -o ~/.local/share/maple-llama.cpp/models/maple-preview-TQ2_0-head-Q4_K.gguf \
  https://huggingface.co/deepgrove/maple-preview-GGUF/resolve/main/maple-preview-TQ2_0-head-Q4_K.gguf
sha256sum ~/.local/share/maple-llama.cpp/models/maple-preview-TQ2_0-head-Q4_K.gguf
```

Checksum verified against HF metadata:
221f792cc9760d27a34f449b4229e258fa968a63bd4213993e45d9c0bb477a9e

Variant rationale: TQ2_0 is the faster decoding ternary packing (slightly
more RAM than TQ1_0); Q4_K LM head is much faster to decode than FP16.

## Step 3: run llama-server as a systemd user service

Created `~/.config/systemd/user/maple-preview.service`:

```ini
[Unit]
Description=Maple Preview local model server
After=network.target

[Service]
ExecStart=/home/mihai/.local/share/maple-llama.cpp/build/bin/llama-server -m /home/mihai/.local/share/maple-llama.cpp/models/maple-preview-TQ2_0-head-Q4_K.gguf --alias maple-preview --host 127.0.0.1 --port 8081 --ctx-size 32768 --parallel 1 --threads 6 --threads-batch 6 --n-gpu-layers 0 --jinja --temp 1.0 --top-p 0.95 --reasoning-format deepseek --no-webui --sleep-idle-seconds 300
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
```

Then:

```bash
systemctl --user daemon-reload
systemctl --user enable --now maple-preview.service
```

Flag notes:

- `--jinja` applies Maple's embedded chat template, including the forced
  reasoning prefix (think tag) on the assistant turn.
- `--temp 1.0 --top-p 0.95` are the sampling parameters from the model card.
- `--reasoning-format deepseek` moves thinking into `reasoning_content`, so
  chat clients get clean content plus separate reasoning.
- `--ctx-size 32768` with `--parallel 1`: 32K context for one slot, sized to
  RAM. The model supports 128K natively; raise ctx if you have RAM headroom.
- `--threads 6` = physical cores (llama.cpp guidance: SMT siblings usually
  do not help); `--threads-batch 6` for prompt processing.
- `--n-gpu-layers 0` forces CPU (no usable discrete GPU here).
- `--no-webui` skips serving the bundled web UI.
- `--sleep-idle-seconds 300` unloads/daemon-sleeps after 5 idle minutes so
  the 6 GB resident set does not sit in RAM when not used; it reloads on the
  next request.
- Server listens on 127.0.0.1:8081 only (localhost).

## Step 4: verify the API directly

```bash
curl http://127.0.0.1:8081/health
# {"status":"ok"}

curl http://127.0.0.1:8081/v1/chat/completions -H 'Content-Type: application/json' \
  -d '{"model":"maple-preview","messages":[{"role":"user","content":"Reply with only hello."}],"max_tokens":128,"temperature":0}'
```

Confirmed:

- plain chat works: content `hello`, reasoning separated into
  `reasoning_content` by the server
- OpenAI tool calling works: sent a `calculator` tool definition, model
  answered `finish_reason: tool_calls` with a proper
  `{"a": 13, "b": 29}` arguments object
- `/v1/models` reports the model as `maple-preview`, n_ctx 32768,
  20214030336 params, "TQ2_0 - 2.06 bpw ternary"

## Step 5: wire it into opencode

In `~/.config/opencode/opencode.json` a custom OpenAI-compatible provider was
added (per opencode docs, llama.cpp section):

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "maple": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Maple Preview (local)",
      "options": {
        "baseURL": "http://127.0.0.1:8081/v1"
      },
      "models": {
        "maple-preview": {
          "name": "Maple Preview 20B-A1B (llama.cpp, 32K)",
          "tool_call": true,
          "reasoning": true,
          "interleaved": { "field": "reasoning_content" },
          "limit": { "context": 32768, "output": 8192 }
        }
      }
    }
  }
}
```

Notes:

- `maple` is an arbitrary provider id; model reference is `maple/maple-preview`
- the model id `maple-preview` matches the server `--alias`
- `interleaved.field: reasoning_content` maps the llama.cpp reasoning field
  into opencode's thinking channel
- `limit.context` matches the server's 32K ctx; `limit.output` 8192
- earlier the same model had been added under the `ollama` provider; that
  entry was removed since Ollama cannot load this GGUF at all

## Step 6: use it

- restart opencode (config is only read at startup)
- `/models`, pick provider `Maple Preview (local)` and model
  `maple/maple-preview`, or set `"model": "maple/maple-preview"` in config
- first request after idle sleeps takes a few extra seconds while the model
  reloads

## Operations

```bash
systemctl --user status maple-preview.service    # state
systemctl --user restart maple-preview.service   # restart
journalctl --user -u maple-preview.service -f    # logs
```

Measured on this machine (6 threads, 32K ctx):

- prompt eval: ~100 tok/s
- decode: ~27-30 tok/s
- resident memory while loaded: ~6 GB

## Cleanup options (not done)

- `ollama rm hf.co/deepgrove/maple-preview-GGUF` would free the 5.4 GB
  Ollama blob of the wrong variant (kept for now)
- the venv at /tmp/opencode/maple-build-env is only needed for rebuilds and
  disappears on reboot anyway
