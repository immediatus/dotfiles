# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# Aliases
alias vim=nvim

# Linux aliases
alias clipboard='xclip -sel clip'

# Default editor
EDITOR=/snap/bin/nvim

# Starship
eval "$(starship init zsh)"

# Set up fzf key bindings and fuzzy completion
source <(fzf --zsh)

# PyEnv config
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# JEnv config
export PATH="$HOME/.jenv/bin:$PATH"
eval "$(jenv init -)"
