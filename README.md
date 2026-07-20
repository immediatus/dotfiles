# Reproducible Developer Workstation & Dotfiles

Declarative configuration and installer for a reproducible, containerized developer workstation on **Fedora 44** (including Fedora COSMIC Atomic / Silverblue / Workstation).

---

## 🚀 1. Quick Start (New System Setup)

Run this single command on a fresh Fedora system:

```bash
git clone https://github.com/immediatus/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install.sh
```

### Interactive Prompts During Installation:

1. **Host & Flatpak Updates Prompt:**
   > `Would you like to check for and apply host OS (rpm-ostree) and Flatpak updates?`
   * **Recommended:** Press `Y` (Yes).

2. **Lemonade AI Server Prompt:**
   > `Would you like to install the local Lemonade AI configuration and CLI?`
   * **Standard Laptop (No local LLM / ROCm required):** Press `N` (No). Keeps installation lightweight.
   * **Workstation / APU with AMD ROCm:** Press `Y` (Yes) to enable background model serving.

---

## 🛠️ 2. What Gets Installed & Configured

### A. Host System & COSMIC Desktop
* **Desktop Environment (`stow/cosmic`)**: Automatically applies COSMIC panel applets, window autotiling, custom keybindings, themes, and wallpaper (`mountain-valley`).
* **Alacritty Terminal (`stow/alacritty`)**: Sets up GPU-accelerated Alacritty with `synthwave_84` theme and `SauceCodePro Nerd Font`, configured to boot directly into the `dev-workspace` container.
* **Host Flatpak Applications**: Automatically installs **Brave Browser** (`com.brave.Browser`), **Google Chrome**, **Telegram**, **Zoom**, **Syncthing**, **Heroic Games Launcher**, **COSMIC Tweaks**, **Vigil Applet**, **Clipboard Manager Applet**, **Loupe**, **Papers**, and **SimpleScan**.
* **Fonts**: Installs and registers `SauceCodePro` Nerd Font in `~/.local/share/fonts/`.

### B. Containerized Dev Workspace (`dev-workspace`)
* **Isolated Environment**: Builds a dedicated Distrobox development container (`my-dev-box`) with direct volume access to `~/code`, `~/.claude`, `~/Sync`, and `~/.ssh`.
* **Zsh & Starship (`stow/zsh`, `stow/starship`)**: Oh-My-Zsh shell with `zsh-autosuggestions`, `zsh-syntax-highlighting`, and custom prompt styling.
* **Neovim (`stow/nvim`)**: Optimized Neovim setup with LSP, Treesitter syntax highlighting, and lightweight `github/copilot.vim` integration.
* **CLI Utilities (`stow/yazi`, `stow/eza`, `stow/git`, `stow/npm`)**: Yazi terminal file manager, `eza` (modern `ls`), global git configurations, and npm defaults.

---

## 🔄 3. Host System Maintenance (Fedora Atomic & Flatpaks)

To keep your host OS and Flatpak applications up to date over time, run:

```bash
# Update host OS deployment
rpm-ostree upgrade

# Update all Flatpak applications (Brave, Chrome, Zoom, COSMIC tools)
flatpak update -y

# Reboot if a new OS deployment was staged
systemctl reboot
```

---

## 📦 4. Stow Packages Reference

All package configurations are maintained declaratively inside `stow/`:

| Package | Scope | Description |
| :--- | :--- | :--- |
| `alacritty` | Host | Alacritty config, `synthwave_84` theme, fonts, and container auto-entry script. |
| `cosmic` | Host | COSMIC panel applets, keybindings, autotile, compositor rules, and wallpaper. |
| `zsh` | Container | Zsh shell, Oh-My-Zsh plugins, aliases, and container bridge tools (`xclaude`, `xagy`). |
| `starship` | Container | Cross-shell prompt theme (`starship.toml`). |
| `nvim` | Container | Neovim Lua IDE setup with `github/copilot.vim`. |
| `yazi` | Container | Blazing-fast terminal file manager with image previews. |
| `eza` | Container | Modern `ls` enhancement with icons and git integration. |
| `git` | Container | Global Git configuration, visual log aliases, and ignore rules. |
| `npm` | Container | Global NPM defaults. |
| `lemonade` | Host & Container | *(Optional)* Lemonade local LLM CLI wrapper and completion engine. |

---

## 🧠 5. Optional: Local AI Server Setup (Lemonade AI)

If you chose to install Lemonade AI during setup (`INSTALL_LEMONADE=true`):

* **API Endpoint:** `http://localhost:13305/v1` (inside container: `http://host.docker.internal:13305/v1`)
* **Model Cache:** Stored in host `~/.cache/huggingface` and shared across container and host.
* **CLI Commands:**
  ```bash
  lemonade list           # List available models
  lemonade load <model>   # Load model into GPU memory
  lemonade unload         # Unload model to free VRAM
  lemonade status         # Check background daemon status
  ```
