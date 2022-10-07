#!/bin/bash

set -e
# https://stackoverflow.com/q/32145643
trap "exit" INT

setupConfigurations() {
  mkdir -p current/caddy_data_directory
  rm -rf current/www
  cp -r www current/

  if [ ! -f current/config.prop ]; then
    read -r -p "Please enter your domain: " domain

    star_link_password=$(openssl rand -hex 16)
    v2ray_password=$(uuidgen)

    echo "domain=$domain
star_link_password=$star_link_password
v2ray_password=$v2ray_password" >> current/config.prop
  else
    . current/config.prop
  fi

  # https://superuser.com/a/416630
  star_link_wspath=$(echo "$star_link_password" | xxd -r -p | base64)

  for file_name in Caddyfile server.conf client.conf v2ray_service.json v2ray_client_template.json; do
    # https://unix.stackexchange.com/q/211834
    sed "s/domain_placeholder/$domain/g; \
    s,star_link_wspath_placeholder,$star_link_wspath,g; \
    s/star_link_password_placeholder/$star_link_password/g; \
    s/v2ray_wspath_placeholder/$v2ray_password/g; \
    s/v2ray_id_placeholder/$v2ray_password/g" \
      $file_name >current/$file_name
  done
}

if [ ! -f current/config.prop ]; then
  setupConfigurations
else
  read -r -p "Do you want to regenerate the configuration files? [y/N] " yN
  yN=${yN,,} # to lowercase

  if [[ "$yN" =~ ^(y|yes)$ ]]; then
    setupConfigurations
  fi
fi

cd current || exit 1
sudo podman pod create --name tlh -p 80:80 -p 443:443
sudo podman create --name caddy --pod tlh -v "$PWD"/Caddyfile:/etc/caddy/Caddyfile:Z -v "$PWD"/www:/var/www:Z -v "$PWD"/caddy_data_directory:/data:Z --label io.containers.autoupdate=image docker.io/caddy:latest
sudo podman create --name star-link --pod tlh -v "$PWD"/server.conf:/etc/star-link/server.conf:Z --label io.containers.autoupdate=image docker.io/aasterism/star-link:latest
sudo podman create --name v2ray --pod tlh -v "$PWD"/v2ray_service.json:/etc/v2ray/config.json:Z --label io.containers.autoupdate=image docker.io/v2fly/v2fly-core:latest

sudo podman generate systemd --new --files --restart-policy=on-abnormal --name tlh
sudo podman pod rm tlh
sudo cp {pod-tlh,container-star-link,container-caddy,container-v2ray}.service /etc/systemd/system/
sudo systemctl enable --now pod-tlh
