#!/usr/bin/env bash
# ~/.dotfiles/install.sh
# Bootstrap installer for the reproducible development environment
set -e

HOST_HOME="${HOME}"
DOTFILES="${HOST_HOME}/.dotfiles"

# Helper function for prompting y/n (defaulting to Yes if enter is pressed)
prompt_yn() {
    local prompt_text="$1"
    local response
    while true; do
        read -p "${prompt_text} (Y/n): " response </dev/tty
        # Default to Yes
        if [[ -z "$response" || "$response" =~ ^[Yy]$ || "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
            return 0
        elif [[ "$response" =~ ^[Nn]$ || "$response" =~ ^[Nn][Oo]$ ]]; then
            return 1
        fi
    done
}

# Prompt for LLM configuration, helper functions, and daemon setup
INSTALL_LLM=false
INSTALL_LLM_DAEMON=false

echo "=== Installation Configuration ==="
if prompt_yn "Would you like to install the local LLM configuration and helper functions?"; then
    INSTALL_LLM=true
    if prompt_yn "Would you like to install and activate the background LLM daemon (Systemd Quadlet service)?"; then
        INSTALL_LLM_DAEMON=true
    fi
fi
echo "=================================="
echo ""

echo "=== Phase 1: Creating Host-Level Symlinks ==="
mkdir -p "${HOST_HOME}/.config/alacritty"
rm -f "${HOST_HOME}/.config/alacritty/alacritty.toml"
ln -sf "${DOTFILES}/stow/alacritty/.config/alacritty/alacritty.toml" "${HOST_HOME}/.config/alacritty/alacritty.toml"
ln -sfn "${DOTFILES}/stow/alacritty/.config/alacritty/themes" "${HOST_HOME}/.config/alacritty/themes"

# Stow or Symlink COSMIC configurations on host
echo "=== Phase 1.2: Stowing COSMIC configuration on host ==="
# Clean up existing host locations to prevent symlink conflicts and force unfolding
for item in ".config/cosmic" ".config/dconf/cosmic" ".config/environment.d/cosmic.conf" ".config/gtk-4.0/cosmic" "Pictures/wallpapers/mountain-valley-with-solitary-tree-27efee0c-bc58-463e-8ddc-2ea2abf6924d.png"; do
    if [ -L "${HOST_HOME}/${item}" ]; then
        echo "      Removing existing host symlink ${item}..."
        rm -f "${HOST_HOME}/${item}"
    elif [ -e "${HOST_HOME}/${item}" ]; then
        echo "      Backing up existing host file/folder ${item} to ${item}.bak..."
        rm -rf "${HOST_HOME}/${item}.bak"
        mv "${HOST_HOME}/${item}" "${HOST_HOME}/${item}.bak"
    fi
done

if command -v stow &>/dev/null; then
    echo "      Stowing COSMIC configuration using GNU Stow (with --no-folding)..."
    stow --no-folding -d "${DOTFILES}/stow" -t "${HOST_HOME}" cosmic
else
    echo "      GNU Stow not found on host. Falling back to manual symlinking..."
    # Recreate directory structure and symlink individual files to prevent directory folding
    (
        cd "${DOTFILES}/stow/cosmic"
        find . -type d | while read -r dir; do
            mkdir -p "${HOST_HOME}/${dir}"
        done
        find . -type f | while read -r file; do
            if [ -e "${HOST_HOME}/${file}" ] && [ ! -L "${HOST_HOME}/${file}" ]; then
                echo "      Backing up existing host file ${file} to ${file}.bak..."
                rm -rf "${HOST_HOME}/${file}.bak"
                mv "${HOST_HOME}/${file}" "${HOST_HOME}/${file}.bak"
            fi
            ln -sf "${DOTFILES}/stow/cosmic/${file}" "${HOST_HOME}/${file}"
        done
    )
fi


# Ensure host-level models directory exists
echo "      Ensuring host models directory exists..."
mkdir -p "${HOST_HOME}/models"

# Ensure host-level code trash directories exist to support trash-cli/yazi across container volume boundaries
mkdir -p "${HOST_HOME}/code/.Trash-1000/files"
mkdir -p "${HOST_HOME}/code/.Trash-1000/info"
chmod 700 "${HOST_HOME}/code/.Trash-1000" "${HOST_HOME}/code/.Trash-1000/files" "${HOST_HOME}/code/.Trash-1000/info"

# Ensure host-level .ssh directory exists with correct permissions
mkdir -p "${HOST_HOME}/.ssh"
chmod 700 "${HOST_HOME}/.ssh"

# Ensure host-level .claude, .claude.json, and .gemini exist with container-accessible labels
mkdir -p "${HOST_HOME}/.claude"
touch "${HOST_HOME}/.claude.json"
mkdir -p "${HOST_HOME}/.gemini"
chcon -R -t container_file_t "${HOST_HOME}/.claude" "${HOST_HOME}/.claude.json" "${HOST_HOME}/.gemini" "${HOST_HOME}/.local/bin/agy" 2>/dev/null || true

# Ensure host-level bin directory exists and symlink the llama script and models.json if requested
if [ "$INSTALL_LLM" = "true" ]; then
    mkdir -p "${HOST_HOME}/.local/bin"
    ln -sf "${DOTFILES}/stow/llama/.local/bin/llama" "${HOST_HOME}/.local/bin/llama"

    # Symlink host-level models.json configuration
    ln -sf "${DOTFILES}/models/models.json" "${HOST_HOME}/models/models.json"
fi

echo "=== Phase 1.5: Installing Fonts on Host ==="
FONT_DIR="${HOST_HOME}/.local/share/fonts"
if [ ! -d "${FONT_DIR}/SauceCodePro" ]; then
    echo "Installing SauceCodePro (Source Code Pro) Nerd Font..."
    mkdir -p "${FONT_DIR}/SauceCodePro"
    unzip -o -d "${FONT_DIR}/SauceCodePro" "${DOTFILES}/fonts/SourceCodePro.zip"
    
    # Update host font cache
    if command -v fc-cache &>/dev/null; then
        echo "Updating host font cache..."
        fc-cache -f "${FONT_DIR}"
    fi
    echo "SauceCodePro Nerd Font installed successfully!"
else
    echo "SauceCodePro Nerd Font is already installed."
fi

echo "=== Phase 1.8: Installing Host Flatpak Applications ==="
if command -v flatpak &>/dev/null; then
    echo "Checking Flatpak remotes..."
    # Ensure flathub remote is configured
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    
    # Check if cosmic remote exists, otherwise add it (COSMIC desktop apps repo)
    flatpak remote-add --user --if-not-exists cosmic https://repository.cosmic.system76.com/flatpak/cosmic.flatpakrepo || true

    # Applications to ensure are installed
    HOST_APPS=(
        "com.google.Chrome"
        "us.zoom.Zoom"
        "dev.edfloreshz.CosmicTweaks"
        "com.github.bgub.CosmicExtAppletVigil"
        "io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager"
        "org.gnome.Loupe"
        "org.gnome.Papers"
        "org.gnome.SimpleScan"
    )

    for app in "${HOST_APPS[@]}"; do
        if ! flatpak list --columns=application | grep -q "^${app}$"; then
            echo "Installing ${app}..."
            # Try to install from configured remotes (prefer user scope)
            flatpak install -y --user --noninteractive "${app}" || \
            flatpak install -y --system --noninteractive "${app}" || \
            echo "WARNING: Failed to install ${app}"
        else
            echo "      ${app} is already installed."
        fi
    done
else
    echo "      Flatpak is not installed on host. Skipping app installation."
fi

# Systemd Quadlet (host LLM background container service)
if [ "$INSTALL_LLM_DAEMON" = "true" ]; then
    mkdir -p "${HOST_HOME}/.config/containers/systemd"
    ln -sf "${DOTFILES}/quadlets/llama-rocm.container" "${HOST_HOME}/.config/containers/systemd/llama-rocm.container"

    echo "=== Phase 2: Activating Llama-ROCm Service via Quadlet ==="
    # NOTE: Quadlet-generated units cannot be 'enabled' via systemctl — they are
    # automatically enabled through WantedBy=default.target in the .container file.
    # daemon-reload triggers the Quadlet generator which creates the unit.
    systemctl --user daemon-reload

    # Sync active model env file with the latest definitions in models.json
    ACTIVE_PROFILE="expert"
    if [[ -f "${HOST_HOME}/models/.active_model" ]]; then
      ACTIVE_PROFILE=$(python3 -c "
import json
try:
    models = json.load(open('${HOST_HOME}/models/models.json'))
    active = open('${HOST_HOME}/models/.active_model').read().strip()
    profile = next((k for k, v in models.items() if v.get('file') == active), 'expert')
    print(profile)
except Exception:
    print('expert')
" 2>/dev/null || echo "expert")
    fi
    echo "      Syncing active model profile (${ACTIVE_PROFILE}) with models.json..."
    bash "${DOTFILES}/stow/zsh/.local/bin/llama" switch "${ACTIVE_PROFILE}" || true

    systemctl --user restart llama-rocm.service || true
else
    echo "=== Phase 2: Skipping Llama-ROCm Service Activation ==="
fi

echo "=== Phase 3: Building Custom Distrobox Workspace Image ==="
podman build -t my-dev-box -f "${DOTFILES}/distrobox/Containerfile" "${DOTFILES}/distrobox"

echo "=== Phase 4: Recreating Distrobox Workspace ==="
# Remove any existing container instances
distrobox rm -f dev-workspace 2>/dev/null || true
distrobox rm -f dev-station 2>/dev/null || true

# Create container with isolated home directory and direct volume mounts for host paths
distrobox create --name dev-workspace --image my-dev-box \
    --home "${HOST_HOME}/.local/share/dev-workspace" \
    --volume "${HOST_HOME}/code:/home/${USER}/code" \
    --volume "${HOST_HOME}/models:/home/${USER}/models" \
    --volume "${HOST_HOME}/.claude:/home/${USER}/.claude" \
    --volume "${HOST_HOME}/Sync:/home/${USER}/Sync" \
    -Y

echo "=== Phase 5: Initializing GNU Stow inside Container ==="
# Clean up existing files in container home to prevent Stow/symlink conflicts
distrobox enter dev-workspace -- sh -c 'rm -rf ~/.config/alacritty ~/.config/starship.toml ~/.config/nvim ~/.config/yazi ~/.config/git ~/.config/eza ~/.npmrc ~/.gitconfig ~/.zshrc ~/.zprofile ~/.profile ~/.zsh ~/.claude.json ~/.ssh ~/.zshrc.local ~/.gitconfig.local ~/.local/bin/llama ~/.local/bin/docker ~/.local/bin/podman ~/.local/bin/xagy ~/.local/bin/xclaude'

# Symlink host's .dotfiles folder inside the container home so Stow can find it
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/.dotfiles" "/home/${USER}/.local/share/dev-workspace/.dotfiles"

# Symlink direct volume mount paths inside the container home for path alignment
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/code" "/home/${USER}/.local/share/dev-workspace/code"
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/models" "/home/${USER}/.local/share/dev-workspace/models"
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/.claude" "/home/${USER}/.local/share/dev-workspace/.claude"
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/Sync" "/home/${USER}/.local/share/dev-workspace/Sync"
# Symlink host .gemini so agy conversations are accessible inside container
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/.gemini" "/home/${USER}/.local/share/dev-workspace/.gemini"
# Symlink host .claude.json so Claude Code state and authentication are shared
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/.claude.json" "/home/${USER}/.local/share/dev-workspace/.claude.json"
# Symlink host .ssh so SSH keys and configurations are shared
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/.ssh" "/home/${USER}/.local/share/dev-workspace/.ssh"
# Symlink host synced local configurations via volume mount
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/Sync/config/.zshrc.local" "/home/${USER}/.local/share/dev-workspace/.zshrc.local"
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/Sync/config/.gitconfig.local" "/home/${USER}/.local/share/dev-workspace/.gitconfig.local"


# Clone Oh My Zsh to the container's isolated home directory if not present
if [ ! -d "${HOST_HOME}/.local/share/dev-workspace/.oh-my-zsh" ]; then
    echo "Cloning Oh My Zsh for container..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "${HOST_HOME}/.local/share/dev-workspace/.oh-my-zsh"
fi

# Ensure Zsh plugins are cloned in dotfiles stow structure before running Stow
echo "Ensuring cloneable Zsh plugins are present..."
mkdir -p "${DOTFILES}/stow/zsh/.zsh/plugins"
if [ ! -f "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    echo "Cloning or restoring zsh-autosuggestions..."
    rm -rf "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-autosuggestions"
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-autosuggestions"
fi
if [ ! -f "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    echo "Cloning or restoring zsh-syntax-highlighting..."
    rm -rf "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-syntax-highlighting"
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-syntax-highlighting"
fi

# Run GNU Stow inside the container to symlink dev configurations
STOW_PACKAGES=(alacritty zsh starship nvim yazi git eza npm)
if [ "$INSTALL_LLM" = "true" ]; then
    STOW_PACKAGES+=(llama)
fi
distrobox enter dev-workspace -- stow -d "/home/${USER}/.local/share/dev-workspace/.dotfiles/stow" -t "/home/${USER}/.local/share/dev-workspace" "${STOW_PACKAGES[@]}"

# Symlink bun and bunx inside container .local/bin for MCP servers compatibility
distrobox enter dev-workspace -- ln -sfn "../../.bun/bin/bun" "/home/${USER}/.local/share/dev-workspace/.local/bin/bun"
distrobox enter dev-workspace -- ln -sfn "../../.bun/bin/bunx" "/home/${USER}/.local/share/dev-workspace/.local/bin/bunx"
# Symlink agy inside container .local/bin for developer use
distrobox enter dev-workspace -- ln -sfn "/home/${USER}/.local/bin/agy" "/home/${USER}/.local/share/dev-workspace/.local/bin/agy"

# Ensure Claude symlink inside container .local/bin is valid and points to the latest local version (or globally installed fallback)
distrobox enter dev-workspace -- sh -c '
  CLAUDE_BIN_DIR="$HOME/.local/bin"
  CLAUDE_VERSIONS_DIR="$HOME/.local/share/claude/versions"
  mkdir -p "$CLAUDE_BIN_DIR"
  if [ -d "$CLAUDE_VERSIONS_DIR" ] && [ "$(ls -A "$CLAUDE_VERSIONS_DIR" 2>/dev/null)" ]; then
    LATEST_CLAUDE=$(ls -vd "$CLAUDE_VERSIONS_DIR"/* 2>/dev/null | tail -n 1)
    if [ -x "$LATEST_CLAUDE" ]; then
      ln -sfn "$LATEST_CLAUDE" "$CLAUDE_BIN_DIR/claude"
      echo "      Synced Claude symlink to latest version: $LATEST_CLAUDE"
    fi
  else
    ln -sfn "/usr/local/bin/claude" "$CLAUDE_BIN_DIR/claude"
    echo "      Synced Claude symlink to global fallback: /usr/local/bin/claude"
  fi
'


# Change default container shell to Zsh
distrobox enter dev-workspace -- sudo chsh -s /usr/bin/zsh "${USER}"

echo "=== Phase 6: Cleaning Host Home of Duplicate Configurations ==="
# Prevent host environment contamination
configs=(
    ".zshrc"
    ".zprofile"
    ".profile"
    ".npmrc"
    ".gitconfig"
    ".zsh"
)
for item in "${configs[@]}"; do
    if [ -e "${HOST_HOME}/${item}" ]; then
        echo "Removing host ${item}..."
        rm -rf "${HOST_HOME}/${item}"
    fi
done

config_items=(
    "starship.toml"
    "zellij"
    "nvim"
    "yazi"
    "eza"
    "fzf"
    "git"
)
for item in "${config_items[@]}"; do
    if [ -e "${HOST_HOME}/.config/${item}" ]; then
        echo "Removing host .config/${item}..."
        rm -rf "${HOST_HOME}/.config/${item}"
    fi
done

echo "=== Bootstrap & Setup Complete! ==="
echo "You can now launch Alacritty, which will boot straight into dev-workspace container with a clean host home."
