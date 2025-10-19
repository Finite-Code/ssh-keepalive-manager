#!/bin/bash

SSHD_CONF="/etc/ssh/sshd_config"
BACKUP_CONF="/etc/ssh/sshd_config.bak"
APPROVAL_FILE="/tmp/ssh-restart-approve"
STATE_FILE="/tmp/ssh_keepalive_mode"

EXTENDED_START=23    # 11 PM
EXTENDED_END=11      # 11 AM

DEFAULT_INTERVAL=60
DEFAULT_COUNTMAX=3
EXTENDED_INTERVAL=300
EXTENDED_COUNTMAX=144 # 12 hours

MAX_WAIT=600       # 10 minutes max wait for approval
WAIT_INTERVAL=5    # check every 5 seconds

notify_ssh_users() {
  local message="$1"
  for user in $(who | grep 'pts/' | awk '{print $1}' | sort | uniq); do
    echo "$message" | write "$user" 2>/dev/null
  done
}

active_ssh_count() {
  ss -o state established '( dport = :ssh or sport = :ssh )' | wc -l
}

update_sshd_config() {
  local interval=$1
  local countmax=$2

  # Backup on first run
  if [ ! -f "$BACKUP_CONF" ]; then
    cp "$SSHD_CONF" "$BACKUP_CONF"
  fi

  sed -i '/^ClientAliveInterval/d' "$SSHD_CONF"
  sed -i '/^ClientAliveCountMax/d' "$SSHD_CONF"

  echo "ClientAliveInterval $interval" >> "$SSHD_CONF"
  echo "ClientAliveCountMax $countmax" >> "$SSHD_CONF"
}

while true; do
  HOUR=$(date +%H)
  HOUR=$((10#$HOUR))  # strip leading zero if any

  if (( HOUR >= EXTENDED_START || HOUR < EXTENDED_END )); then
    desired_mode="extended"
    upd_interval=$EXTENDED_INTERVAL
    upd_countmax=$EXTENDED_COUNTMAX
    mode_msg="Extended (nighttime) SSH keepalive mode"
  else
    desired_mode="default"
    upd_interval=$DEFAULT_INTERVAL
    upd_countmax=$DEFAULT_COUNTMAX
    mode_msg="Default (daytime) SSH keepalive mode"
  fi

  current_mode=$(cat "$STATE_FILE" 2>/dev/null || echo "none")
  if [ "$desired_mode" != "$current_mode" ]; then
    active_sessions=$(active_ssh_count)

    if (( active_sessions == 0 )); then
      # No active sessions - apply immediately
      echo "$(date): No active SSH sessions. Applying $mode_msg"
      update_sshd_config "$upd_interval" "$upd_countmax"
      systemctl restart sshd
      echo "$desired_mode" > "$STATE_FILE"
    else
      notify_ssh_users "NOTICE: SSH server must restart soon to apply keepalive changes. If ready, please run 'touch /tmp/ssh-restart-approve' to approve immediate restart. Waiting up to 10 minutes."

      elapsed=0
      notified=0
      while (( elapsed < MAX_WAIT )); do
        if [ -f "$APPROVAL_FILE" ]; then
          if (( notified == 0 )); then
            notify_ssh_users "SSH restart approved by a user. Restarting now."
            echo "$(date): Restart approved by user."
            notified=1
          fi
          update_sshd_config "$upd_interval" "$upd_countmax"
          systemctl restart sshd
          echo "$desired_mode" > "$STATE_FILE"
          rm -f "$APPROVAL_FILE"
          break
        fi
        sleep $WAIT_INTERVAL
        elapsed=$(( elapsed + WAIT_INTERVAL ))
      done

      if (( elapsed >= MAX_WAIT )); then
        notify_ssh_users "No SSH restart approval received within 10 minutes. Restart deferred."
        echo "$(date): Restart deferred due to no approval."
      fi
    fi
  fi

  sleep 60
done
