#!/bin/sh

sudo systemctl disable --now pod-tlh
sudo rm /etc/systemd/system/{pod-tlh,container-star-link,container-caddy,container-v2ray}.service
sudo podman pod rm tlh
