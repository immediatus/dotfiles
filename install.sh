#!/usr/bin/env bash
# ~/.dotfiles/install.sh
# Bootstrap installer for the reproducible development environment
set -e

HOST_HOME="${HOME}"
DOTFILES="${HOST_HOME}/.dotfiles"

# Ensure ~/.local/bin is in PATH for host commands
mkdir -p "${HOST_HOME}/.local/bin"
export PATH="${HOST_HOME}/.local/bin:${PATH}"

# Configuration Flags
UPDATE_SYSTEM=false
CLEAN_ENV=false
SWAP_CMD_CTRL=false
INSTALL_CHROME=false
INSTALL_LEMONADE=false
INSTALL_LEMONADE_DAEMON=false

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

echo "=== Installation Configuration ==="
if prompt_yn "Would you like to perform a clean reset of existing container environment (~/.local/share/dev-workspace)?"; then
    CLEAN_ENV=true
fi
if prompt_yn "Would you like to swap Left Command (Super) and Left Control keys in COSMIC desktop?"; then
    SWAP_CMD_CTRL=true
fi
if prompt_yn "Would you like to install Google Chrome (Flatpak)?"; then
    INSTALL_CHROME=true
fi
if prompt_yn "Would you like to check for and apply host OS (rpm-ostree) and Flatpak updates?"; then
    UPDATE_SYSTEM=true
fi
if prompt_yn "Would you like to install the local Lemonade AI configuration and CLI?"; then
    INSTALL_LEMONADE=true
    if prompt_yn "Would you like to install and activate the background Lemonade AI daemon (Systemd Quadlet service)?"; then
        INSTALL_LEMONADE_DAEMON=true
    fi
fi
echo "=================================="
echo ""

if [ "$UPDATE_SYSTEM" = "true" ]; then
    echo "=== Phase 0: Updating Host System & Flatpaks ==="
    if command -v rpm-ostree &>/dev/null; then
        echo "Checking for host OS updates (rpm-ostree upgrade)..."
        rpm-ostree upgrade || echo "Notice: rpm-ostree upgrade completed or requires reboot."
    fi
    if command -v flatpak &>/dev/null; then
        echo "Updating Flatpak applications..."
        flatpak update -y --noninteractive || true
    fi
fi

if [ "$CLEAN_ENV" = "true" ]; then
    echo "=== Phase 0.5: Performing Clean Environment Reset ==="
    if command -v distrobox &>/dev/null; then
        echo "Removing existing container instances..."
        distrobox rm -f dev-workspace dev-station 2>/dev/null || true
    fi
    echo "Resetting container home directory (~/.local/share/dev-workspace)..."
    rm -rf "${HOST_HOME}/.local/share/dev-workspace"
    echo "Cleaning host-level symlinks..."
    rm -f "${HOST_HOME}/.config/alacritty/alacritty.toml" "${HOST_HOME}/.config/environment.d/10-local-bin.conf"
fi

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

# Configure keymap swap (Command <-> Control) based on user confirmation
XKB_CONF="${DOTFILES}/stow/cosmic/.config/cosmic/com.system76.CosmicComp/v1/xkb_config"
mkdir -p "$(dirname "$XKB_CONF")"
if [ "$SWAP_CMD_CTRL" = "true" ]; then
    echo "      Configuring COSMIC keymap: Swapping Left Command (Super) and Left Control keys..."
    cat << 'EOF' > "$XKB_CONF"
(
    rules: "",
    model: "pc105",
    layout: "us,ua",
    variant: ",",
    options: Some("ctrl:swap_lwin_lctl"),
    repeat_delay: 400,
    repeat_rate: 25,
)
EOF
else
    echo "      Configuring COSMIC keymap: Standard Left Command and Left Control keys..."
    cat << 'EOF' > "$XKB_CONF"
(
    rules: "",
    model: "pc105",
    layout: "us,ua",
    variant: ",",
    options: None,
    repeat_delay: 400,
    repeat_rate: 25,
)
EOF
fi

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




# Ensure host-level code, Sync, and cache directories exist for container mounts
mkdir -p "${HOST_HOME}/code/.Trash-1000/files"
mkdir -p "${HOST_HOME}/code/.Trash-1000/info"
mkdir -p "${HOST_HOME}/Sync/config"
mkdir -p "${HOST_HOME}/.cache/huggingface"
chmod 700 "${HOST_HOME}/code/.Trash-1000" "${HOST_HOME}/code/.Trash-1000/files" "${HOST_HOME}/code/.Trash-1000/info"

# Ensure host-level .ssh directory exists with correct permissions
mkdir -p "${HOST_HOME}/.ssh"
chmod 700 "${HOST_HOME}/.ssh"

# Ensure host-level .claude, .claude.json, and .gemini exist with container-accessible labels
mkdir -p "${HOST_HOME}/.claude"
touch "${HOST_HOME}/.claude.json"
mkdir -p "${HOST_HOME}/.gemini"

# Ensure Antigravity CLI (agy) is downloaded and installed on host from Google
mkdir -p "${HOST_HOME}/.local/bin"
if [ ! -f "${HOST_HOME}/.local/bin/agy" ]; then
    echo "=== Downloading & Installing Antigravity CLI (agy) from Google ==="
    echo "Running official installer: curl -fsSL https://antigravity.google/cli/install.sh | bash"
    curl -fsSL https://antigravity.google/cli/install.sh | bash || true
fi

if [ -f "${HOST_HOME}/.local/bin/agy" ]; then
    chmod +x "${HOST_HOME}/.local/bin/agy"
    chcon -t container_file_t "${HOST_HOME}/.local/bin/agy" 2>/dev/null || true
fi
chcon -R -t container_file_t "${HOST_HOME}/.claude" "${HOST_HOME}/.claude.json" "${HOST_HOME}/.gemini" 2>/dev/null || true

# Ensure host-level bin directory exists and symlink the lemonade CLI if requested
if [ "$INSTALL_LEMONADE" = "true" ]; then
    mkdir -p "${HOST_HOME}/.local/bin"
    ln -sf "${DOTFILES}/stow/lemonade/.local/bin/lemonade" "${HOST_HOME}/.local/bin/lemonade"
fi

echo "=== Phase 1.5: Installing Fonts on Host ==="
FONT_DIR="${HOST_HOME}/.local/share/fonts"
LEGACY_FONT_DIR="${HOST_HOME}/.fonts"
mkdir -p "${FONT_DIR}/SauceCodePro"
mkdir -p "${LEGACY_FONT_DIR}/SauceCodePro"

echo "Installing SauceCodePro (Source Code Pro) Nerd Font..."
unzip -o -d "${FONT_DIR}/SauceCodePro" "${DOTFILES}/fonts/SourceCodePro.zip"
unzip -o -d "${LEGACY_FONT_DIR}/SauceCodePro" "${DOTFILES}/fonts/SourceCodePro.zip"

if command -v fc-cache &>/dev/null; then
    echo "Updating host font cache..."
    fc-cache -fv "${FONT_DIR}" "${LEGACY_FONT_DIR}" 2>/dev/null || true
fi
echo "SauceCodePro Nerd Font installed successfully!"

echo "=== Phase 1.7: Installing Native Host Packages ==="
if ! command -v alacritty &>/dev/null; then
    echo "Installing Alacritty terminal on host..."
    if command -v rpm-ostree &>/dev/null; then
        rpm-ostree install -y alacritty || true
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y alacritty || true
    fi
fi

echo "=== Phase 1.8: Installing Host Flatpak Applications ==="
if command -v flatpak &>/dev/null; then
    echo "Checking Flatpak remotes..."
    # Ensure flathub remote is configured
    flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo || true
    
    # Ensure cosmic remote exists and disable GPG verification requirement for unverified APT summaries
    flatpak remote-add --user --if-not-exists --no-gpg-verify cosmic https://apt.pop-os.org/cosmic/ || true
    flatpak remote-modify --no-gpg-verify cosmic 2>/dev/null || true

    # Applications to ensure are installed
    HOST_APPS=(
        "com.brave.Browser"
        "us.zoom.Zoom"
        "org.telegram.desktop"
        "io.github.martchus.syncthingtray"
        "com.heroicgameslauncher.hgl"
        "dev.edfloreshz.CosmicTweaks"
        "com.github.bgub.CosmicExtAppletVigil"
        "io.github.cosmic_utils.cosmic-ext-applet-clipboard-manager"
        "org.gnome.Loupe"
        "org.gnome.Papers"
        "org.gnome.SimpleScan"
    )
    if [ "$INSTALL_CHROME" = "true" ]; then
        HOST_APPS+=("com.google.Chrome")
    fi

    for app in "${HOST_APPS[@]}"; do
        if ! flatpak list --columns=application | grep -q "^${app}$"; then
            echo "Installing ${app}..."
            # Try installing from flathub, cosmic, or default remotes
            flatpak install -y --user --noninteractive flathub "${app}" 2>/dev/null || \
            flatpak install -y --user --noninteractive cosmic "${app}" 2>/dev/null || \
            flatpak install -y --user --noninteractive "${app}" || \
            echo "WARNING: Failed to install ${app}"
        else
            echo "      ${app} is already installed."
        fi
    done

    # Refresh COSMIC panel & dock to pick up newly stowed panel config, applets, and dock favorites
    if command -v cosmic-panel &>/dev/null; then
        echo "Reloading COSMIC desktop panel & dock to apply applets and icon layout..."
        systemctl --user restart cosmic-panel cosmic-app-list cosmic-dock 2>/dev/null || true
    fi
else
    echo "      Flatpak is not installed on host. Skipping app installation."
fi

# Systemd Quadlet (host Lemonade background container service)
if [ "$INSTALL_LEMONADE_DAEMON" = "true" ]; then
    mkdir -p "${HOST_HOME}/.config/containers/systemd"
    ln -sf "${DOTFILES}/quadlets/lemonade.container" "${HOST_HOME}/.config/containers/systemd/lemonade.container"

    echo "=== Phase 2: Activating Lemonade Service via Quadlet ==="
    # NOTE: Quadlet-generated units cannot be 'enabled' via systemctl — they are
    # automatically enabled through WantedBy=default.target in the .container file.
    # daemon-reload triggers the Quadlet generator which creates the unit.
    systemctl --user daemon-reload

    systemctl --user restart lemonade.service || true
else
    echo "=== Phase 2: Skipping Lemonade Service Activation ==="
fi

echo "=== Phase 3: Building Custom Distrobox Workspace Image ==="
podman build -t my-dev-box -f "${DOTFILES}/distrobox/Containerfile" "${DOTFILES}/distrobox"

# Ensure Distrobox is installed on host
if ! command -v distrobox &>/dev/null; then
    echo "      Distrobox not found on host. Installing Distrobox locally..."
    mkdir -p "${HOST_HOME}/.local/bin"
    curl -s https://raw.githubusercontent.com/89luca89/distrobox/main/install | sh -s -- --prefix "${HOST_HOME}/.local"
    export PATH="${HOST_HOME}/.local/bin:${PATH}"
fi

echo "=== Phase 4: Recreating Distrobox Workspace ==="
# Remove any existing container instances
distrobox rm -f dev-workspace 2>/dev/null || true
distrobox rm -f dev-station 2>/dev/null || true

# Create container with isolated home directory and direct volume mounts for host paths
distrobox create --name dev-workspace --image my-dev-box \
    --home "${HOST_HOME}/.local/share/dev-workspace" \
    --volume "${HOST_HOME}/code:/home/${USER}/code" \
    --volume "${HOST_HOME}/.cache/huggingface:/home/${USER}/.cache/huggingface" \
    --volume "${HOST_HOME}/.claude:/home/${USER}/.claude" \
    --volume "${HOST_HOME}/Sync:/home/${USER}/Sync" \
    -Y

echo "=== Phase 5: Initializing GNU Stow inside Container ==="
# Clean up existing files in container home to prevent Stow/symlink conflicts
distrobox enter dev-workspace -- sh -c 'rm -rf ~/.config/alacritty ~/.config/starship.toml ~/.config/nvim ~/.config/yazi ~/.config/git ~/.config/eza ~/.npmrc ~/.gitconfig ~/.zshrc ~/.zprofile ~/.profile ~/.zsh ~/.claude.json ~/.ssh ~/.zshrc.local ~/.gitconfig.local'

# Symlink host dotfiles into container home so Stow can find it
distrobox enter dev-workspace -- sh -c 'ln -sfn "/run/host/var/home/'"${USER}"'/.dotfiles" ~/.dotfiles 2>/dev/null || ln -sfn "/run/host/home/'"${USER}"'/.dotfiles" ~/.dotfiles 2>/dev/null || true'

# Symlink direct volume mount paths inside container home using /run/host paths
distrobox enter dev-workspace -- sh -c 'ln -sfn "/run/host/var/home/'"${USER}"'/code" ~/code 2>/dev/null || true'
distrobox enter dev-workspace -- sh -c 'ln -sfn "/run/host/var/home/'"${USER}"'/.claude" ~/.claude 2>/dev/null || true'
distrobox enter dev-workspace -- sh -c 'ln -sfn "/run/host/var/home/'"${USER}"'/Sync" ~/Sync 2>/dev/null || true'
distrobox enter dev-workspace -- sh -c 'ln -sfn "/run/host/var/home/'"${USER}"'/.gemini" ~/.gemini 2>/dev/null || true'
distrobox enter dev-workspace -- sh -c 'ln -sfn "/run/host/var/home/'"${USER}"'/.claude.json" ~/.claude.json 2>/dev/null || true'
distrobox enter dev-workspace -- sh -c 'ln -sfn "/run/host/var/home/'"${USER}"'/.ssh" ~/.ssh 2>/dev/null || true'
distrobox enter dev-workspace -- sh -c 'ln -sfn "/run/host/var/home/'"${USER}"'/Sync/config/.zshrc.local" ~/.zshrc.local 2>/dev/null || true'
distrobox enter dev-workspace -- sh -c 'ln -sfn "/run/host/var/home/'"${USER}"'/Sync/config/.gitconfig.local" ~/.gitconfig.local 2>/dev/null || true'

# Clone Oh My Zsh to the container's isolated home directory if not present
if [ ! -d "${HOST_HOME}/.local/share/dev-workspace/.oh-my-zsh" ]; then
    echo "Cloning Oh My Zsh for container..."
    git clone https://github.com/ohmyzsh/ohmyzsh.git "${HOST_HOME}/.local/share/dev-workspace/.oh-my-zsh"
fi

# Ensure Zsh plugins are present in stow/zsh/.zsh/plugins
mkdir -p "${DOTFILES}/stow/zsh/.zsh/plugins"
if [ ! -f "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    echo "Cloning zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions.git "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-autosuggestions"
fi
if [ ! -f "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    echo "Cloning zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${DOTFILES}/stow/zsh/.zsh/plugins/zsh-syntax-highlighting"
fi

# Run GNU Stow inside the container
STOW_PACKAGES=(alacritty zsh starship nvim yazi git eza npm)
if [ "$INSTALL_LEMONADE" = "true" ]; then
    STOW_PACKAGES+=(lemonade)
fi
distrobox enter dev-workspace -- stow -d "/home/${USER}/.local/share/dev-workspace/.dotfiles/stow" -t "/home/${USER}/.local/share/dev-workspace" "${STOW_PACKAGES[@]}"

# Symlink bun and bunx inside container .local/bin for MCP servers compatibility
distrobox enter dev-workspace -- sh -c 'mkdir -p ~/.local/bin && ln -sfn /usr/local/bin/bun ~/.local/bin/bun && ln -sfn /usr/local/bin/bunx ~/.local/bin/bunx'
# Symlink host agy binary inside container .local/bin
distrobox enter dev-workspace -- sh -c 'mkdir -p ~/.local/bin && (ln -sfn "/run/host/var/home/'"${USER}"'/.local/bin/agy" ~/.local/bin/agy 2>/dev/null || ln -sfn "/run/host/home/'"${USER}"'/.local/bin/agy" ~/.local/bin/agy 2>/dev/null || true)'


# Change default container shell to Zsh
distrobox enter dev-workspace -- sudo chsh -s /usr/bin/zsh "${USER}"

echo "=== Phase 6: Cleaning Host Home of Duplicate Configurations ==="
# Prevent host environment contamination (keep .bashrc/.profile with ~/.local/bin in PATH)
configs=(
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

# Ensure host shell PATH includes ~/.local/bin for agy in cosmic-term and host shells
for profile_file in "${HOST_HOME}/.bashrc" "${HOST_HOME}/.profile"; do
    touch "${profile_file}"
    if ! grep -q '\.local/bin' "${profile_file}" 2>/dev/null; then
        echo 'export PATH="${HOME}/.local/bin:${PATH}"' >> "${profile_file}"
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
