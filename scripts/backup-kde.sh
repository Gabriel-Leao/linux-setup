#!/usr/bin/env bash
set -euo pipefail

#######################################
# VARIÁVEIS
#######################################
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKUP_DIR="$REPO_ROOT/kde-backup"
BACKUP_FILE="$BACKUP_DIR/kde-configs.7z"

TMP_KDE_DIR="/tmp/kde-backup-work"

DRY_RUN=false

#######################################
# LOG
#######################################
log()  { echo -e "➡️  $*"; }
ok()   { echo -e "✅ $*"; }
warn() { echo -e "⚠️  $*"; }
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
# BACKUP KDE
#######################################
backup_kde() {
  log "Preparando backup KDE..."

  run mkdir -p "$BACKUP_DIR"
  run rm -rf "$TMP_KDE_DIR"
  run mkdir -p "$TMP_KDE_DIR"

  log "Copiando arquivos KDE..."

  [[ -f "$HOME/.config/kdeglobals" ]]        && run cp "$HOME/.config/kdeglobals" "$TMP_KDE_DIR/"
  [[ -f "$HOME/.config/kglobalshortcutsrc" ]] && run cp "$HOME/.config/kglobalshortcutsrc" "$TMP_KDE_DIR/"
  [[ -f "$HOME/.config/kwinrc" ]]            && run cp "$HOME/.config/kwinrc" "$TMP_KDE_DIR/"
  [[ -f "$HOME/.config/systemsettingsrc" ]]  && run cp "$HOME/.config/systemsettingsrc" "$TMP_KDE_DIR/"
  [[ -d "$HOME/.config/plasma" ]]            && run cp -r "$HOME/.config/plasma"* "$TMP_KDE_DIR/"

  [[ -d "$HOME/.local/share/plasma" ]]       && run cp -r "$HOME/.local/share/plasma" "$TMP_KDE_DIR/"
  [[ -d "$HOME/.local/share/icons" ]]        && run cp -r "$HOME/.local/share/icons" "$TMP_KDE_DIR/"
  [[ -d "$HOME/.local/share/wallpapers" ]]   && run cp -r "$HOME/.local/share/wallpapers" "$TMP_KDE_DIR/"

  log "Compactando para $BACKUP_FILE"
  run 7z a -t7z -mx=9 "$BACKUP_FILE" "$TMP_KDE_DIR"

  run rm -rf "$TMP_KDE_DIR"

  ok "Backup KDE salvo no repositório: $BACKUP_FILE"
}

#######################################
# MAIN
#######################################
main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run) DRY_RUN=true ;;
      --backup) backup_kde ;;
      -h|--help)
        echo "Uso: $0 [--dry-run] [--backup]"
        exit 0
        ;;
      *) err "Argumento desconhecido: $1" ;;
    esac
    shift
  done

  if [[ $# -eq 0 ]]; then
    backup_kde
  fi
}

main "$@"
