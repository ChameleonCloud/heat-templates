#!/usr/bin/env bash

# Install Docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install -y docker-ce docker-ce-cli containerd.io

# Start Docker service
systemctl enable docker
systemctl start docker

# Install Docker-Compose
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" \
  -o /usr/local/bin/docker-compose \
  && chmod +x /usr/local/bin/docker-compose

cat >/etc/profile.d/user_data.sh <<EOF
export NGINX_IMAGE=nginx:mainline
export JUPYTERHUB_IMAGE=docker.chameleoncloud.org/jupyterhub:latest
export NOTEBOOK_IMAGE=docker.chameleoncloud.org/jupyterhub-user:latest
export JUPYTERHUB_CRYPT_KEY=$(openssl rand -hex 32)
EOF
source /etc/profile.d/user_data.sh

token=$(curl 169.254.169.254/openstack/latest/vendor_data2.json \
  | jq -r .chameleon.instance_metrics_writer_token)
docker login -u token -p "$token" docker.chameleoncloud.org
for image in $NGINX_IMAGE $JUPYTERHUB_IMAGE $NOTEBOOK_IMAGE; do
  docker pull $image
done

# Generate crypto stuffs
openssl_conf="${OPENSSL_CONF:-NOTFOUND}"
for path in /etc/ssl/openssl.cnf /etc/pki/tls/openssl.conf; do
  if [[ -f "$path" ]]; then openssl_conf="$path"; break; fi
done
openssl req -newkey rsa:4096 -nodes -x509 -days 90 \
  -subj "/C=US/ST=Illinois/L=Chicago/O=Chameleon/CN=JupyterHub Appliance" \
  -config <(cat "$openssl_conf" <(printf "\n[SAN]\nsubjectAltName=IP:$FLOATING_IP")) \
  -out jupyterhub/nginx/default.crt \
  -keyout jupyterhub/nginx/default.key

(cd jupyterhub && docker-compose up -d)
