#!/bin/sh

sudo systemctl disable --now pod-tlh
sudo rm /etc/systemd/system/{pod-tlh,container-star-link,container-caddy,container-v2ray}.service
sudo podman pod rm tlh

for repo_name in caddy:latest aasterism/star-link:latest v2fly/v2fly-core:latest; do
  sudo podman rmi $(sudo podman images -q "$repo_name")
done
