#!/bin/sh

read -p "Please enter your domain: " domain

wspath=$(uuidgen)
v2ray_id=$(uuidgen)
mkdir -p current/caddy
for file_name in Caddyfile v2ray_service.json v2ray_client_template.json;
  do
    sed "s/example.com/$domain/g; s/wspath_placeholder/$wspath/g; s/v2ray_id_placeholder/$v2ray_id/g" "$file_name" > "current/$file_name"
  done

sudo podman pod create --name=tlh -p 80 -p 443
sudo podman create --name=caddy --pod=tlh -v ./current/Caddyfile:/etc/caddy/Caddyfile:Z -v ./www:/var/www:Z -v ./current/caddy:/root/.local/share/caddy:Z caddy/caddy:alpine
sudo podman create --name=v2ray --pod=tlh -v ./current/v2ray_service.json:/etc/v2ray/config.json:Z v2fly/v2fly-core

sudo cp tlh.service /etc/systemd/system/
sudo systemctl enable --now tlh
