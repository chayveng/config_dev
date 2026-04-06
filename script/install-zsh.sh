#!/bin/bash

set -e

echo "== Update package =="
sudo apt update

echo "== Install Zsh + Git + Curl =="
sudo apt install -y zsh git curl

echo "== Set Zsh as default shell =="
chsh -s $(which zsh)

echo "== Install Oh My Zsh =="
RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

echo "== Install plugins =="
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

# autosuggestions
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions

# syntax highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${jZSH_CUSTOM}/plugins/zsh-syntax-highlighting

sed -i 's/^ZSH_THEME=.*/ZSH_THEME=""\nPROMPT="%n@%m [%*] %~ %# "/'

# PROMPT="%n@%m[%*]:%~ %$"
# PROMPT="%F{82}%n@%m%f[%F{220}%*%f]:%F{39}%~%f %# "
# PROMPT="%F{cyan}%n@%m%f %F{magenta}[%*]%f %F{blue}%~%f %# "
# PROMPT="%F{green}%n@%m%f:%F{cyan}%~%f %F{red}%#%f "

sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

echo "== Done! =="
echo "Please reconnect"
echo "exec zsh"
