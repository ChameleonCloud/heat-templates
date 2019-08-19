#!/usr/bin/env bash

# Install Docker
yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
yum install docker-ce docker-ce-cli containerd.io

(cd jupyterhub && docker-compose up -d)
