#!/bin/bash

setupConfigurations() {
  read -r -p "Please enter your domain: " domain
  read -r -p "Please enter your email for ACME (press Enter to skip): " email

  star_link_password=$(openssl rand -hex 16)
  # https://superuser.com/a/416630
  star_link_wspath=$(echo "$star_link_password" | xxd -r -p | base64)

  v2ray_wspath=$(uuidgen)
  v2ray_id=$(uuidgen)
  mkdir -p current/caddy_data_directory
  for file_name in Caddyfile server.conf client.conf v2ray_service.json v2ray_client_template.json; do
    # https://unix.stackexchange.com/q/211834
    sed "s/domain_placeholder/$domain/g; \
    s,star_link_wspath_placeholder,$star_link_wspath,g; \
    s/star_link_pas--label io.containers.autoupdate=imagesword_placeholder/$star_link_password/g; \
    s/v2ray_wspath_placeholder/$v2ray_wspath/g; \
    s/v2ray_id_placeholder/$v2ray_id/g" \
      $file_name >current/$file_name
  done

  if [ -n "${email}" ]; then
    sed -i "1s/^/{\n    email $email\n}\n\n/" current/Caddyfile
  fi
}

if [ ! -d current ]; then
  setupConfigurations
else
  read -r -p "Do you want to reset the old configuration files? [y/N] " yN
  yN=${yN,,} # to lowercase

  if [[ "$yN" =~ ^(y|yes)$ ]]; then
    setupConfigurations
  fi
fi

cp -r www current/
cd current || exit 1
sudo podman pod create --name tlh -p 80 -p 443
sudo podman create --name caddy --pod tlh -v "$PWD"/Caddyfile:/etc/caddy/Caddyfile:Z -v "$PWD"/www:/var/www:Z -v "$PWD"/caddy_data_directory:/root/.local/share/caddy:Z --label io.containers.autoupdate=image caddy:latest
sudo podman create --name star-link --pod tlh -v "$PWD"/server.conf:/etc/star-link/server.conf:Z --label io.containers.autoupdate=image aasterism/star-link:latest
sudo podman create --name v2ray --pod tlh -v "$PWD"/v2ray_service.json:/etc/v2ray/config.json:Z --label io.containers.autoupdate=image v2fly/v2fly-core:latest

sudo podman generate systemd --new --files --name tlh
sudo podman pod rm tlh
sudo cp {pod-tlh,container-star-link,container-caddy,container-v2ray}.service /etc/systemd/system/
sudo systemctl enable --now pod-tlh
