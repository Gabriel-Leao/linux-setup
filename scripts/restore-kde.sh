#!/usr/bin/env bash
set -euo pipefail

#######################################
# CONFIGURAÇÃO
#######################################
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

ARCHIVE="../kde-backup/kde-configs.7z"
TEMP_DIR="/tmp/kde-restore"

log() { echo "[RESTORE KDE] $1"; }

#######################################
# CHECAR ARQUIVO DE BACKUP
#######################################
if [[ ! -f "$ARCHIVE" ]]; then
  log "Arquivo não encontrado: $ARCHIVE"
  exit 1
fi

log "Extraindo configs KDE..."

if $DRY_RUN; then
  echo "DRY-RUN 7z x $ARCHIVE -o$TEMP_DIR"
else
  rm -rf "$TEMP_DIR"
  mkdir -p "$TEMP_DIR"
  7z x "$ARCHIVE" -o"$TEMP_DIR" >/dev/null
fi

log "Restaurando arquivos..."

restore() {
  for src in "$1"/*; do
    [[ -e "$src" ]] || continue

    dest="$HOME/$(basename "$src")"

    if [[ -f "$dest" && -f "$src" ]]; then
      if cmp -s "$src" "$dest"; then
        log "Igual ao existente, pulando: $(basename "$src")"
        continue
      fi
    fi

    if $DRY_RUN; then
      echo "DRY-RUN cp -r '$src' '$dest'"
    else
      cp -r "$src" "$dest"
      log "Restaurado: $(basename "$src")"
    fi
  done
}

# Verifica se existem arquivos para restaurar
if compgen -G "$TEMP_DIR/kde/*" > /dev/null; then
  restore "$TEMP_DIR/kde"
else
  log "Nenhum arquivo para restaurar."
fi

log "Limpando arquivos temporários..."

if $DRY_RUN; then
  echo "DRY-RUN rm -rf $TEMP_DIR"
else
  rm -rf "$TEMP_DIR"
fi

log "Restore KDE finalizado. Reinicie a sessão para aplicar todas as alterações."
