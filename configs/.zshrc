export ZSH="$HOME/.oh-my-zsh"
plugins=(git)
source $ZSH/oh-my-zsh.sh

# Detect OS
case "$(uname -s)" in
  Darwin)
    alias update="brew update && brew upgrade && brew autoremove && brew cleanup"
    ;;
  Linux)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      # WSL
      alias update="sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y"
    else
      # Arch / CachyOS
      alias update="paru -Syu && paru -Rns $(pacman -Qdtq 2>/dev/null)"
    fi
    ;;
esac

#Programing
alias cat="bat --theme=\$(defaults read -globalDomain AppleInterfaceStyle &> /dev/null && echo default || echo GitHub)"
alias ls="eza --color=always --long --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias cd="z"

### Added by Zinit's installer
if [[ ! -f $HOME/.local/share/zinit/zinit.git/zinit.zsh ]]; then
    print -P "%F{33} %F{220}Installing %F{33}ZDHARMA-CONTINUUM%F{220} Initiative Plugin Manager (%F{33}zdharma-continuum/zinit%F{220})…%f"
    command mkdir -p "$HOME/.local/share/zinit" && command chmod g-rwX "$HOME/.local/share/zinit"
    command git clone https://github.com/zdharma-continuum/zinit "$HOME/.local/share/zinit/zinit.git" && \
        print -P "%F{33} %F{34}Installation successful.%f%b" || \
        print -P "%F{160} The clone has failed.%f%b"
fi

source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl \
    zdharma-continuum/zinit-annex-rust \
    zdharma-continuum/fast-syntax-highlighting \
    zdharma-continuum/history-search-multi-word \
    zsh-users/zsh-autosuggestions \
    zsh-users/zsh-completions

### End of Zinit's installer chunk

eval "$(starship init zsh)"
eval "$(mise activate zsh)"
eval "$(zoxide init zsh)"
source <(fzf --zsh)

export FZF_CTRL_T_OPTS="
 --style full
 --walker-skip .git,node_modules,target
 --preview 'bat -n --color=always {}'
 --bind 'ctrl-/:change-preview-window(down|hidden|)'
"

# --- mise Java ---
export JAVA_HOME="$(dirname "$(dirname "$(mise which java)")")"
export PATH="$JAVA_HOME/bin:$PATH"
