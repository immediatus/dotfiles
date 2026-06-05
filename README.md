# Dotfiles & Development Environment Setup

This repository contains declarative configurations for a reproducible, containerized developer workstation optimized for **AMD Strix Halo (gfx1151)** and Fedora-based hosts.

---

## 1. Host Prerequisites & ROCm Optimization

Unified memory APUs like Strix Halo share RAM between the CPU and GPU. To run large LLM models (e.g., 122B Qwen) stably under ROCm without running out of memory (OOM), you must configure your BIOS and host kernel parameters.

### A. BIOS UMA Settings (Choose one)
*   **Option A (Dynamic - Recommended):** Set the **UMA Frame Buffer Size to "Auto"** or a low value (like 2GB) in your BIOS. This allocates most memory to the CPU system pool, and we will let the GPU driver dynamically map it.
*   **Option B (Static):** Set the **UMA Frame Buffer Size to 96GB or 112GB** statically in the BIOS.

### B. Host Kernel Boot Parameters (For Fedora Atomic / Silverblue)
If using **Option A (Dynamic)**, you must increase the host GPU driver's GTT (Graphics Translation Table) mapping limit to allow `cudaMalloc` allocations to scale up to 85% of your system RAM (~108 GB on a 128GB system). 

Run this command on your host system:
```bash
sudo rpm-ostree kargs \
  --append="ttm.pages_limit=28311552" \
  --append="ttm.page_pool_size=28311552"
```
*After executing, reboot your host computer.*

### C. Enable Systemd User Linger
Enable systemd to run services for your user account even when you are not logged in. This keeps the background Llama server active:
```bash
loginctl enable-linger $USER
```

---

## 2. Bootstrapping the Environment

Run the installer script on the host to configure host symlinks, build the custom Distrobox development container, and initialize GNU Stow:
```bash
./install.sh
```

This will perform the following steps:
1.  Setup host symlinks for Alacritty, custom scripts, models configuration, and the Llama Quadlet.
2.  Install fonts and reload cache.
3.  Build the custom `my-dev-box` image using Podman.
4.  Create the isolated-home `dev-workspace` container.
5.  Link and Stow configurations (git, zsh, starship, nvim, yazi, eza).
6.  Dynamically clone Zsh plugins (`zsh-autosuggestions` and `zsh-syntax-highlighting`).

---

## 3. Configuration Packages & Development Stack

This repository packages several specialized development configurations inside the `stow/` directory. When the bootstrapping script runs, GNU Stow symlinks these folders directly into the isolated distrobox home directory:

*   **Alacritty (`stow/alacritty/`)**: GPU-accelerated terminal emulator configured with Nerdfont integration, standard developer layouts, and custom theme presets.
*   **Neovim (`stow/nvim/`)**: A highly optimized terminal editor workspace setup with customized search, treesitter syntax parser settings, and language server presets.
*   **Starship (`stow/starship/`)**: A cross-shell prompt that dynamically displays git branch names, command durations, active container states, and local runtime engine versions.
*   **Zsh & plugins (`stow/zsh/`)**: The main user shell configured with custom aliases, auto-completion engines, syntax highlighting plugins, and functions (such as `llama`).
*   **Yazi (`stow/yazi/`)**: Blazing-fast terminal file manager configured with image previews, keybindings, trash integration, and shell navigation aliases.
*   **Eza (`stow/eza/`)**: Modern `ls` enhancement config highlighting folders, permissions, size layouts, and git metadata status directly in terminal directory lists.
*   **Git (`stow/git/`)**: Standard global Git configurations, default pull merge properties, custom git log visual alias commands, and local settings exclusions.
*   **NPM (`stow/npm/`)**: Node Package Manager configuration defaults.

---

## 4. Model Storage, Configurations & Download Directory

This repository employs a hybrid approach to manage LLM configurations and weights efficiently without cluttering the Git history or duplicating storage:
- **`models/models.json` (Declarative Presets):** Version-controlled configuration defining your model profiles and execution arguments.
- **`~/models/` (Host Storage):** A local host directory containing heavy GGUF binary files, state environment files, and KV cache directories. This is ignored by Git and shared dynamically with containers.

### Why is this structured this way?

1. **Separation of Concerns:** Heavy model weights (often 10GB to 100GB+) must not be checked into Git. By keeping them in `~/models/` and ignoring GGUF/bin files, we keep the dotfiles repository lightweight while maintaining full version control over the server arguments and preset configurations.
2. **Container Volume Alignment:** The development container (`dev-workspace`) mounts the host's `~/models/` directory directly to `/models`. This allows both the host (e.g., the background Podman/systemd service) and the container (e.g., local CLI tools or shell scripts) to share the same model files and runtime state without duplication.
3. **Stow Conflict Prevention:** Because the host mount is dynamically linked, we avoid using GNU Stow to manage the `models/` package inside the container. Attempting to stow a directory to a path occupied by a volume mount leads to symlink conflicts. Instead, `install.sh` establishes a host-level symlink from `~/.dotfiles/models/models.json` to `~/models/models.json`.

### How to Install and Switch Models

To set up and run any model profile, follow these three steps:

#### Step 1: Place GGUF Model Files in `~/models/`
All model weights must be downloaded as GGUF files and stored in the host directory `~/models/`. 
*(Note: If the directory does not exist, running `./install.sh` will automatically create it for you).*

You can download GGUF files manually from Hugging Face or use the helper commands below for the recommended profiles:

*   **`expert`** (Qwen 2.5 122B MoE scale):
    *   *Required Files:* `Qwen_Qwen3.5-122B-A10B-Q4_K_M-00001-of-00002.gguf` & `Qwen_Qwen3.5-122B-A10B-Q4_K_M-00002-of-00002.gguf`
    *   *Download Commands:*
        ```bash
        curl -L -o ~/models/Qwen_Qwen3.5-122B-A10B-Q4_K_M-00001-of-00002.gguf "https://huggingface.co/bartowski/Qwen_Qwen3.5-122B-A10B-GGUF/resolve/main/Qwen_Qwen3.5-122B-A10B-Q4_K_M-00001-of-00002.gguf"
        curl -L -o ~/models/Qwen_Qwen3.5-122B-A10B-Q4_K_M-00002-of-00002.gguf "https://huggingface.co/bartowski/Qwen_Qwen3.5-122B-A10B-GGUF/resolve/main/Qwen_Qwen3.5-122B-A10B-Q4_K_M-00002-of-00002.gguf"
        ```
*   **`reson`** (Reasoning Distilled 27B / Claude-Style):
    *   *Required File:* `Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-Q6_K.gguf`
    *   *Download Command:*
        ```bash
        curl -L -o ~/models/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-Q6_K.gguf "https://huggingface.co/mradermacher/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled-GGUF/resolve/main/Qwen3.5-27B-Claude-4.6-Opus-Reasoning-Distilled.Q6_K.gguf"
        ```
*   **`agent`** (Qwen 3 Coder Next):
    *   *Required Files:* `Qwen_Qwen3-Coder-Next-Q8_0-00001-of-00003.gguf`, `00002-of-00003`, & `00003-of-00003`
    *   *Download Commands:*
        ```bash
        curl -L -o ~/models/Qwen_Qwen3-Coder-Next-Q8_0-00001-of-00003.gguf "https://huggingface.co/bartowski/Qwen_Qwen3-Coder-Next-GGUF/resolve/main/Qwen_Qwen3-Coder-Next-Q8_0-00001-of-00003.gguf"
        curl -L -o ~/models/Qwen_Qwen3-Coder-Next-Q8_0-00002-of-00003.gguf "https://huggingface.co/bartowski/Qwen_Qwen3-Coder-Next-GGUF/resolve/main/Qwen_Qwen3-Coder-Next-Q8_0-00002-of-00003.gguf"
        curl -L -o ~/models/Qwen_Qwen3-Coder-Next-Q8_0-00003-of-00003.gguf "https://huggingface.co/bartowski/Qwen_Qwen3-Coder-Next-GGUF/resolve/main/Qwen_Qwen3-Coder-Next-Q8_0-00003-of-00003.gguf"
        ```
*   **`simple`** (Gemma 3 12B IT with Speculative Drafting):
    *   *Required Files:* `gemma-3-12b-it-Q4_K_M.gguf` & `gemma-3-270m-it-Q8_0.gguf`
    *   *Download Commands:*
        ```bash
        curl -L -o ~/models/gemma-3-12b-it-Q4_K_M.gguf "https://huggingface.co/google/gemma-3-12b-it-GGUF/resolve/main/gemma-3-12b-it-Q4_K_M.gguf"
        curl -L -o ~/models/gemma-3-270m-it-Q8_0.gguf "https://huggingface.co/google/gemma-3-270m-it-GGUF/resolve/main/gemma-3-270m-it-Q8_0.gguf"
        ```

#### Step 2: Verify the Configuration Presets (`models.json`)
The llama script maps command arguments to the files downloaded in Step 1. Ensure the profile names and GGUF filenames match exactly what is in your local `models/models.json`:
```json
{
  "expert": {
    "file": "Qwen_Qwen3.5-122B-A10B-Q4_K_M-00001-of-00002.gguf",
    "args": "--fit off --no-mmap --n-gpu-layers 99 --ctx-size 262144 ..."
  }
}
```
*(If you make any changes to this config, re-run `./install.sh` to update the symlinks on your host system).*

#### Step 3: Switch the Active Model and Load the Server
Once the GGUF files are in `~/models/` and matched in `models.json`, run the following switcher command (accessible both inside and outside the container):
```bash
llama switch <profile_name>
```
For example, to load the `expert` profile:
```bash
llama switch expert
```
This script will:
1. Verify that the matching GGUF file(s) exist in `~/models/`.
2. Write the environment parameters to `~/models/.active_env`.
3. Restart/Start the background `llama-rocm.service` systemd service which mounts the model files automatically.

---

## 5. Llama LLM Server Management


The LLM server runs in the background as a host-level systemd user service (`llama-rocm.service`) generated via a Podman Quadlet.

*   **Initialize/Setup the Service:**
    ```bash
    llama setup
    ```
*   **Switch Model Profiles:**
    ```bash
    llama switch <profile>
    ```
    *Available profiles:*
    *   `expert`: Qwen 3.5 122B A10B (262k context, 99 layers on GPU, 8 threads).
    *   `reson`: Qwen 3.5 27B Claude-Opus-Reasoning-Distilled (128k context, 8 threads).
    *   `agent`: Qwen 3 Coder Next (128k context, 8 threads).
    *   `simple`: Gemma 3 12B IT (128k context, 8 threads, using speculative draft).
*   **Control Commands:**
    *   Check status: `llama status`
    *   Restart service: `llama restart`
    *   View live logs: `llama logs` (uses journalctl)
