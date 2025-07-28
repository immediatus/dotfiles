# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git jenv pyenv common-aliases tmux)

# ZSH config
ZSH_COLORIZE_TOOL=pygmentize

source $ZSH/oh-my-zsh.sh

# Default editor
EDITOR=/bin/nvim

# Aliases
alias vim=nvim
alias vi=nvim
alias cb='xclip -sel clip'
alias bat=batcat
alias la='eza --group-directories-first --header --no-user --colour-scale -al'
alias ll='eza --group-directories-first --header --no-user --colour-scale -l'

# Starship
eval "$(starship init zsh)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
 --color=fg:#fafafa,bg:#171d23,hl:#4cc3ff
 --color=fg+:#14ff57,bg+:#171d23,hl+:#ffff4a
 --color=info:#ff6969,prompt:#09ff00,pointer:#14ff57
 --color=marker:#a3a3a3,spinner:#af5fff,header:#ff6969'

# PyEnv config
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path zsh)"

# JEnv config
export JENV_ROOT="$HOME/.jenv"
export PATH="$JENV_ROOT/bin:$PATH"
eval "$(jenv init - zsh)"


# PATH
export PATH="$HOME/.cargo/bin:$HOME/bin:$PATH"

# Bindings

# Copilot
bindkey '^[|' zsh_gh_copilot_explain  # bind Alt+shift+\ to explain
bindkey '^[\' zsh_gh_copilot_suggest  # bind Alt+\ to suggest


# Gemini CLI
export GEMINI_API_KEY=""


