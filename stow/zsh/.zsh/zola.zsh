# ~/.dotfiles/stow/zsh/.zsh/zola.zsh
# Zola build/serve helper function using rootless podman

zola() {
  if [[ "$1" == "serve" || $# -eq 0 ]]; then
    # Serve mode requires specific binding configuration for container networking
    local cmd="serve"
    shift 2>/dev/null || true
    podman run -it --rm \
      -v "$(pwd):/app:Z" \
      -w /app \
      -p 8000:8000 \
      ghcr.io/getzola/zola:v0.22.1 \
      "$cmd" --interface 0.0.0.0 --port 8000 --base-url 127.0.0.1 "$@"
  else
    # Non-serve commands (e.g., build) do not need to publish ports or bind interface
    podman run -it --rm \
      -v "$(pwd):/app:Z" \
      -w /app \
      ghcr.io/getzola/zola:v0.22.1 \
      "$@"
  fi
}
