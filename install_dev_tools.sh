#!/bin/bash
set -e

echo "[INFO] Starting development tools installation"

install_docker() {
  echo "[INFO] Checking Docker installation status"
  if ! command -v docker &> /dev/null; then
    echo "[INFO] Installing Docker"
    sudo apt update -y
    sudo apt install -y ca-certificates curl gnupg lsb-release
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo systemctl enable docker
    sudo systemctl start docker
    echo "[SUCCESS] Docker installed successfully"
  else
    echo "[SUCCESS] Docker is already installed"
  fi
}

install_docker_compose() {
  echo "[INFO] Checking Docker Compose installation status"
  if ! command -v docker-compose &> /dev/null; then
    echo "[INFO] Installing Docker Compose"
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    echo "[SUCCESS] Docker Compose installed successfully"
  else
    echo "[SUCCESS] Docker Compose is already installed"
  fi
}

install_python() {
  echo "[INFO] Checking Python installation status"
  if ! command -v python3 &> /dev/null; then
    echo "[INFO] Installing Python 3"
    sudo apt update -y
    sudo apt install -y python3 python3-pip python3-venv
    echo "[SUCCESS] Python installed successfully"
  else
    PY_VER=$(python3 -V | awk '{print $2}')
    echo "[SUCCESS] Python is already installed (version $PY_VER)"
  fi
}

install_django() {
  echo "[INFO] Checking Django installation status"
  if ! pip3 show django &> /dev/null; then
    echo "[INFO] Installing Django"
    pip3 install --upgrade pip
    pip3 install django
    echo "[SUCCESS] Django installed successfully"
  else
    DJ_VER=$(pip3 show django | grep Version | awk '{print $2}')
    echo "[SUCCESS] Django is already installed (version $DJ_VER)"
  fi
}

install_docker
install_docker_compose
install_python
install_django

echo "[SUCCESS] All tools have been successfully installed"