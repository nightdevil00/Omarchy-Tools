# Laya MCP → opencode

Setup record for wiring the **Laya** decision model into opencode as an MCP server.

- **Date:** 2026-09-26
- **Host:** Arch / Omarchy, Python 3.14.7, NVIDIA GTX 1650 Ti (Max-Q, 4 GB VRAM)
- **Status:** `opencode mcp list` reports `✓ laya connected`

---

## 1. What got installed

| Piece | Version | Location |
|---|---|---|
| `python-pipx` | 1.15.0 | system pacman package |
| `laya-mcp` | 0.2.2 | `~/.local/share/pipx/venvs/laya-mcp/` (1.2 GB) |
| `laya` (upstream, by Convai) | 0.3.20 | same venv |
| `torch` | 2.14.0**+cpu** | same venv, CPU-only build |
| `transformers` | 5.17.0 | same venv |
| `mcp` SDK | 1.30.0 | same venv |
| `convaiinnovations/laya` checkpoint | `english` | `~/.cache/huggingface/` (2.3 GB) |

The venv lives at `~/.local/share/pipx/venvs/laya-mcp/`, **not** `.../venvs/laya/` —
pipx names the directory after the package, and the package is `laya-mcp`.

`laya-mcp` on PyPI is a third-party integration layer (Apache-2.0, by PerryLink).
`laya` is the upstream research model. They are related but separate projects.

---

## 2. The config that was requested vs. what shipped

The original snippet was:

```json
"laya-mcp": {
  "type": "local",
  "command": ["~/.local/share/pipx/venvs/laya/bin/laya-mcp-server"],
  "disabled": true,
  "environment": { "LAYA_DEVICE": "cuda" }
}
```

Five things were wrong with it.

### 2.1 `disabled: true` is not an opencode key

opencode's toggle is `enabled`, not `disabled`. **A `disabled` key is silently
ignored** — the server would have run anyway, with no error to explain why. The
`laya-mcp` README calls out this exact trap for opencode specifically, since
every other harness it targets uses different spellings.

Fixed: `enabled: true`.

### 2.2 `LAYA_DEVICE=cuda` is not read by anything

Grepping the whole installed package for `os.environ` / `getenv` turns up exactly
one environment variable: `LOCALAPPDATA`, on Windows, for locating `HERMES_HOME`.
There is no `LAYA_DEVICE`.

Device selection is a **CLI flag**, not an environment variable:
`--device cpu|cuda|mps`, defaulting to `auto`. Because opencode spawns the
server with a fixed argv and no shell, the flag would have to be appended to
`command`.

Fixed: the `environment` block was removed entirely. See §5 if you want CUDA.

### 2.3 The binary name was a different server — and an incompatible one

`laya-mcp-server` **does exist**, so this was not a typo. It is provided by the
`laya` package (entry point `laya.mcp.server:main`), i.e. upstream Laya's own
bare MCP server — a *different* program from the `laya-mcp` integration.

The two cannot coexist in one environment:

| Package | Requires | Result |
|---|---|---|
| `laya-mcp[mcp]` | `mcp>=1.28,<2` | installs `mcp` **1.30.0** |
| `laya[mcp]` | `mcp>=2.2.0` | **incompatible** — mutually exclusive |

Running `laya-mcp-server` in the `laya-mcp` venv fails immediately:

```
ModuleNotFoundError: No module named 'mcp.server.mcpserver'
ImportError: the laya[mcp] extra (mcp>=2.2.0) is required to run the MCP server
```

**The integration (`laya-mcp`) was chosen** because it is a strict superset of
the bare server for agent use: token-budget preflight (`laya_plan`), structured
errors that name the failing question, a persisted calibration store, device-demotion
reporting, serialised inference, `--sidecar`, a `doctor` command, and an
`install` command that writes the correct config for whichever harness it finds.
It also advertises the same five tools the bare server exposes.

### 2.4 The `[mcp]` extra is mandatory

`laya-mcp` declares `mcp` as an *optional* extra. A plain `pipx install laya-mcp`
silently skips it and the server cannot start. The install had to be:

```bash
pipx install 'laya-mcp[mcp]'
```

### 2.5 `timeout` had to be raised

opencode's default MCP tool-fetch timeout is **5000 ms**. Measured on this host:

| Phase | Cold (first run) | Warm |
|---|---|---|
| `initialize` | model download, tens of seconds | 1.73 s |
| `tools/list` | — | 0.01 s |
| first `tools/call` | model load + forward pass | ~10 s |

1.73 s is uncomfortably close to 5 s, and a cold HuggingFace cache blows straight
past it. Set to `timeout: 120000` (120 s).

---

## 3. The commands actually run

```bash
# 1. pipx is not in Arch's repo under that name; it is python-pipx
sudo pacman -S --needed python-pipx

# 2. Force the CPU-only torch build.
#    The default PyPI torch for linux-x86_64 is a CUDA build that drags in
#    ~2.5 GB of nvidia-* wheels and can collide with Arch's system driver.
#    The constraint pins the +cpu local version so pip cannot fall back to
#    the CUDA wheel (both are version 2.14.0; PEP 440 orders +cpu higher).
printf 'torch==2.14.0+cpu\n' > /tmp/opencode/laya-constraints.txt

pipx install 'laya-mcp[mcp]' \
  --pip-args="--extra-index-url https://download.pytorch.org/whl/cpu \
              --constraint=/tmp/opencode/laya-constraints.txt"
```

Verified afterwards: `torch 2.14.0+cpu`, and **zero** `nvidia-*` / `triton`
packages in the venv.

---

## 4. The shipped config

Added to `~/.config/opencode/opencode.json` (existing `provider` blocks untouched):

```json
"mcp": {
  "laya": {
    "type": "local",
    "command": [
      "/home/mihai/.local/share/pipx/venvs/laya-mcp/bin/python",
      "-m",
      "laya_mcp",
      "mcp"
    ],
    "enabled": true,
    "timeout": 120000
  }
}
```

Notes on the shape:

- The command is the venv's **interpreter running `-m laya_mcp mcp`**, not the
  `laya-mcp` console script. The package's own installer does this deliberately:
  on Windows the console script is a `.cmd` shim that the MCP SDK cannot spawn
  with `shell: false`. Same reasoning is harmless here and survives a rebuild.
- **Absolute paths**, not `~`. `command` is exec'd directly, so tilde expansion
  is not guaranteed.
- `enabled: true` is the default, stated explicitly for clarity.
- No `environment` block — §2.2.

**Restart opencode to pick this up.** Config is read once at startup; a running
session keeps its loaded copy.

---

## 5. Verification

```bash
opencode mcp list
```

```
●  ✓ laya connected
     /home/mihai/.local/share/pipx/venvs/laya-mcp/bin/python -m laya_mcp mcp
```

A full protocol handshake was also run directly against the venv's MCP SDK
(`initialize` → `tools/list` → `tools/call`). All five tools listed and
`laya_plan` returned a real result:

```
server: laya 1.30.0
tools: 5
  - laya_ask      batch of typed questions over one state
  - laya_noul     one yes/no question -> P(true) + band
  - laya_choice   one multiple-choice question -> label + distribution
  - laya_score    one ordered-scale question
  - laya_plan     "will this fit, what gets cut?" - no forward pass
```

`laya-mcp doctor`:

```
laya-mcp 0.2.2
python   3.14.7
packages laya 0.3.20 / torch 2.14.0+cpu / transformers 5.17.0
device   cuda  unavailable, inference would run on CPU
```

---

## 6. Tools exposed to the model

| Tool | Answers |
|---|---|
| `laya_ask` | a batch of typed questions over one state — the general one |
| `laya_noul` | one yes/no question; returns `P(true)` and a yes/no/uncertain band |
| `laya_choice` | one multiple-choice question; returns the label and the distribution |
| `laya_score` | one ordered-scale question |
| `laya_plan` | what would be truncated, and how many tokens each option really gets — **no forward pass** |

---

## 7. Read this before trusting its output

Reproduced from the upstream documentation, because a decision model that sounds
confident and is wrong is worse than no model. These are the package authors'
own numbers, not a disclaimer added here:

- **The base checkpoints are near chance zero-shot on typed decisions** — 0.362
  (English) against a **0.461 majority-class baseline**. Guessing the most common
  answer beats the model.
- `score` is the weakest primitive: 35% against a 70% reference on a five-level
  ordinal task.
- **`confidence` is not accuracy.** It is `1 - H(p)/log(k)` for `choice`/`score`
  and `max(p, 1-p)` for `noul`. A threshold on it does not mean what it looks like.
- The installed checkpoint logs this on every load:
  `this checkpoint ships invalid temperatures or values outside [0.5, 5] ...
  Treat confidence from the affected entries as uncalibrated.`
- Calibration needs labelled data. Raw ECE is 0.466 (English) / 0.314
  (multilingual), improving to 0.081 / 0.106 only after fitting temperatures
  against your own labels.
- Position bias is real — one published fixture answered "A" on 46 of 50
  multiple-choice items.
- Accuracy falls off above ~20 options.
- A decision model asked to write prose produces nothing useful. Every tool
  description says what it is *not* for.

Calibration makes a probability honest; it cannot make a model right. If the
accuracy is not there for your task, fit on your own domain or do not deploy it.

---

## 8. Optional: sidecar mode

A harness spawns one stdio server **per session**, so the default pays the model
load every time. To load once and reuse:

```bash
laya-mcp serve --port 8787     # loads the model, keeps it warm on 127.0.0.1:8787
```

Then add `--sidecar` to the `command` array in `opencode.json`:

```json
"command": [
  "/home/mihai/.local/share/pipx/venvs/laya-mcp/bin/python",
  "-m", "laya_mcp", "mcp", "--sidecar"
]
```

`serve` is loopback-only by default and **has no authentication** — binding it
elsewhere warns loudly. Do not expose it.

`laya-mcp install` can write this config for you; it detects opencode among the
harnesses it knows and merges rather than replaces, backing the file up first.
It was not used here because the config needed a non-default `timeout` and a
`--device`/sidecar decision.

---

## 9. Optional: switching to CUDA

`doctor` reports `cuda unavailable` because the installed torch is the CPU-only
build — that is a direct consequence of the constraint in §3, not a driver
problem. The system driver is fine (`nvidia-smi` sees the GTX 1650 Ti).

To try the GPU:

```bash
pipx install 'laya-mcp[mcp]' --force \
  --pip-args="--extra-index-url https://download.pytorch.org/whl/cu128"
```

Then add the device flag to `command` — as a trailing argv element, since there
is no environment variable:

```json
"command": [
  "/home/mihai/.local/share/pipx/venvs/laya-mcp/bin/python",
  "-m", "laya_mcp", "mcp", "--device", "cuda"
]
```

Caveats before you do:

- Costs roughly **2.5 GB** of `nvidia-*` wheels and can conflict with Arch's
  system NVIDIA packages.
- 4 GB VRAM on a 1650 Ti may not hold the checkpoint. On OOM, Laya **silently
  demotes itself to CPU in fp32, in place and permanently**, printing to stdout
  and setting no flag. A process that hits this once keeps answering 10–15×
  slower with nothing in the response admitting it. `laya-mcp doctor` runs a real
  op on the device rather than trusting `torch.cuda.is_available()`; use it to
  check. The `/health` endpoint reports a demotion.

Leaving it on `auto` is the safer default. It is also currently equivalent to
`cpu`, because the CPU wheel has no CUDA support to auto-detect.

---

## 10. Useful flags

| Flag | Why |
|---|---|
| `--head-max-len` | Options share this budget (192 tokens on the English checkpoint). Past a point every label gets ~4 tokens, which is the documented cause of a benchmark collapse. Raise it for high-cardinality `choice`. |
| `--max-len` | Total budget. Raising it is the fix for a truncated state. |
| `--truncate-left` | Keep the **tail** of an oversized state. Off by default because it changes the answer: one 16 958-character state with a decoy at the front scored 0.0706 head-kept vs 0.8341 tail-kept. Use it for threads, logs, closing contract terms. |
| `--concurrency` | Default 1, and that is correctness, not caution — Laya is not thread-safe. |
| `--sidecar` | Point at a running `serve`; see §8. |

Laya truncates state **from the end, silently**. Long documents lose their tail
and the model then answers about the surviving prefix at full confidence. Use
`laya_plan` before `laya_ask` on anything long.

---

## 11. Maintenance

```bash
# update
pipx upgrade laya-mcp

# what is installed
pipx list
opencode mcp list

# remove completely
pipx uninstall laya-mcp
# then delete the "mcp" block from ~/.config/opencode/opencode.json and restart
```

The HuggingFace checkpoint cache (2.3 GB) is left behind on uninstall:
`rm -rf ~/.cache/huggingface` if you want it gone.

---

## 12. Summary of corrections to the original snippet

| # | Original | Shipped | Why |
|---|---|---|---|
| 1 | `"disabled": true` | `"enabled": true` | `disabled` is not an opencode key; silently ignored |
| 2 | `"environment": {"LAYA_DEVICE": "cuda"}` | removed | no such env var; device is the `--device` flag |
| 3 | `laya-mcp-server` | `python -m laya_mcp mcp` | different program; needs an incompatible `mcp>=2.2.0` |
| 4 | `venvs/laya/` | `venvs/laya-mcp/` | pipx names the dir after the package |
| 5 | — | `"timeout": 120000` | default 5000 ms is too tight for a cold model cache |
| 6 | `pipx install laya-mcp` | `pipx install 'laya-mcp[mcp]'` | `[mcp]` extra is required or the server cannot start |
