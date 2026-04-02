#!/bin/bash

set -e

echo "== Add aliases to ~/.zshrc =="

cat << 'EOF' >> ~/.zshrc

## General
alias l="ls -lh"
alias ll="ls -lh"
alias la="ls -alh"
alias reload="source ~/.zshrc"
alias zshrc="vim ~/.zshrc"
alias vimrc="vim ~/.vimrc"
alias tmuxrc="vim ~/.tmux.conf"
alias cls="clear"
alias inet="ip a | grep 'inet '"
alias clock="tty-clock -s -c -C 2"

## Docker
alias dps='docker ps --format "table {{.Status}}\t{{.Names}}\t{{.Ports}}"'
alias dpsa="docker ps -a"
alias di="docker images"
alias drmi="docker rmi "
alias dlogs="docker logs -f"
alias dload="docker load < "
alias dcu="docker compose up"
alias dcud="docker compose up -d"
alias dcubd="docker compose up --build -d"
alias dcb="docker compose --build"
alias dcbd="docker compose --build"
alias dcub="docker compose up --build"
alias dclogs="docker compose logs -f --tail 404 "

EOF

echo "== Please reload zsh =="
echo "== Done! =="
