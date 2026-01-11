# Linux Setup — Arch Linux & CachyOS

Este repositório contém meu ambiente Linux totalmente reproduzível, baseado em dois scripts:

- setup.sh → provisionamento do sistema
- scripts/sync-dotfiles.sh → aplicação segura dos dotfiles

Compatível somente com:

- Arch Linux
- CachyOS

Qualquer outro sistema é bloqueado automaticamente.

---

## Objetivo

Ter um ambiente:

- Reprodutível
- Modular
- Seguro
- Declarativo
- Com dry-run global
- Com dotfiles versionados

Formatou o sistema → rodou os scripts → ambiente restaurado.

---

## Estrutura do projeto

```
linux-setup/
├── configs/
│ ├── .gitconfig
│ ├── .zshrc
│ ├── .tmux.conf
│ ├── alacritty.toml
│ ├── MangoHud.conf
│ └── starship.toml
│
├── scripts/
│ └── sync-dotfiles.sh
│
├── setup.sh
└── .env.example
```

---

# setup.sh

Script principal de provisionamento do sistema.

## Funções principais

- Detecta Arch ou CachyOS
- Detecta KDE Plasma
- Instala pacotes base
- Instala Paru
- Instala pacotes Arch e KDE
- Instala pacotes AUR
- Instala Flatpaks
- Configura Docker e UFW
- Instala stack de games
- Instala Starship
- Instala Mise
- Configura Java e Node
- Aplica dotfiles
- Configura ZSH
- Suporte completo a dry-run

---

## Uso

./setup.sh [flags]

---

## Flags

--arch Instala pacotes Arch  
--aur Instala pacotes AUR  
--flatpak Instala Flatpaks  
--docker Configura Docker e firewall  
--games Instala pacotes de games  
--sync-dotfiles Aplica dotfiles

--java <versão> Configura Java via Mise  
--node <versão> Configura Node via Mise

--dry-run Simula tudo (nada é executado)  
-h, --help Mostra ajuda

Caso não seja passada nenhuma flag, o script roda tudo

---

## Exemplos

Configuração completa:

./setup.sh

Simulação:

./setup.sh --arch --aur --dry-run

---

## Execução crítica

Sempre executado:

- install_base_packages
- install_paru

Se falhar → script aborta.

---

## Pacotes Arch

Base:

- docker
- docker-buildx
- docker-compose
- fuse2
- libreoffice-fresh
- obs-studio
- qbittorrent

KDE:

- okular
- partitionmanager
- kclock
- discover

---

## Pacotes AUR

- google-chrome
- visual-studio-code-bin
- jetbrains-toolbox
- linuxtoys-bin

---

## Flatpaks

- Zen Browser
- Bitwarden
- Discord
- Postman
- Teams for Linux
- ZapZap
- Spotify
- Ente Auth
- Obsidian
- Devtoolbox
- GIMP
- RetroArch
- Localsend

---

## Games

Base:

- hydra-launcher-bin
- gamemode

Arch:

- heroic-games-launcher-bin
- mangohud
- goverlay
- steam

CachyOS:

- cachyos-gaming-meta

---

## Docker

- Ativa serviço
- Adiciona usuário ao grupo docker
- Configura UFW

Logout/login é necessário após execução.

---

## Shell

- ZSH como padrão
- Oh My Zsh
- Zinit

O .zshrc é controlado somente pelos dotfiles.

---

## Mise

Gerencia runtimes:

- Java
- Node

Exemplo:

./setup.sh --java 21 --node 20

---

# sync-dotfiles.sh

Script de aplicação segura dos dotfiles.

---

## O que faz

- Cria backup automático .bak
- Só substitui arquivos se houver mudança
- Suporte a dry-run
- Interpola .gitconfig via .env
- Não sobrescreve sem backup

---

## Uso

scripts/sync-dotfiles.sh  
scripts/sync-dotfiles.sh --dry-run

---

## Arquivos aplicados

~/.gitconfig  
~/.zshrc  
~/.tmux.conf  
~/.config/alacritty/alacritty.toml  
~/.config/MangoHud/MangoHud.conf  
~/.config/starship.toml

---

## .env

Arquivo opcional:

GIT_NAME="Seu Nome"

GIT_EMAIL="Seu_email"

---

## Fluxo após formatar

git clone <repo> linux-setup
cd linux-setup
chmod +x setup.sh scripts/sync-dotfiles.sh
./setup.sh --arch --aur --flatpak --docker --games --sync-dotfiles

---

## Avisos

- Não execute como root
- Logout/login pode ser necessário
- Dry-run não executa nada
- Alguns Flatpaks podem falhar em dry-run

---

## Autor

Gabriel Leão  
Ambiente Linux pessoal totalmente automatizado
