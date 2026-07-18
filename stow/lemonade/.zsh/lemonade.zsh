# ~/.dotfiles/stow/lemonade/.zsh/lemonade.zsh
# Zsh extension for Lemonade local AI server

_lemonade() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    '1:subcommand:((
      run\:"Load model and chat in browser"
      chat\:"Interactive chat REPL in terminal"
      launch\:"Launch local agent"
      list\:"List available models"
      pull\:"Download a model"
      load\:"Load model into memory"
      unload\:"Unload model from memory"
      delete\:"Remove model files"
      status\:"Check server status"
      config\:"Manage settings"
      scan\:"Scan for network beacons"
    ))' \
    '*::arg:->args'
}

compdef _lemonade lemonade
