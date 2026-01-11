#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_DIR="$REPO_ROOT/configs"
ENV_FILE="$REPO_ROOT/.env"

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

#######################################
# LOGS
#######################################
log()  { echo -e "➡️  $*"; }
ok()   { echo -e "✅ $*"; }
warn() { echo -e "⚠️ $*"; }
err()  { echo -e "❌ $*" >&2; exit 1; }

#######################################
# DRY-RUN
#######################################
run() {
  if [[ "$DRY_RUN" == true ]]; then
    log "[dry-run] $*"
  else
    "$@" || err "Falhou: $*"
  fi
}

#######################################
# BACKUP NO MESMO LOCAL
#######################################
backup_file() {
  local file="$1"
  [[ -f "$file" ]] || return

  local backup="${file}.bak"

  if [[ "$DRY_RUN" == true ]]; then
    log "DRY-RUN: Backup $file -> $backup"
  else
    cp -f "$file" "$backup"
    ok "Backup criado: $backup"
  fi
}

#######################################
# APLICAR ARQUIVO
#######################################
apply_file() {
  local src="$1"
  local dest="$2"

  [[ -f "$src" ]] || return

  if [[ -f "$dest" ]] && cmp -s "$src" "$dest"; then
    ok "$(basename "$dest") já está atualizado"
    return
  fi

  backup_file "$dest"

  run mkdir -p "$(dirname "$dest")"
  run cp -f "$src" "$dest"

  ok "$(basename "$dest") aplicado"
}

#######################################
# GITCONFIG COM ENV
#######################################
apply_gitconfig() {
  local src="$CONFIG_DIR/.gitconfig"
  local dest="$HOME/.gitconfig"
  local tmp

  [[ -f "$src" ]] || return

  log "Processando .gitconfig..."

  tmp="$(mktemp)"

  # Carrega .env se existir
  if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
  fi

  envsubst < "$src" > "$tmp"

  if [[ -f "$dest" ]] && cmp -s "$tmp" "$dest"; then
    ok ".gitconfig já está atualizado"
    rm -f "$tmp"
    return
  fi

  backup_file "$dest"

  run cp -f "$tmp" "$dest"
  rm -f "$tmp"

  ok ".gitconfig aplicado"
}

#######################################
# APPLY DOTFILES
#######################################
apply_dotfiles() {
  log "Aplicando dotfiles..."

  apply_gitconfig

  apply_file "$CONFIG_DIR/.zshrc" "$HOME/.zshrc"
  apply_file "$CONFIG_DIR/.tmux.conf" "$HOME/.tmux.conf"

  apply_file "$CONFIG_DIR/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
  apply_file "$CONFIG_DIR/MangoHud.conf" "$HOME/.config/MangoHud/MangoHud.conf"
  apply_file "$CONFIG_DIR/starship.toml" "$HOME/.config/starship.toml"

  ok "Dotfiles aplicados com sucesso."
}

#######################################
# USAGE
#######################################
usage() {
  echo "Uso: sync-dotfiles.sh [--dry-run]"
  exit 0
}

#######################################
# MAIN
#######################################
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      -h|--help) usage ;;
      *) err "Argumento desconhecido: $1" ;;
    esac
    shift
  done

  apply_dotfiles
}

main "$@"
