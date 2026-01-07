#!/usr/bin/env bash
set -e

echo "🚀 Iniciando setup do sistema (workstation)..."

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
IS_FEDORA=false

if [[ "$ID" == "arch" || "$ID_LIKE" == *"arch"* || "$ID" == "cachyos" ]]; then
  IS_ARCH=true
fi

if [[ "$ID" == "fedora" ]]; then
  IS_FEDORA=true
fi

echo "🖥 Sistema detectado: $NAME ($ID)"

#######################################
# 2. PACOTES BASE
#######################################
if $IS_ARCH; then
  sudo pacman -S --needed --noconfirm \
    git curl flatpak zsh tmux bat ufw
elif $IS_FEDORA; then
  sudo dnf install -y \
    git curl flatpak zsh tmux bat firewalld
fi

#######################################
# 3. YAY (ARCH)
#######################################
if $IS_ARCH && ! command -v yay >/dev/null; then
  echo "📦 Instalando yay..."
  sudo pacman -S --needed --noconfirm base-devel
  git clone https://aur.archlinux.org/yay.git /tmp/yay
  (cd /tmp/yay && makepkg -si --noconfirm)
  rm -rf /tmp/yay
fi

#######################################
# 4. PACOTES ARCH (OFICIAIS)
#######################################
if $IS_ARCH; then
  yay -S --needed --noconfirm \
    docker docker-buildx docker-compose \
    fuse2 okular partitionmanager kclock
fi

#######################################
# 5. AUR CONTROLADO (APENAS ESTES)
#######################################
if $IS_ARCH; then
  yay -S --needed --noconfirm \
    google-chrome \
    visual-studio-code-bin \
    jetbrains-toolbox
fi

#######################################
# 6. DOCKER
#######################################
if ! command -v docker >/dev/null; then
  if $IS_FEDORA; then
    echo "🐳 Instalando Docker (Fedora)..."
    sudo dnf config-manager addrepo \
      --from-repofile https://download.docker.com/linux/fedora/docker-ce.repo
    sudo dnf install -y \
      docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin
  fi
fi

sudo systemctl enable --now docker || true
sudo usermod -aG docker "$USER" || true

#######################################
# 7. FIREWALL (APENAS LOCALSEND)
#######################################
if $IS_FEDORA; then
  echo "🔥 Configurando firewalld (LocalSend)..."
  sudo systemctl enable --now firewalld || true
  sudo firewall-cmd --permanent --add-port=53317/tcp
  sudo firewall-cmd --permanent --add-port=53317/udp
  sudo firewall-cmd --reload
else
  echo "🔥 Configurando ufw (LocalSend)..."
  sudo systemctl enable --now ufw || true
  sudo ufw allow from 192.168.0.0/16 to any port 53317
  sudo ufw --force enable
fi

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
  com.getpostman.Postman
  com.github.IsmaelMartinez.teams_for_linux
  com.obsproject.Studio
  com.spotify.Client
  md.obsidian.Obsidian
  org.gimp.GIMP
  org.localsend.localsend_app
  org.videolan.VLC
  org.qbittorrent.qBittorrent
)

if ! $IS_FEDORA && ! command -v libreoffice >/dev/null; then
  FLATPAKS+=(org.libreoffice.LibreOffice)
fi

for app in "${FLATPAKS[@]}"; do
  flatpak install -y flathub "$app" || true
done

#######################################
# 9. STARSHIP
#######################################
if ! command -v starship >/dev/null; then
  curl -sS https://starship.rs/install.sh | sh -s -- -y
fi

#######################################
# 10. MISE
#######################################
if ! command -v mise >/dev/null; then
  curl https://mise.run/zsh | sh
fi

#######################################
# 11. ZSH + OH-MY-ZSH + ZINIT
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
