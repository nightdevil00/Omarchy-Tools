# Qwen 3.5 4B (local, 64K) Configuration with Ollama & Opencode

---

## **Ollama Setup**
| Parameter | Value |
|-----------|-------|
| Location | `localhost` (default) |
| Port | `11434` |
| Base URL | `http://localhost:11434/v1` |
| SDK Package | `@ai-sdk/openai-compatible` |

---

## **Qwen 3.5 4B-OPENCODE Model Configuration**

```json
{
  "name": "Ollama (local)",
  "baseURL": "http://localhost:11434/v1",
  "models": {
    "qwen3.5:4b-opencode": {
      "name": "Qwen 3.5 4B (local, 64K)",
      "tool_call": true,
      "reasoning": true,
      "limit": {
        "context": 65536,
        "output": 8192
      }
    },
    "llama3.2:latest": {
      "name": "Llama 3.2 3B (local)",
      "limit": {
        "context": 16384,
        "output": 4096
      }
    }
  },
  "small_model": "ollama/llama3.2:latest"
}
```

---

## **Ollama Package Names**

### Model Packages (for `yarn pull ollama/model-name`)
- Qwen Model: `qwen3.5:4b-opencode`
- Llama Model: `llama3.2:latest`

### Ollama Service Configuration
| Component | Command / File Location |
|-----------|-------------------------|
| **Ollama binary** | `/usr/local/bin/ollama` (Arch Linux) |
| **Service name** | `ollama.service` (systemd) |
| **Start service** | `sudo systemctl start ollama` |
| **Status check** | `sudo systemctl status ollama` |
| **Stop service** | `sudo systemctl stop ollama` |

### CUDA Configuration
| Component | Path / File Location |
|-----------|----------------------|
| **CUDA directory** | `/usr/lib/cuda/` (default Arch) |
| **CUBLAS_LIB env** | `$CUDA_HOME/lib64/libcublas.so.*` |
| **Ollama CUDA check** | `sudo apt install cuda` then verify in `~/.ollama/config.json` |

---

## **Configuration Location**
- **File**: `~/.config/opencode/opencode.json`
- **Small Model**: Llama 3.2 3B (used for lighter tasks)
- **Qwen Capabilities**: Tool calling + Reasoning enabled, 65K context window, 8K output tokens
