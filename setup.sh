#!/usr/bin/env bash
set -uo pipefail

#######################################
# PROTEÇÃO
#######################################
[[ "$EUID" -eq 0 ]] && { echo "❌ Não execute como root."; exit 1; }

#######################################
# VARIÁVEIS GLOBAIS
#######################################
SCRIPT_NAME="$(basename "$0")"
TMP_DIR="/tmp/paru"

JAVA_VERSION=""
NODE_VERSION=""

# Variáveis de sistema - usadas em múltiplas funções
IS_ARCH=false
IS_CACHY=false
IS_KDE=false

DO_ARCH=false
DO_AUR=false
DO_FLATPAK=false
DO_DOCKER=false
DO_GAMES=false
DO_ALL=false
DO_SYNC_DOTFILES=false

SHOW_HELP=false
DRY_RUN=false

#######################################
# LOGGING
#######################################
log()  { echo -e "➡️  $*"; }
ok()   { echo -e "✅ $*"; }
warn() { echo -e "⚠️  $*"; }
err()  { echo -e "❌ $*" >&2; exit 1; }

#######################################
# DETECÇÃO DO SISTEMA (ESTRITA + USO EXPLÍCITO)
#######################################
detect_system() {
  [[ ! -f /etc/os-release ]] && {
    err "Arquivo /etc/os-release não encontrado. Abortando."
  }
  
  . /etc/os-release

  if [[ "$ID" == "arch" ]]; then
    IS_ARCH=true
    ok "Sistema Arch Linux detectado: $PRETTY_NAME"
  elif [[ "$ID" == "cachyos" ]]; then
    IS_CACHY=true
    ok "Sistema CachyOS detectado: $PRETTY_NAME"
  else
    err "❌ SISTEMA NÃO SUPORTADO: $PRETTY_NAME ($ID)"
    err "Este script executa APENAS em Arch Linux ou CachyOS"
    err "Seu sistema: $NAME $VERSION"
    exit 1
  fi

  if $IS_ARCH; then
    log "Modo Arch ativado"
  elif $IS_CACHY; then
    log "Modo CachyOS ativado"
  fi

  if [[ "${XDG_CURRENT_DESKTOP:-}" =~ KDE|Plasma ]] || \
     [[ "${DESKTOP_SESSION:-}" =~ plasma ]]; then
    IS_KDE=true
    ok "Desktop: KDE Plasma"
  else
    warn "Desktop não é KDE ($XDG_CURRENT_DESKTOP)"
  fi
}

#######################################
# DRY-RUN WRAPPER (GLOBAL)
#######################################
run() {
  if [[ "$DRY_RUN" == true ]]; then
    log "[dry-run] $*"
    return 0
  else
    "$@"
    local status=$?
    [[ $status -eq 0 ]] || warn "Falhou (mas continuando): $* (exit code: $status)"
    return $status
  fi
}

run_pipe() {
  if [[ "$DRY_RUN" == true ]]; then
    log "[dry-run] $*"
    return 0
  else
    bash -c "$*"
    local status=$?
    [[ $status -eq 0 ]] || warn "Falhou (mas continuando): $* (exit code: $status)"
    return $status
  fi
}

#######################################
# FUNÇÕES DE SYNC DOTFILES
#######################################
sync_dotfiles() {
  log "Aplicando dotfiles..."
  local args=()
  [[ "$DRY_RUN" == true ]] && args+=(--dry-run)
  run bash scripts/sync-dotfiles.sh "${args[@]}" || warn "Dotfiles falhou"
}

#######################################
# PACOTES BASE (CRÍTICO)
#######################################
install_base_packages() {
  log "Instalando pacotes base..."
  sudo pacman -S --needed --noconfirm \
    git curl flatpak zsh tmux bat ufw base-devel \
    || err "❌ FALHA CRÍTICA: Não foi possível instalar pacotes base"
}

#######################################
# PARU (CRÍTICO)
#######################################
install_paru() {
  command -v paru &>/dev/null && { ok "Paru já instalado"; return 0; }

  log "Instalando Paru (CRÍTICO)..."
  run rm -rf "$TMP_DIR" || err "Falha ao limpar $TMP_DIR"
  run git clone https://aur.archlinux.org/paru.git "$TMP_DIR" \
    || err "❌ FALHA CRÍTICA: Não foi possível clonar Paru"

  (
    cd "$TMP_DIR" || err "Falha ao entrar em $TMP_DIR"
    run makepkg -si --noconfirm \
      || err "❌ FALHA CRÍTICA: Não foi possível compilar/instalar Paru"
  )
  
  command -v paru &>/dev/null || err "❌ FALHA CRÍTICA: Paru não está funcional"
  ok "Paru instalado com sucesso"
}

#######################################
# SHELL (CRÍTICO - SEM EDITAR .zshrc)
#######################################
setup_shell() {
  log "Configurando ZSH (sem editar .zshrc)..."

  local current_shell
  current_shell="$(getent passwd "$USER" | cut -d: -f7 | tr -d '\n')"

  [[ "$current_shell" == "$(command -v zsh)" ]] || \
    run chsh -s "$(command -v zsh)" || err "❌ FALHA CRÍTICA: Não foi possível mudar shell para ZSH"

  [[ -d "$HOME/.oh-my-zsh" ]] || {
    run_pipe 'RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"' \
      || err "❌ FALHA CRÍTICA: Não foi possível instalar Oh My Zsh"
  }

  [[ -d "$HOME/.local/share/zinit/zinit.git" ]] || {
    run git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" \
      || err "❌ FALHA CRÍTICA: Não foi possível instalar Zinit"
  }

  ok "ZSH + Oh My Zsh + Zinit instalados (dotfiles configuram .zshrc)"
}

#######################################
# PACOTES ARCH
#######################################
install_arch_packages() {
  log "Instalando pacotes oficiais do Arch..."

  BASE_PACKAGES=(
    docker
    docker-buildx
    docker-compose
    fuse2
    libreoffice-fresh
    obs-studio
    qbittorrent
  )

  KDE_PACKAGES=(
    okular
    partitionmanager
    kclock
    discover
  )

  PACKAGES=("${BASE_PACKAGES[@]}")

  if [[ "$IS_KDE" == true ]]; then
    PACKAGES+=("${KDE_PACKAGES[@]}")
  fi

  run paru -S --needed --noconfirm "${PACKAGES[@]}" \
    || warn "Alguns pacotes Arch falharam"
}

#######################################
# PACOTES AUR
#######################################
install_aur_packages() {
  log "Instalando pacotes AUR..."
  run paru -S --needed --noconfirm \
    google-chrome \
    visual-studio-code-bin \
    jetbrains-toolbox \
    linuxtoys-bin || warn "Alguns pacotes AUR falharam"
}

#######################################
# MULTILIB
#######################################
enable_multilib() {
  local pacman_conf="/etc/pacman.conf"

  grep -q '^\[multilib\]' "$pacman_conf" 2>/dev/null && {
    ok "multilib já habilitado"
    return 0
  }

  grep -q '^\#\[multilib\]' "$pacman_conf" 2>/dev/null || {
    warn "Bloco [multilib] não encontrado em $pacman_conf"
    return 1
  }

  log "Habilitando multilib (apenas Arch)..."
  run sudo sed -i \
    -e 's/^#\[multilib\]/[multilib]/' \
    -e 's|^#Include = /etc/pacman.d/mirrorlist|Include = /etc/pacman.d/mirrorlist|' \
    "$pacman_conf" || warn "Falha ao editar pacman.conf"

  run sudo pacman -Sy || warn "Falha ao sincronizar repositórios após multilib"
}

#######################################
# GAMES
#######################################
install_games_packages() {
  log "Instalando pacotes para games..."

  BASE_GAMES_PACKAGES=(
    hydra-launcher-bin
    gamemode
  )

  ARCH_GAMES_PACKAGES=(
    heroic-games-launcher-bin
    mangohud
    goverlay
    steam
  )

  CACHY_EXTRA_PACKAGES=(
    cachyos-gaming-meta
  )

  PACKAGES=("${BASE_GAMES_PACKAGES[@]}")

  if $IS_ARCH; then
    enable_multilib || warn "Falha ao habilitar multilib para games"
    PACKAGES+=("${ARCH_GAMES_PACKAGES[@]}")
  elif $IS_CACHY; then
    PACKAGES+=("${CACHY_EXTRA_PACKAGES[@]}")
  fi

  run paru -S --needed --noconfirm "${PACKAGES[@]}" \
    || warn "Alguns pacotes de games falharam"
}

#######################################
# DOCKER
#######################################
setup_docker() {
  log "Configurando Docker..."
  run sudo systemctl enable --now docker || warn "Falha ao iniciar Docker"
  run sudo usermod -aG docker "$USER" || warn "Falha ao adicionar usuário ao grupo docker"
  warn "IMPORTANTE: Faça logout/login para Docker funcionar"
}

#######################################
# FIREWALL
#######################################
setup_firewall() {
  log "Configurando UFW com regras seguras..."
  run sudo ufw --force reset
  run sudo ufw default deny incoming
  run sudo ufw default allow outgoing
  run sudo ufw allow ssh
  run sudo ufw allow 53317/tcp
  run sudo ufw allow 53317/udp
  run sudo ufw --force enable
}

#######################################
# FLATPAK
#######################################
install_flatpak_apps() {
  log "Configurando Flatpak..."

  run sudo flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo || warn "Falha ao adicionar Flathub"

  local FLATPAKS=(
    app.zen_browser.zen
    com.bitwarden.desktop
    com.discordapp.Discord
    com.getpostman.Postman
    com.github.IsmaelMartinez.teams_for_linux
    com.rtosta.zapzap
    com.spotify.Client
    io.ente.auth
    md.obsidian.Obsidian
    me.iepure.devtoolbox
    org.gimp.GIMP
    org.libretro.RetroArch
    org.localsend.localsend_app
  )

  for app in "${FLATPAKS[@]}"; do
    run flatpak install -y flathub "$app" || warn "Falha ao instalar Flatpak: $app"
  done
}

#######################################
# STARSHIP
#######################################
install_starship() {
  command -v starship &>/dev/null && { ok "Starship já instalado"; return 0; }
  log "Instalando Starship..."
  run_pipe "curl -sS https://starship.rs/install.sh | sh -s -- -y" || warn "Falha ao instalar Starship"
}

#######################################
# MISE
#######################################
install_mise() {
  if ! command -v mise &>/dev/null; then
    log "Instalando Mise..."
    run_pipe "curl https://mise.run/zsh | sh" || warn "Falha ao instalar Mise"
  fi
}

#######################################
# JAVA / NODE
#######################################
configure_mise_runtimes() {
  [[ -z "$JAVA_VERSION" && -z "$NODE_VERSION" ]] && return 0
  install_mise

  [[ -n "$JAVA_VERSION" ]] && run mise use -g "java@$JAVA_VERSION" || warn "Falha Java $JAVA_VERSION"
  [[ -n "$NODE_VERSION" ]] && run mise use -g "node@$NODE_VERSION" || warn "Falha Node $NODE_VERSION"
}

#######################################
# USAGE (ATUALIZADO)
#######################################
usage() {
  cat <<EOF
Uso: $SCRIPT_NAME [flags]

--arch          Instala pacotes Arch
--aur           Instala pacotes AUR  
--flatpak       Instala Flatpaks
--docker        Configura Docker
--games         Instala pacotes games
--java <ver>    Configura Java
--node <ver>    Configura Node

🔄 OPERAÇÕES DE BACKUP/DOTFILES:
--sync-dotfiles Aplica dotfiles

--dry-run       MODO TESTE (NADA É EXECUTADO)
-h, --help

ATENÇÃO: Executa APENAS em Arch Linux e CachyOS
EOF
  exit 0
}

#######################################
# MAIN (ATUALIZADO)
#######################################
main() {
  detect_system

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --arch) DO_ARCH=true ;;
      --aur) DO_AUR=true ;;
      --flatpak) DO_FLATPAK=true ;;
      --docker) DO_DOCKER=true ;;
      --games) DO_GAMES=true ;;
      --sync-dotfiles) DO_SYNC_DOTFILES=true ;;
      --java)
        [[ -z "${2:-}" ]] && { err "--java requer versão"; exit 1; }
        JAVA_VERSION="$2"; shift ;;
      --node)
        [[ -z "${2:-}" ]] && { err "--node requer versão"; exit 1; }
        NODE_VERSION="$2"; shift ;;
      --dry-run) DRY_RUN=true; log "🚫 MODO DRY-RUN ATIVADO - NADA SERÁ EXECUTADO" ;;
      -h|--help) SHOW_HELP=true ;;
      *) err "Flag desconhecida: $1" ;;
    esac
    shift
  done

  $SHOW_HELP && usage
  $DO_SYNC_DOTFILES  && sync_dotfiles

  # CRÍTICO: Para se qualquer um falhar
  install_base_packages
  install_paru

  # OPCIONAL: Continua mesmo se falhar
  ($DO_ALL || $DO_ARCH)    && install_arch_packages
  ($DO_ALL || $DO_AUR)     && install_aur_packages
  ($DO_ALL || $DO_FLATPAK) && install_flatpak_apps
  ($DO_ALL || $DO_DOCKER)  && setup_docker && setup_firewall
  ($DO_ALL || $DO_GAMES)   && install_games_packages

  if [[ "$DO_ALL" == true ]]; then
    install_starship
    install_mise
    configure_mise_runtimes
    sync_dotfiles
    setup_shell
  fi

  run flatpak update -y || warn "Flatpak update falhou"

  ok "✅ Setup finalizado com sucesso!"
  [[ "$DRY_RUN" != true ]] && warn "⚠️  Alguns passos podem ter falhado - verifique os warnings acima"
  warn "🔄 Logout/login pode ser necessário para algumas mudanças"
}

main "$@"
