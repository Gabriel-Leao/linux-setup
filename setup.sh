#!/usr/bin/env bash
set -e

echo "🚀 Iniciando setup do sistema..."

#######################################
# 1. DETECÇÃO DO SISTEMA
#######################################
if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "❌ Não foi possível detectar o sistema"
  exit 1
fi

IS_ARCH=false
if [[ "$ID" = "arch" || "$ID_LIKE" == *"arch"* ]]; then
  IS_ARCH=true
fi

echo "🖥 Sistema detectado: $NAME ($ID)"

#######################################
# 2. ARCH: INSTALAÇÃO DO YAY
#######################################
if $IS_ARCH; then
  echo "🐧 Sistema baseado em Arch"

  if command -v yay >/dev/null 2>&1; then
    echo "✔ yay já instalado"
  else
    echo "📦 Instalando yay..."
    sudo pacman -S --needed --noconfirm base-devel git

    TMP_DIR=$(mktemp -d)
    git clone https://aur.archlinux.org/yay.git "$TMP_DIR/yay"
    cd "$TMP_DIR/yay"
    makepkg -si --noconfirm
    cd ~
    rm -rf "$TMP_DIR"
  fi
else
  echo "ℹ Não é Arch, pulando yay"
fi

#######################################
# 3. ARCH: PACOTES AUR
#######################################
if $IS_ARCH; then
  echo "📦 Instalando pacotes AUR..."

  YAY_PACKAGES=(
    ufw
    zsh
    fuse2
    docker
    docker-buildx
    docker-compose
    powerdevil
    power-profiles-daemon
    spectacle
    gwenview
    okular
    filelight
    kalk
    partitionmanager
    google-chrome
    tmux
    alacritty
    goverlay
    mangohud
    visual-studio-code-bin
    bat
  )

  yay -S --needed --noconfirm "${YAY_PACKAGES[@]}"
fi

#######################################
# 4. STARSHIP (UNIVERSAL)
#######################################
if ! command -v starship >/dev/null 2>&1; then
  echo "✨ Instalando Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y
else
  echo "✔ Starship já instalado"
fi

#######################################
# 5. MISE (UNIVERSAL)
#######################################
if ! command -v mise >/dev/null 2>&1; then
  echo "🔧 Instalando mise..."
  curl https://mise.run/zsh | sh
else
  echo "✔ mise já instalado"
fi

#######################################
# 6. DOCKER (UNIVERSAL)
#######################################
echo "🐳 Configurando Docker (se instalado)..."

if command -v docker >/dev/null 2>&1; then
  sudo systemctl enable --now docker.service || true
  sudo systemctl enable containerd.service || true

  if ! getent group docker >/dev/null; then
    sudo groupadd docker
  fi

  sudo usermod -aG docker "$USER"

  echo "✔ Docker configurado"
  echo "➡ Logout/login ou execute: newgrp docker"
else
  echo "ℹ Docker não encontrado, pulando configuração"
fi

#######################################
# 7. FLATPAK + FLATHUB (UNIVERSAL)
#######################################
echo "📦 Configurando Flatpak..."

if ! flatpak remote-list | grep -q flathub; then
  sudo flatpak remote-add --if-not-exists flathub \
    https://flathub.org/repo/flathub.flatpakrepo
fi

FLATPAKS=(
  app.zen_browser.zen
  com.bitwarden.desktop
  com.discordapp.Discord
  com.getpostman.Postman
  com.github.IsmaelMartinez.teams_for_linux
  com.heroicgameslauncher.hgl
  com.obsproject.Studio
  com.rtosta.zapzap
  com.spotify.Client
  com.valvesoftware.Steam
  io.ente.auth
  md.obsidian.Obsidian
  me.iepure.devtoolbox
  org.gimp.GIMP
  org.libretro.RetroArch
  org.localsend.localsend_app
  org.videolan.VLC
)

echo "📦 Instalando Flatpaks..."
for app in "${FLATPAKS[@]}"; do
  if flatpak list --app --columns=application | grep -qx "$app"; then
    echo "✔ $app já instalado"
  else
    sudo flatpak install -y flathub "$app"
  fi
done

#######################################
# 8. FINAL
#######################################
echo "🔄 Atualizando Flatpaks..."
flatpak update -y

echo "✅ Setup finalizado com sucesso!"
echo "⚠ Algumas mudanças exigem logout/login (Docker, grupos)"
