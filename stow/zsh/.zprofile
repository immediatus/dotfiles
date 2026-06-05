# Zsh login shell configuration (.zprofile)
# Written from scratch for a clean, reproducible setup

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    PATH="$HOME/.local/bin:$PATH"
fi

# PyEnv config
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv &>/dev/null; then eval "$(pyenv init --path zsh)"; fi

# JEnv config
export JENV_ROOT="$HOME/.jenv"
export PATH="$JENV_ROOT/bin:$PATH"
if command -v jenv &>/dev/null; then eval "$(jenv init - zsh)"; fi
