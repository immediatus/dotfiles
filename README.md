# Dotfiles & Development Environment Setup

This repository contains declarative configurations for a reproducible, containerized developer workstation optimized for Fedora-based hosts (including Fedora COSMIC Atomic / Silverblue) and AMD hardware.

---

## 1. Quick Start for New Laptop / System Setup

Setting up a new laptop or workstation with this repository takes only a few minutes. 

### Step 1: Download & Bootstrap (No Git Required)

On a fresh Fedora Atomic installation where `git` is not yet installed, download the repository using `curl` (built into Fedora by default) or use `podman`:

#### Option A: Direct Download via `curl` (Recommended - No reboot required)
```bash
curl -sSL https://github.com/your-username/.dotfiles/archive/refs/heads/main.tar.gz | tar -xz && mv .dotfiles-main ~/.dotfiles
cd ~/.dotfiles
```

#### Option B: Clone using `podman` (Built into Fedora Atomic out-of-the-box)
```bash
podman run --rm -v $HOME:$HOME -w $HOME alpine sh -c "apk add --no-cache git && git clone https://github.com/your-username/.dotfiles.git ~/.dotfiles"
cd ~/.dotfiles
```

#### Option C: Layer `git` on Host (Requires Reboot)
```bash
sudo rpm-ostree install git && systemctl reboot
# After reboot:
git clone https://github.com/your-username/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
```

### Step 2: Run the Interactive Installer
```bash
./install.sh
```

During installation, the script will prompt you:
* **System Update Prompt:** `Would you like to check for and apply host OS (rpm-ostree) and Flatpak updates?`
  * Automatically pulls the latest Fedora Atomic system image and updates all installed Flatpaks.
* **Lemonade AI Prompt:** `Would you like to install the local Lemonade AI configuration and CLI? (Y/n)`
  * **On Laptops without local LLM needs:** Answer `n` (No). The installer will skip Lemonade Quadlet daemon activation and CLI stowing, keeping your setup lightweight.
  * **On APUs / Workstations with ROCm:** Answer `y` (Yes) to install Lemonade and the background daemon.

### Recommended Post-Install / Maintenance Commands (Fedora Atomic & Flatpak)

On Fedora Atomic / Silverblue / COSMIC Atomic, use these standard commands to keep your host OS and Flatpak applications up to date:

```bash
# 1. Update host OS deployment via rpm-ostree
rpm-ostree upgrade

# 2. Update all installed Flatpaks (Brave, Chrome, Zoom, COSMIC apps)
flatpak update -y

# 3. Reboot host if a new rpm-ostree deployment was staged
systemctl reboot
```

### What `./install.sh` Automatically Configures:
1. **COSMIC Desktop Environment (`stow/cosmic/`)**:
   * Stows COSMIC desktop configuration (`--no-folding`) to set up panel layouts, applets, shortcuts, wallpapers (`mountain-valley`), keybindings, and autotile settings on the host.
2. **Alacritty Terminal (`stow/alacritty/`)**:
   * Configures GPU-accelerated Alacritty as the default terminal on the host, styled with the `synthwave_84` theme and SauceCodePro Nerd Font, configured to launch directly into the `dev-workspace` container.
3. **Host Flatpak Applications**:
   * Ensures essential applications are installed: **Brave Browser** (`com.brave.Browser`), **Google Chrome**, **Zoom**, **COSMIC Tweaks**, **Vigil Applet**, **Clipboard Manager**, **Loupe**, **Papers**, and **SimpleScan**.
4. **SauceCodePro Nerd Font**:
   * Automatically unzips and registers `SauceCodePro` Nerd Font into `~/.local/share/fonts/` and updates the host font cache.
5. **Containerized Development Workspace (`my-dev-box` & `dev-workspace`)**:
   * Builds the custom container image using Podman and Distrobox.
   * Creates an isolated-home `dev-workspace` container mapped with volume access to `~/code`, `~/.claude`, `~/Sync`, and `~/.ssh`.
6. **Development Tool Configurations (stowed inside container)**:
   * **Zsh & Plugins**: Oh-My-Zsh setup with `zsh-autosuggestions` and `zsh-syntax-highlighting`.
   * **Starship Prompt**: Cross-shell prompt (`starship.toml`).
   * **Neovim**: Optimized Lua workspace with LSP, Treesitter, and lightweight `github/copilot.vim` integration.
   * **Yazi & Eza**: Terminal file manager with previews, trash integration, and modern `ls`.
   * **Git & NPM**: Global git configs and npm settings.

---

## 2. Host Prerequisites & ROCm Optimization (Optional - for ROCm APUs)

If you are running on an **AMD Strix Halo (gfx1151)** or similar unified-memory APU and wish to run 100B+ local LLMs via Lemonade:

### A. BIOS UMA Settings (Choose one)
* **Option A (Dynamic - Recommended):** Set **UMA Frame Buffer Size to "Auto"** or a low value (2GB) in BIOS.
* **Option B (Static):** Set **UMA Frame Buffer Size to 96GB or 112GB** statically in BIOS.

### B. Host Kernel Boot Parameters (For Fedora Atomic / Silverblue)
For Option A (Dynamic), increase GTT mapping limit for `cudaMalloc`:
```bash
sudo rpm-ostree kargs \
  --append="ttm.pages_limit=28311552" \
  --append="ttm.page_pool_size=28311552"
```
*Reboot the host system after applying.*

### C. Systemd User Linger
Keep background user services active when logged out:
```bash
loginctl enable-linger $USER
```

---

## 3. Configuration Packages Overview

All package configurations are organized declaratively under `stow/`:

| Package | Target | Description |
| :--- | :--- | :--- |
| `alacritty` | Host & Container | Terminal emulator setup, themes (`synthwave_84`), font settings, and auto-entry into `dev-workspace`. |
| `cosmic` | Host | COSMIC desktop settings: panel applets, keybindings, autotile, window behavior, and custom wallpaper. |
| `zsh` | Container | Main Zsh shell, Oh-My-Zsh plugins, aliases, and container helper tools (`xclaude`, `xagy`). |
| `starship` | Container | Custom cross-shell prompt style. |
| `nvim` | Container | Neovim IDE setup with LSP, treesitter, and `github/copilot.vim`. |
| `yazi` | Container | Fast terminal file manager with image previews and trash integration. |
| `eza` | Container | Modern replacement for `ls` with git status and file icons. |
| `git` | Container | Global git configuration, aliases, and ignores. |
| `npm` | Container | Global npm config. |
| `lemonade` | Host & Container | *(Optional)* Lemonade AI CLI wrapper and Zsh completion. |

---

## 4. Local Model Storage & Lemonade Server (Optional)

If Lemonade AI is installed (`INSTALL_LEMONADE=true`):
* **Daemon Endpoint:** `http://localhost:13305/v1` (inside container: `http://host.docker.internal:13305/v1`)
* **Hugging Face Cache:** Models are cached in host `~/.cache/huggingface` and shared across container and host.
* **Commands:**
  * List models: `lemonade list`
  * Load model: `lemonade load <model-id>`
  * Unload model: `lemonade unload`
  * Status: `lemonade status`
