#!/bin/sh

if [ ! -d current ]; then
  read -p "Please enter your domain: " domain

  star_link_password=$(openssl rand -hex 16)
  # https://superuser.com/a/416630
  star_link_wspath=$(echo "$star_link_password" | xxd -r -p | base64)

  v2ray_wspath=$(uuidgen)
  v2ray_id=$(uuidgen)
  mkdir -p current/caddy_data_directory
  for file_name in Caddyfile server.conf client.conf v2ray_service.json v2ray_client_template.json; do
    sed "s/domain_placeholder/$domain/g; \
    s/star_link_wspath_placeholder/$star_link_wspath/g; \
    s/star_link_password_placeholder/$star_link_password/g; \
    s/v2ray_wspath_placeholder/$v2ray_wspath/g; \
    s/v2ray_id_placeholder/$v2ray_id/g" \
      "$file_name" >"current/$file_name"
  done

else
  echo "\`current\` directory exists. Skip to create relevant configuration files."
fi

cp -r www current/
cd current
sudo podman pod create --name=tlh -p 80 -p 443
sudo podman create --name=caddy --pod=tlh -v ./Caddyfile:/etc/caddy/Caddyfile:Z -v ./www:/var/www:Z -v ./caddy_data_directory:/root/.local/share/caddy:Z caddy:latest
sudo podman create --name=star-link --pod=tlh -v ./server.conf:/etc/star-link/server.conf:Z aasterism/star-link:latest
sudo podman create --name=v2ray --pod=tlh -v ./v2ray_service.json:/etc/v2ray/config.json:Z v2fly/v2fly-core:latest

sudo podman generate systemd --files --name tlh
sudo cp {pod-tlh,container-star-link,container-caddy,container-v2ray}.service /etc/systemd/system/
sudo systemctl enable --now pod-tlh
