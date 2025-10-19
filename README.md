# SSH Keepalive Manager

Keep your SSH sessions alive effortlessly, even during client sleep!

## Overview

This lightweight Bash script dynamically manages SSH server keepalive settings based on the time of day. It extends the keepalive timeout overnight to prevent unexpected SSH disconnections, especially when your client device (like a laptop) goes to sleep. During the day, it switches back to default timeouts for normal operation.

It also notifies connected SSH users before restarting the SSH daemon to apply updated settings and allows simple user approval for the restart to avoid disruptions.

---

## Features

- Automatic switching between extended (night) and default (day) SSH keepalive settings  
- User notifications and approval prompt before restarting SSH server  
- Minimal system resource usage — runs as a lightweight background daemon  
- Easy setup with a helper script that installs and configures a systemd service  
- Perfect for personal servers or small environments  

---

## Setup

1. Place `ssh-keepalive-daemon.sh` and `setup-ssh-keepalive.sh` in the same directory.  
2. Run the setup script with root permissions:
```bash
sudo bash setup-ssh-keepalive.sh
```
3. This will copy the daemon script, create and enable a systemd service, and start managing SSH keepalive immediately.

---

## Usage

- The daemon automatically adjusts SSH keepalive settings based on time.  
- To approve a pending restart, SSH users can run:
```bash
touch /tmp/ssh-restart-approve
```
- Check service status:
```bash
sudo systemctl status ssh-keepalive.service
```
- View logs live:

```bash
sudo journalctl -fu ssh-keepalive.service

```
- Stop/start the service as needed:
```bash (Stop)
sudo systemctl stop ssh-keepalive.service
```
```bash (Start)
sudo systemctl start ssh-keepalive.service
```

---

## Customization

- Modify `EXTENDED_START` and `EXTENDED_END` variables in `ssh-keepalive-daemon.sh` to change extended keepalive time range.  
- Adjust keepalive intervals inside the daemon script as desired.

---

## License

This project is open source under the MIT License. Feel free to fork, improve, and share!

---

Enjoy hassle-free, stable SSH sessions!

---

If you find this tool useful, consider starring the repo ⭐️

