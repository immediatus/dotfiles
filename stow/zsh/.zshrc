# ~/.dotfiles/stow/zsh/.zshrc
# Zsh configuration file - optimized for reliability, speed, and portability

# Automatically switch to container's isolated home directory if starting in the host home
if [[ -f /run/.containerenv ]] && [[ "$PWD" == "/run/host/var/home/$USER" || "$PWD" == "/run/host/home/$USER" ]]; then
    cd "$HOME"
fi

# -----------------------------------------------------------------------------
# 1. Environment & Path Configurations
# -----------------------------------------------------------------------------
export PYENV_ROOT="$HOME/.pyenv"
export JENV_ROOT="$HOME/.jenv"
export BUN_INSTALL="$HOME/.bun"
export EDITOR="nvim"
export VISUAL="nvim"

# Load local environment overrides (untracked credentials, etc.)
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi


# Keep path entries unique and filter out non-existent directories
typeset -U path
path=(
    $PYENV_ROOT/bin(N)
    $JENV_ROOT/bin(N)
    $HOME/.cargo/bin(N)
    $HOME/bin(N)
    $HOME/.local/bin(N)
    $HOME/.npm-global/bin(N)
    $BUN_INSTALL/bin(N)
    $path
)

# Tool initializations
if command -v pyenv &>/dev/null; then eval "$(pyenv init --path zsh)"; fi
if command -v jenv &>/dev/null; then eval "$(jenv init - zsh)"; fi
[ -s "${BUN_INSTALL}/_bun" ] && source "${BUN_INSTALL}/_bun"

# Podman socket for devcontainers
export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"

# -----------------------------------------------------------------------------
# 2. Oh My Zsh Initialization
# -----------------------------------------------------------------------------
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="robbyrussell"
plugins=(git jenv pyenv common-aliases fzf)

# Initialize OhMyZsh
if [ -d "$ZSH" ]; then
    source "$ZSH/oh-my-zsh.sh"
fi

# -----------------------------------------------------------------------------
# 3. Interactive Shell Options & History
# -----------------------------------------------------------------------------
HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"

setopt SHARE_HISTORY          # Share history between sessions
setopt APPEND_HISTORY         # Append history rather than replace
setopt HIST_IGNORE_DUPS       # Ignore duplicate runs of same command
setopt HIST_IGNORE_ALL_DUPS   # Remove older duplicate command from history
setopt HIST_REDUCE_BLANKS     # Remove superfluous blanks from history items
setopt HIST_VERIFY            # Show command with history expansion before running

# GH Copilot CLI bindings
bindkey '^[|' zsh_gh_copilot_explain  # Alt+shift+\ to explain
bindkey '^[\' zsh_gh_copilot_suggest  # Alt+\ to suggest

# -----------------------------------------------------------------------------
# 4. Aliases
# -----------------------------------------------------------------------------
# Text Editors
alias vim=nvim
alias vi=nvim

# Clipboard integration (Wayland native with X11 fallback)
if command -v wl-copy &>/dev/null; then
    alias pbcopy='wl-copy'
    alias pbpaste='wl-paste'
    alias cb='wl-copy'
elif command -v xclip &>/dev/null; then
    alias pbcopy='xclip -selection clipboard'
    alias pbpaste='xclip -selection clipboard -o'
    alias cb='xclip -selection clipboard'
fi

# Modern alternatives (with fallback to standard coreutils)
if command -v eza &>/dev/null; then
    alias l='eza --icons'
    alias ll='eza --icons --group-directories-first --header --no-user --colour-scale -l'
    alias la='eza --icons --group-directories-first --header --no-user --colour-scale -al'
else
    alias l='ls -CF'
    alias ll='ls -alF'
    alias la='ls -A'
fi

alias open='xdg-open'
alias cdev='claude-dev'
alias code='opencode'
alias yy='yazi'

# -----------------------------------------------------------------------------
# 5. Fuzzy Finder (fzf) Configuration
# -----------------------------------------------------------------------------
if command -v fzf &>/dev/null; then
    export FZF_BASE=/usr/bin/fzf
    
    if command -v fd &>/dev/null; then
        export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --exclude .git'
    fi

    # Core Options - Handle Tabs in folder list with delimiter and full preview styling
    export FZF_DEFAULT_OPTS="--style=full
     --delimiter='\t'
     --preview 'fzf-preview.sh {-1}'
     --bind 'focus:transform-header:file --brief {-1}'
     --bind 'ctrl-/:toggle-preview'
     --color=fg:#fafafa,bg:#171d23,hl:#4cc3ff
     --color=fg+:#14ff57,bg+:#171d23,hl+:#ffff4a
     --color=info:#ff6969,prompt:#09ff00,pointer:#14ff57
     --color=marker:#a3a3a3,spinner:#af5fff,header:#ff6969"

    # Widget specific overrides
    export FZF_CTRL_T_OPTS="--preview 'fzf-preview.sh {-1}' --border-label=' File Search '"
    export FZF_ALT_C_OPTS="--preview 'fzf-preview.sh {-1}' --border-label=' Directory Search '"
    export FZF_CTRL_R_OPTS="--preview 'echo {}' --preview-window=down:3:hidden:wrap --bind '?:toggle-preview' --border-label=' History '"

    source <(fzf --zsh)
fi

# -----------------------------------------------------------------------------
# 6. Helper Functions & Extensions
# -----------------------------------------------------------------------------



# Path translation helper for host container operations
to_host_path() {
    local p="$1"
    if [[ "$p" != /* ]]; then
        p="$PWD/$p"
    fi
    p="${p:A}"
    local host_home="/var/home/$USER"
    if [[ "$p" == /run/host/var/home/$USER/* ]]; then
        p="${p/#\/run\/host\/var\/home\/$USER/$host_home}"
    elif [[ "$p" == /run/host/home/$USER/* ]]; then
        p="${p/#\/run\/host\/home\/$USER/$host_home}"
    elif [[ "$p" == /home/$USER/code/* ]]; then
        # Direct volume mount, do not translate to isolated home
        :
    elif [[ "$p" == /home/$USER/models/* ]]; then
        # Direct volume mount, do not translate to isolated home
        :
    elif [[ "$p" == /home/$USER/.claude/* ]]; then
        # Direct volume mount, do not translate to isolated home
        :
    elif [[ "$p" == /home/$USER/Sync/* ]]; then
        # Direct volume mount, do not translate to isolated home
        :
    elif [[ "$p" == /home/$USER/* ]]; then
        p="${p/#\/home\/$USER/$host_home/.local/share/dev-workspace}"
    fi
    echo "$p"
}

# Private helper to spin up devcontainers
_start_devcontainer() {
    if [ ! -d ".devcontainer" ]; then
        echo "No .devcontainer found in the current directory." >&2
        return 1
    fi

    echo "Spinning up the development workspace..." >&2
    local PODMAN_BIN=$(which podman || echo "$HOME/.local/bin/podman")
    local COMPOSE_BIN=$(which podman-compose || which docker-compose 2>/dev/null || echo "")
    local folder_name=$(basename "$PWD")

    export UID=$(id -u) GID=$(id -g)
    export WORKSPACES_PATH="workspaces/$folder_name"

    # Translate PWD to host visible path for querying container
    local host_pwd=$(to_host_path "$PWD")

    # Ensure host Claude, Gemini, and agy files have the correct SELinux labels for container access
    chcon -R -t container_file_t "/home/$USER/.claude" "/home/$USER/.claude.json" "/home/$USER/.gemini" "/home/$USER/.local/bin/agy" &>/dev/null || true

    HOME="/home/$USER" devcontainer up \
        --workspace-folder . \
        --docker-path "$PODMAN_BIN" \
        ${COMPOSE_BIN:+--docker-compose-path} ${COMPOSE_BIN:+"$COMPOSE_BIN"} >&2

    local container_id=$("$PODMAN_BIN" ps -q --filter "label=devcontainer.local_folder=$host_pwd" | head -n 1)

    if [ -z "$container_id" ]; then
        local project_name=$(echo "$folder_name" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9-_')
        container_id=$("$PODMAN_BIN" ps --format "{{.ID}}" --filter "name=${project_name}_app" | head -n 1)
    fi

    if [ -z "$container_id" ]; then
        echo "Error: Container vanished or failed to start. Run 'podman ps -a' to debug." >&2
        return 1
    fi

    echo "$container_id"
}

# General container entry tool
enter() {
    local target="$1"

    # Case 1: Enter a Distrobox container by name
    if [ -n "$target" ]; then
        distrobox-host-exec distrobox enter "$target"
        return $?
    fi

    # Case 2: Enter project devcontainer
    if [ -d ".devcontainer" ]; then
        local container_id
        container_id=$(_start_devcontainer) || return 1
        local folder_name=$(basename "$PWD")
        local PODMAN_BIN=$(which podman || echo "$HOME/.local/bin/podman")

        local shell_bin="bash"
        if "$PODMAN_BIN" exec "$container_id" sh -c "command -v zsh" &>/dev/null; then
            shell_bin="zsh"
        elif "$PODMAN_BIN" exec "$container_id" sh -c "command -v bash" &>/dev/null; then
            shell_bin="bash"
        else
            shell_bin="sh"
        fi

        echo "Target acquired: $container_id. Injecting interactive terminal (${shell_bin})..."
        "$PODMAN_BIN" exec -it \
            --workdir "/workspaces/$folder_name" \
            "$container_id" \
            "$shell_bin"
    else
        echo "Error: No .devcontainer folder found in the current directory."
        echo ""
        echo "Usage:"
        echo "  enter <container-name>      Enter a Distrobox container (e.g., enter dev-station)"
        echo "  enter                       Spin up and enter the current project's devcontainer"
        return 1
    fi
}



# Source Zsh Plugins (Manual overrides if not managed by OhMyZsh)
if [ -f "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$HOME/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
if [ -f "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$HOME/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Source extra Zsh Extensions (zola.zsh, llama.zsh, etc.)
for ext in "$HOME"/.zsh/*.zsh; do
    [ -f "$ext" ] && source "$ext"
done

# Initialize Starship Prompt (must be at the very end to override ZSH theme)
if command -v starship &>/dev/null; then
    eval "$(starship init zsh)"
fi
