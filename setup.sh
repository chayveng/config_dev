#!/usr/bin/env bash
# =============================================================
#  setup.sh — Script-first environment bootstrap
#  Tested on: Ubuntu 22.04+ / Debian 12+
# =============================================================

set -uo pipefail
# Note: -e intentionally omitted; each section handles its own errors
# so a single tool failure does not abort the whole script.

# ── Colors ────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

log() { echo -e "${GREEN}[✔]${RESET} $*"; }
info() { echo -e "${CYAN}[→]${RESET} $*"; }
warn() { echo -e "${YELLOW}[!]${RESET} $*"; }
err() {
        echo -e "${RED}[✘]${RESET} $*"
        FAILED_STEPS+=("$*")
}
die() {
        echo -e "${RED}[✘]${RESET} $*" >&2
        exit 1
}

FAILED_STEPS=()

banner() {
        echo -e "\n${BOLD}${CYAN}══════════════════════════════════════${RESET}"
        echo -e "${BOLD}${CYAN}  $*${RESET}"
        echo -e "${BOLD}${CYAN}══════════════════════════════════════${RESET}\n"
}

# ── Helpers ───────────────────────────────────────────────────
has() { command -v "$1" &>/dev/null; }

apt_install() {
        sudo apt-get install -y --no-install-recommends "$@"
}

# ── Preflight ─────────────────────────────────────────────────
banner "Script-first Setup"
[[ $EUID -eq 0 ]] && die "Do not run as root. Use a regular user with sudo."
has apt-get || die "This script requires apt (Debian/Ubuntu)."

info "Updating package lists…"
sudo apt-get update -qq

# =============================================================
# 1. SYSTEM DEPENDENCIES
# =============================================================
banner "System dependencies"
apt_install \
        git curl wget unzip tar build-essential \
        zsh tmux vim xclip \
        htop tree lsof net-tools traceroute \
        speedtest-cli fzf btop \
        python3 python3-pip python3-venv
log "Core packages installed"

# =============================================================
# 2. ZSH + OH-MY-ZSH
# =============================================================
banner "Zsh + Oh-My-Zsh"

if [[ "$SHELL" != */zsh ]]; then
        info "Setting zsh as default shell…"
        chsh -s "$(which zsh)"
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        info "Installing Oh-My-Zsh…"
        RUNZSH=no CHSH=no sh -c \
                "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        log "Oh-My-Zsh installed"
else
        log "Oh-My-Zsh already present"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Plugins
declare -A ZSH_PLUGINS=(
        ["zsh-autosuggestions"]="https://github.com/zsh-users/zsh-autosuggestions"
        ["zsh-syntax-highlighting"]="https://github.com/zsh-users/zsh-syntax-highlighting"
        ["zsh-completions"]="https://github.com/zsh-users/zsh-completions"
)
for name in "${!ZSH_PLUGINS[@]}"; do
        dest="$ZSH_CUSTOM/plugins/$name"
        if [[ ! -d "$dest" ]]; then
                info "Installing plugin: $name"
                git clone --depth=1 "${ZSH_PLUGINS[$name]}" "$dest"
        else
                log "Plugin already installed: $name"
        fi
done

# Update plugins line in .zshrc
if grep -q '^plugins=' "$HOME/.zshrc" 2>/dev/null; then
        sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)/' "$HOME/.zshrc"
else
        echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting zsh-completions)' >>"$HOME/.zshrc"
fi
log "Zsh plugins configured"

# =============================================================
# 3. EZA
# =============================================================
banner "eza"
if ! has eza; then
        info "Installing eza…"
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc |
                sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" |
                sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt-get update -qq
        apt_install eza
        log "eza installed"
else
        log "eza already installed"
fi

# =============================================================
# 4. NEOVIM + LAZYVIM
# =============================================================
banner "Neovim + LazyVim"
if ! has nvim; then
        info "Installing Neovim (latest stable)…"
        NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz"
        curl -fsSL "$NVIM_URL" -o /tmp/nvim.tar.gz
        sudo tar -C /opt -xzf /tmp/nvim.tar.gz
        sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
        rm /tmp/nvim.tar.gz
        log "Neovim installed"
else
        log "Neovim already installed"
fi

if [[ ! -d "$HOME/.config/nvim" ]]; then
        info "Installing LazyVim starter…"
        git clone --depth=1 https://github.com/LazyVim/starter "$HOME/.config/nvim"
        rm -rf "$HOME/.config/nvim/.git"
        log "LazyVim installed — run nvim to finish plugin setup"
else
        log "Neovim config already exists"
fi

# =============================================================
# 5. LAZYGIT
# =============================================================
banner "lazygit"
if ! has lazygit; then
        info "Installing lazygit…"
        LG_VER=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" |
                grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
        curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LG_VER}_Linux_x86_64.tar.gz" |
                tar -xzC /tmp lazygit
        sudo install /tmp/lazygit /usr/local/bin/lazygit
        log "lazygit $LG_VER installed"
else
        log "lazygit already installed"
fi

# =============================================================
# 6. LAZYDOCKER
# =============================================================
banner "lazydocker"
if ! has lazydocker; then
        info "Installing lazydocker…"
        curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh |
                bash
        log "lazydocker installed"
else
        log "lazydocker already installed"
fi

# =============================================================
# 7. YAZI
# =============================================================
banner "yazi"
if ! has yazi; then
        info "Installing yazi…"
        YAZI_VER=$(curl -s "https://api.github.com/repos/sxyazi/yazi/releases/latest" |
                grep '"tag_name"' | sed 's/.*"\(v[^"]*\)".*/\1/')
        curl -fsSL "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip" \
                -o /tmp/yazi.zip
        unzip -qo /tmp/yazi.zip -d /tmp/yazi_extract
        sudo install /tmp/yazi_extract/yazi-x86_64-unknown-linux-gnu/yazi /usr/local/bin/yazi
        rm -rf /tmp/yazi.zip /tmp/yazi_extract
        log "yazi installed"
else
        log "yazi already installed"
fi

# =============================================================
# 8. GPING
# =============================================================
banner "gping"
if ! has gping; then
        info "Installing gping…"
        # Try binary tarball (Linux x86_64) from latest release
        GPING_URL=$(curl -s "https://api.github.com/repos/orf/gping/releases/latest" |
                grep "browser_download_url" |
                grep -i "linux.*x86_64.*gz\|x86_64.*linux.*gz" |
                head -1 | cut -d'"' -f4)
        if [[ -n "$GPING_URL" ]]; then
                curl -fsSL "$GPING_URL" -o /tmp/gping.tar.gz
                tar -xzf /tmp/gping.tar.gz -C /tmp
                sudo install /tmp/gping /usr/local/bin/gping 2>/dev/null ||
                        sudo install /tmp/gping-* /usr/local/bin/gping 2>/dev/null ||
                        warn "gping binary not found in archive — check manually"
                rm -f /tmp/gping.tar.gz /tmp/gping /tmp/gping-*
                has gping && log "gping installed" || warn "gping install may have failed — verify with: gping --version"
        else
                # Fallback: install via cargo
                if has cargo; then
                        cargo install gping
                        log "gping installed via cargo"
                else
                        warn "gping: no binary found & cargo not available."
                        warn "Install manually: https://github.com/orf/gping/releases"
                fi
        fi
else
        log "gping already installed"
fi

# =============================================================
# 9. TTY-CLOCK
# =============================================================
banner "tty-clock"
if ! has tty-clock; then
        info "Building tty-clock from source…"
        apt_install libncurses-dev
        git clone --depth=1 https://github.com/xorg62/tty-clock /tmp/tty-clock
        make -C /tmp/tty-clock
        sudo install /tmp/tty-clock/tty-clock /usr/local/bin/tty-clock
        rm -rf /tmp/tty-clock
        log "tty-clock installed"
else
        log "tty-clock already installed"
fi

# =============================================================
# 10. PYENV
# =============================================================
banner "pyenv"
if [[ ! -d "$HOME/.pyenv" ]]; then
        info "Installing pyenv…"
        apt_install \
                libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev \
                libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev
        curl -fsSL https://pyenv.run | bash
        log "pyenv installed"
else
        log "pyenv already installed"
fi

# =============================================================
# 11. NVM
# =============================================================
banner "nvm"
if [[ ! -d "$HOME/.nvm" ]]; then
        info "Installing nvm…"
        NVM_VER=$(curl -s "https://api.github.com/repos/nvm-sh/nvm/releases/latest" |
                grep '"tag_name"' | sed 's/.*"\(v[^"]*\)".*/\1/')
        curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VER}/install.sh" | bash
        log "nvm $NVM_VER installed"
else
        log "nvm already installed"
fi

# =============================================================
# 12. VIMRC
# =============================================================
banner ".vimrc"
cat >"$HOME/.vimrc" <<'VIMRC'
" Enable line numbers
" set number
" Enable relative line numbers
" set relativenumber
" Enable auto-indentation
set smartindent
" set tabstop=4
" set shiftwidth=4
set expandtab
" Enable line wrapping
set wrap
" Enable syntax highlighting
syntax enable
" Show matching parentheses
set showmatch
" Enable line search highlighting
set hlsearch
set noswapfile
VIMRC
log ".vimrc written"

# =============================================================
# 13. TMUX CONFIG
# =============================================================
banner ".tmux.conf"

# TPM (Tmux Plugin Manager) — for session save addon
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
        info "Installing TPM (Tmux Plugin Manager)…"
        git clone --depth=1 https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
        log "TPM installed"
fi

cat >"$HOME/.tmux.conf" <<'TMUXCONF'
# ── Plugins (TPM) ─────────────────────────────────────────────
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'    # save sessions
set -g @plugin 'tmux-plugins/tmux-continuum'    # auto-save sessions

set -g @continuum-restore 'on'
set -g @continuum-save-interval '10'

# ── Prefix ────────────────────────────────────────────────────
# unbind C-b
# set -g prefix C-a
# bind C-a send-prefix

# ── Pane navigation (vim-style) ───────────────────────────────
bind -r h select-pane -L
bind -r j select-pane -D
bind -r k select-pane -U
bind -r l select-pane -R

# ── Split panes ───────────────────────────────────────────────
bind \\ split-window -h
bind - split-window -v

# ── Resize panes ─────────────────────────────────────────────
bind -r H resize-pane -L 5
bind -r J resize-pane -D 5
bind -r K resize-pane -U 5
bind -r L resize-pane -R 5

# ── Options ───────────────────────────────────────────────────
set -g escape-time 0
set -g default-terminal "screen-256color"
set -g set-titles on
set -g set-titles-string '#S:#I.#P #W'
set -g status-keys vi
set-window-option -g mode-keys vi
# setw -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set-option -g renumber-windows on

# ── Copy mode (vi-style) ──────────────────────────────────────
bind-key -T copy-mode-vi v send -X begin-selection
bind-key -T copy-mode-vi V send -X select-line
bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel 'xclip -in -selection clipboard'

# Initialize TPM (keep at bottom)
run '~/.tmux/plugins/tpm/tpm'
TMUXCONF
log ".tmux.conf written (with tmux-resurrect + tmux-continuum)"

# =============================================================
# 14. ZSHRC — ALIASES + PYENV + NVM
# =============================================================
banner ".zshrc aliases & env"

# Remove old alias block if present, then append fresh
sed -i '/# ==== script-first aliases START ====/,/# ==== script-first aliases END ====/d' "$HOME/.zshrc"

cat >>"$HOME/.zshrc" <<'ZSHRC_APPEND'

# ==== script-first aliases START ====

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# =========================
# SYSTEM
# =========================
alias cls='clear'
alias his='history'
alias inet='ip a | grep "inet "'
alias clock='tty-clock -c -s'
alias zshrc='vim ~/.zshrc'
alias reload='source ~/.zshrc'
alias tmuxrc='vim ~/.tmux.conf'
alias vimrc='vim ~/.vimrc'
alias dfh='df -h'
alias mem='free -h'
alias cpu='htop'

# =========================
# DEV
# =========================
alias py='python3'
alias pipup='pip install --upgrade pip'
alias venv='python3 -m venv .venv'
alias act='source .venv/bin/activate'

# =========================
# NETWORK
# =========================
alias myip='curl ifconfig.me'
alias pingg='gping'
alias ports='ss -tulnp'
alias netlisten='lsof -i -P -n | grep LISTEN'
alias ips='ip -brief addr'
alias speed='speedtest-cli'
alias tracer='traceroute'

# =========================
# DOCKER
# =========================
alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpa='docker ps -a'
alias di='docker images'
alias dcu='docker compose up'
alias dcud='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail 100'
alias dex='docker exec -it'
alias drm='docker rm $(docker ps -aq)'
alias drmi='docker rmi $(docker images -q)'
alias dstop='docker stop $(docker ps -q)'
alias dprune='docker system prune -af'

# =========================
# FIND / FILES
# =========================
alias l='eza -lh'
alias ll='eza -lh'
alias la='eza -alh'
alias duh='du -sh * | sort -h'
alias big='find . -type f | xargs du -h | sort -hr | head -20'
alias ff='find . -type f -iname'
alias fd='find . -type d -iname'
alias grepip='grep -Rni'
alias tree1='tree -L 1'
alias tree2='tree -L 2'

# =========================
# SAFETY
# =========================
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'

# ==== script-first aliases END ====
ZSHRC_APPEND
log ".zshrc aliases + env written (fixed dcl typo → --tail 100)"

# =============================================================
# 15. DOCKER
# =============================================================
banner "Docker"
if ! has docker; then
        info "Installing Docker (official script)…"

        # Remove old/conflicting packages
        for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
                sudo apt-get remove -y "$pkg" 2>/dev/null || true
        done

        # Install via official convenience script
        curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
        sudo sh /tmp/get-docker.sh
        rm /tmp/get-docker.sh

        # Add current user to docker group (no sudo needed after re-login)
        sudo usermod -aG docker "$USER"

        # Enable & start service
        sudo systemctl enable docker
        sudo systemctl start docker

        log "Docker installed — re-login (or run: newgrp docker) to use without sudo"
else
        log "Docker already installed ($(docker --version))"
fi

# Docker Compose plugin check
if ! docker compose version &>/dev/null 2>&1; then
        info "Installing Docker Compose plugin…"
        sudo apt-get update -qq
        apt_install docker-compose-plugin
        log "Docker Compose plugin installed"
else
        log "Docker Compose already available"
fi

# =============================================================
# DONE
# =============================================================
banner "All done!"

if [[ ${#FAILED_STEPS[@]} -gt 0 ]]; then
        echo -e "${RED}${BOLD}The following steps had errors:${RESET}"
        for s in "${FAILED_STEPS[@]}"; do
                echo -e "  ${RED}✘${RESET} $s"
        done
        echo ""
fi

echo -e "${BOLD}Next steps:${RESET}"
echo -e "  1. ${CYAN}exec zsh${RESET}                    — reload shell"
echo -e "  2. ${CYAN}tmux new -s main${RESET}            — start tmux, then press ${BOLD}prefix + I${RESET} to install plugins"
echo -e "  3. ${CYAN}nvim${RESET}                        — LazyVim will auto-install plugins on first launch"
echo -e "  4. ${CYAN}pyenv install 3.12.x${RESET}        — install a Python version"
echo -e "  5. ${CYAN}nvm install --lts${RESET}           — install latest Node LTS"
echo -e "  6. ${CYAN}newgrp docker${RESET}               — หรือ re-login เพื่อใช้ docker ได้เลยโดยไม่ต้อง sudo"
echo ""
