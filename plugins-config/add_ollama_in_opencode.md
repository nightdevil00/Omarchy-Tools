# Add local Ollama models to opencode

Step-by-step guide for a machine with **no Ollama and no CUDA installed yet**.
Tested on an Arch-based system (Omarchy), with notes for other distros.

---

## 0. What you end up with

- A local chat API (`http://localhost:11434/v1`) served by Ollama.
- Local models like Qwen 3 8B, Gemma 3 4B, Mistral Nemo 12B.
- opencode configured to use them as chat models, with tool calling enabled.

---

## 1. Check your GPU

Ollama works 100% on CPU too (slower). A discrete NVIDIA GPU gives a big speedup.

```bash
lspci | grep -iE "vga|3d|display"   # find your GPU
nvidia-smi                          # works later, after the driver is installed
```

- **NVIDIA** GPU -> follow Step 2 and 3 (driver + CUDA).
- **AMD/Intel** GPU or no GPU -> skip CUDA; Ollama falls back to CPU or Vulkan automatically.

Check your VRAM: `nvidia-smi` shows `Memory-Usage`. As a rule of thumb:

| VRAM / RAM       | Good model sizes                                  |
| ---------------- | ------------------------------------------------ |
| 4 GB VRAM + 16 GB RAM | 3–4B fully on GPU, 7–8B with partial offload |
| 8 GB VRAM        | 7–8B fully on GPU, 12B partial offload           |
| No GPU           | 3–4B CPU-only is comfortable, 8B is slow          |

---

## 2. Install the NVIDIA driver

Arch:

```bash
sudo pacman -S nvidia nvidia-utils
sudo reboot
```

Debian/Ubuntu:

```bash
sudo apt install nvidia-driver nvidia-utils
sudo reboot
```

Verify after reboot:

```bash
nvidia-smi   # shows GPU, driver version, VRAM
```

> You need a GPU driver that exposes CUDA. Ollama **bundles its own CUDA runtime libraries**, so a working `nvidia-smi` is usually enough — you do not need the full CUDA Toolkit for Ollama to use the GPU.

---

## 3. Install the CUDA Toolkit (optional, for other CUDA apps)

Skip this if you only use Ollama — its bundled CUDA libs are enough.

Arch:

```bash
sudo pacman -S cuda
```

For other distros, follow the NVIDIA repo installer for your distro:
<https://developer.nvidia.com/cuda-downloads>

Verify:

```bash
nvcc --version
```

---

## 4. Install Ollama

**Arch (recommended, from the official repos):**

```bash
sudo pacman -S ollama
```

**Any other Linux distro (install script):**

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**Windows/macOS:** download the installer from <https://ollama.com/download>.

---

## 5. Start and enable the Ollama service

Arch (systemd unit ships with the `ollama` package; other distros the install script adds it too):

```bash
sudo systemctl enable --now ollama
```

If your distro has no systemd, just run it in a terminal:

```bash
ollama serve
```

Check it is up:

```bash
curl http://localhost:11434            # -> "Ollama is running"
ollama list                            # empty the first time
```

---

## 6. Pull models

```bash
# Strong small coding model (tool calling + reasoning). ~5.2 GB.
ollama pull qwen3:8b

# Fast general model that fits in 4 GB VRAM. ~3.3 GB.
ollama pull gemma3:4b

# Bigger reasoning model, CPU-friendly. ~7.1 GB.
ollama pull mistral-nemo:12b

# Tiny embedding model for RAG. ~274 MB.
ollama pull nomic-embed-text
```

Sizes assume the default 4-bit quant. See Appendix A for choosing other tags.

---

## 7. Configure opencode

Create/open the global config:

```bash
mkdir -p ~/.config/opencode
$EDITOR ~/.config/opencode/opencode.json
```

Paste a minimal config:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (local)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
      },
      "models": {
        "qwen3:8b": {
          "name": "Qwen 3 8B (local, 32K)",
          "tool_call": true,
          "reasoning": true,
          "limit": { "context": 32768, "output": 8192 }
        },
        "gemma3:4b": {
          "name": "Gemma 3 4B (local, 32K)",
          "tool_call": true,
          "reasoning": false,
          "limit": { "context": 32768, "output": 8192 }
        },
        "mistral-nemo:12b": {
          "name": "Mistral Nemo 12B (local, 32K)",
          "tool_call": true,
          "reasoning": false,
          "limit": { "context": 32768, "output": 8192 }
        }
      }
    }
  },
  "small_model": "ollama/gemma3:4b"
}
```

Field notes:

- `model` / `small_model` always use a `provider/model-id` form. `small_model` is used by opencode for cheap background calls like generating titles and summaries — point it at your fastest small model.
- `tool_call: true` lets the model use opencode's tools (edit, bash, ...). Qwen 3 and Gemma 3 support it; when in doubt set it to `true`.
- `reasoning: true` enables thinking output if the model has it (Qwen 3's thinking mode). Mistral Nemo and Gemma 3 do not.
- `limit.context` caps how much context you give the model. Values like 32768 stay responsive on a 4 GB GPU; 65536+ gets slow.
- Make sure you add `"$schema": "https://opencode.ai/config.json"` — your editor then validates mistakes for you.

---

## 8. Restart opencode

Config is read once at startup — it is **not** hot-reloaded.

1. Quit opencode completely.
2. Start it again.
3. Use the model switcher (`mc` in the TUI) or prefix models as `ollama/qwen3:8b`.

If opencode refuses to start because of a config typo:

```bash
OPENCODE_DISABLE_PROJECT_CONFIG=1 opencode   # start with global config only, fix the file
```

---

## 9. Verify the models actually run

Quick sanity checks outside opencode:

```bash
# Straight chat call:
ollama run qwen3:8b "say hi"

# Which layers landed on the GPU? (during/after a request)
ollama ps
```

If all layers show `CPU`, the GPU driver/CUDA path is not detected — Step 2/3, or accept CPU speed.

---

## Appendix A — Picking model tags

Ollama tags are `model:quant`. Smaller quant = smaller file, faster, slightly dumber.

```bash
ollama pull qwen3:8b      # default ~4.7 GB, good balance
ollama pull qwen3:8b-q4_K_M    # explicit 4-bit
ollama pull qwen3:8b-q3_K_M    # even smaller
```

Check what sizes exist with `ollama show qwen3:8b`.

Coding-focused options (small hardware): `qwen2.5-coder:7b`, `qwen3:8b`,
`deepseek-r1:8b` (reasoning-heavy). General: `gemma3:4b`, `llama3.2:3b`.

Skip anything >= 14B on a 4 GB VRAM / 16 GB RAM laptop unless you accept CPU-only speed.

---

## Appendix B — Troubleshooting

| Symptom                                  | Fix                                                                 |
| ---------------------------------------- | ------------------------------------------------------------------- |
| `curl :11434` fails                      | Ollama not running: `sudo systemctl start ollama` or `ollama serve` |
| opencode shows model errors / refuses to start | Check JSON syntax: `jq empty ~/.config/opencode/opencode.json` |
| Very slow output                         | Model too big for VRAM; drop to a smaller model or a `-q3_K_M` tag  |
| All layers `CPU` in `ollama ps`          | Driver/CUDA not detected; redo Step 2 or install CUDA runtime       |
| Tool calls don't work                    | Ensure `"tool_call": true` on that model                            |