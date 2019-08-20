#!/usr/bin/env bash

# Install Docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io

# Start Docker service
systemctl start docker
systemctl enable docker

# Install Docker-Compose
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose

pushd jupyterhub

# Generate crypto stuffs
export JUPYTERHUB_CRYPT_KEY=$(openssl rand -hex 32)
openssl req -newkey rsa:4096 -nodes -x509 -days 90 \
  -subj "/C=US/ST=Illinois/L=Chicago/O=Chameleon/CN=JupyterHub Appliance" \
  -config <(printf "\n[SAN]\nsubjectAltName=IP:$FLOATING_IP") \
  -out nginx/default.crt \
  -keyout nginx/default.key

docker-compose up -d
