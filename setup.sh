#!/usr/bin/env bash
set -e

echo "🚀 Iniciando setup do sistema (Arch-based workstation)..."

#######################################
# 1. DETECÇÃO DO SISTEMA
#######################################
if [ -f /etc/os-release ]; then
  . /etc/os-release
else
  echo "❌ Não foi possível detectar o sistema"
  exit 1
fi

if [[ "$ID" != "arch" && "$ID_LIKE" != *"arch"* && "$ID" != "cachyos" ]]; then
  echo "❌ Este script é exclusivo para Arch Linux e derivados"
  exit 1
fi

echo "🖥 Sistema detectado: $NAME ($ID)"

#######################################
# 2. PACOTES BASE (ARCH)
#######################################
sudo pacman -S --needed --noconfirm \
  git curl flatpak zsh tmux bat ufw base-devel

#######################################
# 3. PARU (AUR HELPER)
#######################################
if ! command -v paru >/dev/null; then
  echo "📦 Paru não encontrado. Instalando..."

  TMP_DIR="/tmp/paru"
  rm -rf "$TMP_DIR"
  git clone https://aur.archlinux.org/paru.git "$TMP_DIR"

  (
    cd "$TMP_DIR"
    makepkg -si --noconfirm
  )
else
  echo "✅ Paru já instalado"
fi

#######################################
# 4. PACOTES ARCH (OFICIAIS)
#######################################
paru -S --needed --noconfirm \
  docker docker-buildx docker-compose \
  fuse2 okular partitionmanager kclock libreoffice-fresh

#######################################
# 5. AUR CONTROLADO
#######################################
paru -S --needed --noconfirm \
  google-chrome \
  visual-studio-code-bin \
  jetbrains-toolbox \
  linuxtoys-bin

#######################################
# 6. DOCKER
#######################################
sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"

#######################################
# 7. FIREWALL (LocalSend)
#######################################
sudo systemctl enable --now ufw
sudo ufw allow 53317/tcp
sudo ufw allow 53317/udp
sudo ufw --force enable

#######################################
# 8. FLATPAK + FLATHUB
#######################################
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
  com.rtosta.zapzap
  com.spotify.Client
  io.ente.auth
  md.obsidian.Obsidian
  me.iepure.devtoolbox
  org.gimp.GIMP
  org.libretro.RetroArch
  org.localsend.localsend_app
  org.gtk.Gtk3theme.Breeze-Dark
)

for app in "${FLATPAKS[@]}"; do
  flatpak install -y flathub "$app" || true
done

#######################################
# 9. FLATPAK OVERRIDES (THEME FIXES)
#######################################
echo "🎨 Aplicando overrides de tema Flatpak..."

flatpak override --user \
  --env=GTK_THEME=Breeze-Dark \
  org.localsend.localsend_app

#######################################
# 10. STARSHIP
#######################################
if ! command -v starship >/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

#######################################
# 11. MISE
#######################################
if ! command -v mise >/dev/null; then
  curl https://mise.run/zsh | sh
fi

#######################################
# 12. ZSH + OH-MY-ZSH + ZINIT
#######################################
if [ "$SHELL" != "$(which zsh)" ]; then
  chsh -s "$(which zsh)"
fi

ZSHRC="$HOME/.zshrc"

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

if ! grep -q zinit "$ZSHRC"; then
  git clone https://github.com/zdharma-continuum/zinit \
    ~/.local/share/zinit/zinit.git

  cat <<'EOF' >>"$ZSHRC"

# ---- ZINIT ----
source ~/.local/share/zinit/zinit.git/zinit.zsh
zinit light zsh-users/zsh-autosuggestions
zinit light zsh-users/zsh-completions

# ---- MISE ----
eval "$(mise activate zsh)"

# ---- STARSHIP ----
eval "$(starship init zsh)"
EOF
fi

#######################################
# FINAL
#######################################
flatpak update -y

echo "✅ Setup finalizado com sucesso!"
echo "⚠ Faça logout/login para aplicar ZSH e grupo Docker"
