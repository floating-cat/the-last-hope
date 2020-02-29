#!/bin/sh

sudo systemctl disable --now tlh
sudo rm /etc/systemd/system/tlh.service
sudo podman pod rm tlh
