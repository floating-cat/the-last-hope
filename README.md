# The Last Hope

The title is a lie.

## Getting Started

### Prerequisites

* Set your domain's A/AAAA records point to your Linux server and open ports 80 & 443 on this server. We need these for automatic HTTPS provisions. Please refer to here for details: https://caddyserver.com/docs/automatic-https.

  If you are using [firewalld](https://firewalld.org/), you are lucky. You could use the following commands to open ports 80 & 443:

  ```bash
  sudo firewall-cmd --add-service=http --permanent
  sudo firewall-cmd --add-service=https --permanent
  sudo firewall-cmd --reload
  ```

* Use systemd and make sure that [podman](https://podman.io/getting-started/installation.html) (2.0.1 version at least), xxd, uuidgen and openssl are installed on your server.

  You could use `sudo dnf install -y vim-common` or `sudo apt-get install -y xxd` to install xxd for Fedora or Ubuntu. 

### Using

1. Clone this project and enter this project's directory.

2. Put some websites like "index.html" into the "www" directory (Please do this).

3. Run `./tlh.sh` from the terminal and follow the prompt to enter your domain.

5. Using `cat current/v2ray_client_template.json` to see the client-side configuration template.

### Usage

Update the last hope (containers):

```bash
// update manually
sudo podman auto-update

// or update automatically
sudo systemctl enable --now podman-auto-update.timer
```

Stop the last hope:

```bash
sudo systemctl stop pod-tlh
```

Uninstall the last hope:

```bash
./tlh_uninstall.sh
```
