#!/bin/bash

DAEMON_SCRIPT="ssh-keepalive-daemon.sh"
DAEMON_PATH="/usr/local/sbin/$DAEMON_SCRIPT"
SERVICE_FILE="/etc/systemd/system/ssh-keepalive.service"

echo "Starting SSH Keepalive Manager setup..."

# Check if daemon script exists in current dir
if [ ! -f "$DAEMON_SCRIPT" ]; then
  echo "ERROR: $DAEMON_SCRIPT not found in current directory."
  exit 1
fi

# Copy daemon script
echo "Copying daemon script to $DAEMON_PATH..."
cp "$DAEMON_SCRIPT" "$DAEMON_PATH" || { echo "Failed to copy script."; exit 1; }
chmod +x "$DAEMON_PATH"

# Create systemd service file
echo "Creating systemd service unit file at $SERVICE_FILE..."
cat << EOF > "$SERVICE_FILE"
[Unit]
Description=SSH Keepalive Management Daemon
After=network.target sshd.service
Wants=sshd.service

[Service]
Type=simple
ExecStart=$DAEMON_PATH
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd daemons
echo "Reloading systemd daemon..."
systemctl daemon-reload

# Enable and start service
echo "Enabling and starting ssh-keepalive.service..."
systemctl enable ssh-keepalive.service
systemctl start ssh-keepalive.service

echo
echo "--------------------------------------------------"
echo "SSH Keepalive Manager setup is COMPLETE!"
echo
echo "The daemon is now running and managing your SSH keepalive settings."
echo "You can check its status anytime with:"
echo "  sudo systemctl status ssh-keepalive.service"
echo
echo "To view logs, run:"
echo "  sudo journalctl -u ssh-keepalive.service -f"
echo
echo "When you want to stop it, run:"
echo "  sudo systemctl stop ssh-keepalive.service"
echo
echo "Welcome to stable, hassle-free SSH sessions!"
echo "--------------------------------------------------"
