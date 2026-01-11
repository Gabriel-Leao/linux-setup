# 🛠 Arch Workstation Setup Script

Script de **setup automatizado** para configurar uma **workstation baseada em Arch Linux** (Arch puro ou CachyOS).

O objetivo é automatizar a instalação de ferramentas essenciais usando **Pacman, AUR (paru) e Flatpak**, além de configurar **Docker, ZSH, firewall (UFW)** e resolver problemas comuns de **tema escuro em apps Flatpak GTK no KDE**.

---

## ✅ Sistemas suportados

- Arch Linux
- CachyOS

❌ **Não suporta outras distribuições**

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

#### Pacotes oficiais (Arch)

- docker
- docker-buildx
- docker-compose
- okular
- partitionmanager
- kclock
- libreoffice-fresh
- fuse2

#### Pacotes AUR

- google-chrome
- visual-studio-code-bin
- jetbrains-toolbox
- linuxtoys-bin

---

### 🐳 Docker

- Ativa e inicia o serviço Docker
- Adiciona o usuário atual ao grupo `docker`

⚠️ É necessário **logout/login** após a execução para usar Docker sem `sudo`.

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

## 🐚 ZSH, Mise e Produtividade

O script configura um ambiente de shell moderno e produtivo.

### O que é instalado

- ZSH como shell padrão
- Oh My Zsh
- Zinit (gerenciador de plugins)
- Starship (prompt)
- **Mise** (gerenciador de runtimes)

---

### 🔍 Como o Mise funciona no script

O **Mise** é usado para gerenciar runtimes como **Java** e **Node.js**.

Durante a execução do script:

- O Mise é **instalado automaticamente**, se ainda não existir
- Ele é **ativado explicitamente dentro do script**, usando:

```bash
eval "$(mise activate bash)"
```

- Isso garante que comandos como `mise use -g` funcionem **durante a execução do script**
- O script **não depende do `.zshrc`** para que o Mise funcione no setup

Após a execução:

- O script adiciona ao `~/.zshrc`:

```bash
eval "$(mise activate zsh)"
```

- Isso garante que o Mise esteja ativo em **todas as sessões futuras do ZSH**

📌 **Resumo importante**
O Mise:

- é ativado no **script** para funcionar durante o setup
- é ativado no **ZSH** para funcionar no uso diário

---

### ☕ Node.js e Java via flags

O script aceita flags para instalar versões específicas de runtimes.

Exemplos:

```bash
./setup.sh --java 21
```

Instala e define globalmente:

```bash
mise use -g java@21
```

```bash
./setup.sh --node 24
```

Instala e define globalmente:

```bash
mise use -g node@24
```

Também é possível usar ambos:

```bash
./setup.sh --java 21 --node 24
```

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

Setup completo:

```bash
./setup.sh --all
```

Setup completo com runtimes:

```bash
./setup.sh --all --java 21 --node 24
```

Apenas shell + runtimes:

```bash
./setup.sh --shell --java 21 --node 24
```

Ver ajuda:

```bash
./setup.sh --help
```

---

## ⚠️ Observações importantes

- O script utiliza `sudo` e solicitará sua senha
- Pode ser executado **mais de uma vez** (idempotente)
- Após a execução, faça **logout/login** para aplicar:

  - ZSH como shell padrão
  - Permissões do Docker

---

## 📂 Estrutura do projeto

```text
.
├── setup.sh
├── README.md
└── LICENSE
```

---

## 📄 Licença

Este projeto está licenciado sob a **MIT License**.
Consulte o arquivo `LICENSE` para mais detalhes.
