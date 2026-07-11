# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"

export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$HOME/go/bin:/usr/lib/go/bin:/usr/local/bin:/usr/bin:$PATH"
export GOPATH=$HOME/go
export GOROOT=/usr/lib/go  # Ajusta según tu instalación


ZSH_THEME="arrow"

plugins=(
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

#pokemon-colorscripts --no-title -s -r #without fastfetch
pokemon-colorscripts --no-title -s -r | fastfetch -c $HOME/.config/fastfetch/config-pokemon.jsonc --logo-type file-raw --logo-height 10 --logo-width 5 --logo -

# fastfetch. Will be disabled if above colorscript was chosen to install
#fastfetch -c $HOME/.config/fastfetch/config-compact.jsonc

# Set-up icons for files/directories in terminal using lsd
alias ls='lsd'
alias l='ls -l'
alias la='ls -a'
alias lla='ls -la'
alias lt='ls --tree'
alias dev='tmuxinator DEV'

# Set-up FZF key bindings (CTRL R for fuzzy history finder)
source <(fzf --zsh)

HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

eval "$(zoxide init zsh)"

limpiarArch() {
  echo "== Uso de disco =="
  df -h /

  echo "== Limpiando cache pacman (paccache) =="
  sudo paccache -r

  echo "== Limpiando todo cache pacman =="
  sudo pacman -Scc --noconfirm
  sudo rm -rf /var/cache/pacman/pkg/download-*

  echo "== Limpiando cache yay =="
  yay -Sc --noconfirm 2>/dev/null || true
  rm -rf ~/.cache/yay

  echo "== Borrando /tmp =="
  sudo rm -rf /tmp/*

  echo "== Eliminando huérfanos pacman =="
  orphans=$(sudo pacman -Qtdq 2>/dev/null)
  if [[ -n "$orphans" ]]; then
    echo "$orphans" | sudo pacman -Rns - --noconfirm
  else
    echo "(ninguno)"
  fi

  echo "== Limpiando journalctl =="
  sudo journalctl --vacuum-time=7d

  echo "== Borrando ccache =="
  rm -rf ~/.ccache

  echo "== Limpiando Rust / cargo =="
  if command -v cargo-cache >/dev/null 2>&1; then
    cargo cache -a 2>/dev/null || true
  else
    rm -rf ~/.cargo/registry/cache ~/.cargo/git/db-checkouts 2>/dev/null || true
  fi
  rm -rf ~/.rustup/tmp 2>/dev/null || true

  echo "== Limpiando Go =="
  if command -v go >/dev/null 2>&1; then
    go clean -cache -modcache -testcache 2>/dev/null || true
  fi

  echo "== Limpiando npm =="
  if command -v npm >/dev/null 2>&1; then
    npm cache clean --force 2>/dev/null || true
  fi

  echo "== Limpiando pnpm =="
  if command -v pnpm >/dev/null 2>&1; then
    pnpm store prune 2>/dev/null || true
  fi

  echo "== Limpiando yarn =="
  if command -v yarn >/dev/null 2>&1; then
    yarn cache clean 2>/dev/null || true
  fi

  echo "== Limpiando bun =="
  if command -v bun >/dev/null 2>&1; then
    bun pm cache rm 2>/dev/null || true
  fi

  echo "== Limpiando pip =="
  if command -v pip >/dev/null 2>&1; then
    pip cache purge 2>/dev/null || true
  fi
  if command -v pipx >/dev/null 2>&1; then
    pipx runpip --global pip cache purge 2>/dev/null || true
  fi

  echo "== Limpiando Homebrew / Linuxbrew =="
  if command -v brew >/dev/null 2>&1; then
    brew cleanup -s --prune=all 2>/dev/null || true
  fi

  echo "== Limpiando cachés en ~/.cache (gestores comunes) =="
  rm -rf \
    ~/.cache/go-build \
    ~/.cache/npm \
    ~/.cache/yarn \
    ~/.cache/pnpm \
    ~/.cache/pip \
    ~/.cache/meson \
    ~/.cache/ccache 2>/dev/null || true

  echo "== Limpieza terminada =="
  df -h /
}
# opencode
export PATH=/home/samael/.opencode/bin:$PATH


# Load Angular CLI autocompletion.
source <(ng completion script)

# bun completions
[ -s "/home/samael/.bun/_bun" ] && source "/home/samael/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="/home/samael/.local/bin:$PATH"
eval "$(/home/samael/.linuxbrew/bin/brew shellenv)"

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<

# gentle-agent-state: renombrar tabs de Zellij con estado del agente (working/blocked/idle)
export AGENT_ZELLIJ_RENAME_TAB=1
export EDITOR=vim
export VISUAL=vim 

# pnpm
export PNPM_HOME="/home/samael/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME/bin:"*) ;;
  *) export PATH="$PNPM_HOME/bin:$PATH" ;;
esac
# pnpm end
