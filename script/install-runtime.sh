#!/bin/bash

set -e

echo "== Update package =="
sudo apt update

echo "== Install base dependencies =="
sudo apt install -y curl build-essential software-properties-common

# -----------------------
# 🟢 Install Node.js (via NVM)
# -----------------------
echo "== Install NVM =="

export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
fi

# load nvm
source "$NVM_DIR/nvm.sh"

echo "== Install latest LTS Node.js =="
nvm install --lts
nvm use --lts

# set default
nvm alias default 'lts/*'

# -----------------------
# 🐍 Install Python
# -----------------------
echo "== Install Python =="
sudo apt install -y python3 python3-pip python3-venv python3-dev

echo "== Upgrade pip =="
python3 -m pip install --upgrade pip

# -----------------------
# ✅ Verify
# -----------------------
echo "== Versions =="
node -v
npm -v
python3 --version
pip3 --version

echo "== Done! =="
echo "ถ้า node ใช้ไม่ได้ ให้รัน:"
echo "source ~/.bashrc หรือ source ~/.zshrc"
