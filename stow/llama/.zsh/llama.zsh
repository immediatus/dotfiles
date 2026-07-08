# ~/.dotfiles/stow/zsh/.zsh/llama.zsh
# Zsh extension for control of host-level Llama model service

llama() {
    if [ -f /run/.containerenv ] && command -v distrobox-host-exec &>/dev/null; then
        distrobox-host-exec "${DISTROBOX_HOST_HOME}/.local/bin/llama" "$@"
    else
        # If running on host, call the local bin script directly
        if [ -x "$HOME/.local/bin/llama" ]; then
            "$HOME/.local/bin/llama" "$@"
        else
            echo "llama standalone script not found at ~/.local/bin/llama"
            return 1
        fi
    fi
}


_llama() {
  local curcontext="$curcontext" state line
  typeset -A opt_args

  _arguments -C \
    '1:subcommand:((
      setup\:"Initialize llama server"
      switch\:"Switch model presets"
      status\:"Service status"
      start\:"Start service"
      stop\:"Stop service"
      restart\:"Restart service"
      logs\:"View live logs"
      save\:"Save slot state"
      load\:"Load slot state"
      simple-state\:"Brief status"
    ))' \
    '*::arg:->args'

  case $state in
    args)
      case $words[1] in
        switch)
          local -a profiles
          local config_file=""
          if [ -f /run/.containerenv ]; then
             config_file="/run/host${DISTROBOX_HOST_HOME}/models/models.json"
          else
             config_file="$HOME/models/models.json"
          fi
          if [ -f "$config_file" ]; then
             profiles=( $(python3 -c "import json; print(' '.join(json.load(open('$config_file')).keys()))" 2>/dev/null) )
          else
             profiles=(expert reson agent simple)
          fi
          _values 'model profiles' $profiles
          ;;
        load)
          local -a bins
          local models_dir=""
          if [ -f /run/.containerenv ]; then
             models_dir="/run/host${DISTROBOX_HOST_HOME}/models"
          else
             models_dir="$HOME/models"
          fi
          bins=(${${(f)"$(ls $models_dir/*.bin 2>/dev/null)"}#*$models_dir/})
          [[ -n $bins ]] && _values 'saved states' ${bins%.bin}
          ;;
        save)
          _message "filename (without .bin)"
          ;;
      esac
      ;;
  esac
}

compdef _llama llama
