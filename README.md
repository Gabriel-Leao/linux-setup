# 🛠 Arch Workstation Setup Script

Script de **setup automatizado** para configurar uma **workstation baseada em Arch Linux** (Arch puro ou CachyOS).

O objetivo é automatizar a instalação de ferramentas essenciais usando **Pacman, AUR (paru) e Flatpak**, além de configurar **Docker, ZSH, firewall (UFW)** e corrigir problemas de **tema escuro em apps Flatpak GTK no KDE**.

---

## ✅ Sistemas suportados

- Arch Linux
- CachyOS

❌ **Não suporta Fedora ou outras distribuições**

---

## 📦 O que este script instala e configura

### 🔧 Pacotes base (Pacman)

- git
- curl
- flatpak
- zsh
- tmux
- bat
- ufw
- base-devel

---

### 🧩 AUR (via paru)

O script verifica se o **paru** já está instalado (CachyOS já vem com ele).
Caso não esteja, ele é instalado automaticamente a partir do AUR.

#### Pacotes oficiais (Arch):

- docker
- docker-buildx
- docker-compose
- okular
- partitionmanager
- kclock
- libreoffice-fresh
- fuse2

#### Pacotes AUR:

- google-chrome
- visual-studio-code-bin
- jetbrains-toolbox
- linuxtoys-bin

---

### 🐳 Docker

- Ativa e inicia o serviço Docker
- Adiciona o usuário atual ao grupo `docker`

> ⚠️ É necessário **logout/login** após a execução para usar Docker sem `sudo`.

---

### 🔥 Firewall (UFW)

- Ativa o `ufw`
- Libera a porta **53317 TCP/UDP**, utilizada pelo **LocalSend**

---

### 📦 Flatpak + Flathub

- Adiciona o repositório **Flathub**
- Instala os seguintes aplicativos Flatpak:

  - Zen Browser
  - Bitwarden
  - Discord
  - Postman
  - Teams for Linux
  - ZapZap
  - Spotify
  - Ente Auth
  - Obsidian
  - Dev Toolbox
  - GIMP
  - RetroArch
  - LocalSend
  - GTK Breeze Dark Theme

---

### 🎨 Correção de tema (KDE + Flatpak)

Alguns aplicativos GTK Flatpak (como o **LocalSend**) não respeitam o tema escuro no KDE.

O script aplica o seguinte override:

```bash
flatpak override --user --env=GTK_THEME=Breeze-Dark org.localsend.localsend_app
```

Isso força o **Breeze Dark apenas para o LocalSend**, sem afetar outros aplicativos Flatpak.

---

### 🐚 ZSH + Produtividade

- Define o **ZSH como shell padrão**
- Instala e configura:

  - Oh My Zsh
  - Zinit
  - Starship (prompt)
  - Mise (gerenciador de runtimes)

As configurações são adicionadas automaticamente ao `~/.zshrc`.

---

## ▶️ Como usar

### 1️⃣ Clone o repositório

```bash
git clone https://github.com/seu-usuario/seu-repo.git
cd seu-repo
```

---

### 2️⃣ Dê permissão de execução ao script

```bash
chmod +x setup.sh
```

---

### 3️⃣ Execute o script

```bash
./setup.sh
```

Ou, se preferir:

```bash
bash setup.sh
```

---

## ⚠️ Observações importantes

- O script utiliza `sudo` e solicitará sua senha
- Pode ser executado mais de uma vez
- Após a execução, faça **logout/login** para aplicar:

  - ZSH como shell padrão
  - Permissões do Docker

---

## 📂 Estrutura do projeto

```
.
├── setup.sh
├── README.md
└── LICENSE
```

---

## 📄 Licença

Este projeto está licenciado sob a **MIT License**.
Consulte o arquivo [`LICENSE`](./LICENSE) para mais detalhes.
