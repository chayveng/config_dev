#!/bin/bash

set -e

echo "== Update package =="
sudo apt update

echo "== Install dependencies =="
sudo apt install -y ca-certificates curl gnupg lsb-release

echo "== Add Docker GPG key =="
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "== Add Docker repo =="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "== Install Docker =="
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "== Start & Enable Docker =="
sudo systemctl enable docker
sudo systemctl start docker

echo "== Create docker group (if not exists) =="
sudo groupadd docker || true

echo "== Add current user to docker group =="
sudo usermod -aG docker $USER

echo "== Done! =="
echo "IMPORTANT: กรุณา logout/login ใหม่ หรือรันคำสั่งนี้:"
echo "newgrp docker"
