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
Enable systemd to run services for your user account even when you are not logged in. This keeps the background Lemonade server active:
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
1.  Setup host symlinks for Alacritty, custom scripts, and the Lemonade Quadlet.
2.  Install fonts and reload cache.
3.  Install host-level Flatpak applications (Google Chrome, Zoom, COSMIC Tweaks, Vigil, Clipboard Manager, Loupe, Papers, and SimpleScan).
4.  Build the custom `my-dev-box` image using Podman.
5.  Create the isolated-home `dev-workspace` container.
6.  Link and Stow configurations (git, zsh, starship, nvim, yazi, eza, and host COSMIC desktop settings configured with `--no-folding` to keep host-local configurations isolated).
7.  Dynamically clone Zsh plugins (`zsh-autosuggestions` and `zsh-syntax-highlighting`).

---

## 3. Configuration Packages & Development Stack

This repository packages several specialized development configurations inside the `stow/` directory. When the bootstrapping script runs, GNU Stow symlinks these folders directly into the isolated distrobox home directory:

*   **Alacritty (`stow/alacritty/`)**: GPU-accelerated terminal emulator configured with Nerdfont integration, standard developer layouts, and custom theme presets.
*   **Neovim (`stow/nvim/`)**: A highly optimized terminal editor workspace setup with customized search, treesitter syntax parser settings, and language server presets.
*   **Starship (`stow/starship/`)**: A cross-shell prompt that dynamically displays git branch names, command durations, active container states, and local runtime engine versions.
*   **Zsh & plugins (`stow/zsh/`)**: The main user shell configured with custom aliases, auto-completion engines, syntax highlighting plugins, and functions (such as `lemonade`).
*   **Yazi (`stow/yazi/`)**: Blazing-fast terminal file manager configured with image previews, keybindings, trash integration, and shell navigation aliases.
*   **Eza (`stow/eza/`)**: Modern `ls` enhancement config highlighting folders, permissions, size layouts, and git metadata status directly in terminal directory lists.
*   **Git (`stow/git/`)**: Standard global Git configurations, default pull merge properties, custom git log visual alias commands, and local settings exclusions.
*   **NPM (`stow/npm/`)**: Node Package Manager configuration defaults.
*   **COSMIC Desktop (`stow/cosmic/`)**: Declarative configuration for the COSMIC desktop environment (panel layouts, applets, compositor settings, and app themes) stowed with directory folding disabled so that host-specific dynamic files (such as local screenshot preferences) are kept local to the host home directory.

---

## 4. Model Storage, Configurations & Local Models

This repository utilizes **Lemonade AI Server (v11)** to run local LLMs. You do not need to download models manually or maintain complex JSON configuration profiles.

### Why is this structured this way?
1. **No Manual Downloads Necessary:** Lemonade supports pulling models directly from Hugging Face via the CLI (e.g. `lemonade pull <model>`), managing downloads and caching automatically.
2. **Hugging Face Cache Integration:** Models are stored in the default Hugging Face cache folder on the host (`~/.cache/huggingface`). This directory is shared with the background Lemonade server and distrobox containers, avoiding duplicate storage.
3. **No Switcher Scripts Needed:** Lemonade hosts models dynamically. You can load, unload, and query models on the fly via the CLI, the OpenAI-compatible API, or the Web UI.

### How to Use Local Models
If you have local GGUF models that you want Lemonade to recognize without re-downloading:
1. **Place in Cache:** Move or copy your GGUF files to the Hugging Face cache snapshots folder (e.g. `~/.cache/huggingface/hub/models--bartowski--Qwen_Qwen3.5-122B-A10B-GGUF/snapshots/<commit_hash>/Qwen_Qwen3.5-122B-A10B-Q4_K_M/`).
2. **Register the Model:** Run the pull command to register it in Lemonade's database. It will verify the files and complete instantly:
   ```bash
   lemonade pull user.qwen3.5-122b-local --checkpoint main bartowski/Qwen_Qwen3.5-122B-A10B-GGUF:Qwen_Qwen3.5-122B-A10B-Q4_K_M --recipe llamacpp
   ```
3. **Load the Model:**
   ```bash
   lemonade load qwen3.5-122b-local
   ```

---

## 5. Lemonade Service & CLI Management

The LLM server runs in the background as a host-level systemd user service (`lemonade.service`) generated via a Podman Quadlet, exposing an OpenAI-compatible API on port `13305`.

*   **API Endpoint:** `http://localhost:13305/v1` (inside containers: `http://host.docker.internal:13305/v1`)
*   **Web UI:** Open your browser and navigate to `http://localhost:13305` or run `lemonade run <model>` to launch a browser chat interface.
*   **Control Commands:**
    *   List models: `lemonade list`
    *   Load model into GPU: `lemonade load <model-id>`
    *   Start terminal chat: `lemonade chat <model-id>`
    *   Unload model (free GPU memory): `lemonade unload`
    *   Check server status: `lemonade status`
    *   Pull new model: `lemonade pull <owner/repo:variant>`
