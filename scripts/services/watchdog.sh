#!/bin/bash
# Auto-start KVM Space services (MC + Cockpit) if not running

export PATH=/usr/local/node-v14.21.3-linux-arm64/bin:$PATH

# Check MC (8444)
if ! ss -tlnp | grep -q ':8444'; then
  cd /opt/kvm-space
  KVM_MODE=libvirt nohup node server/src/app.js > /tmp/mc.log 2>&1 &
  echo "[$(date)] MC restarted" >> /tmp/kvm-space-watchdog.log
fi

# Check Cockpit (9091)
if ! ss -tlnp | grep -q ':9091'; then
  cd /opt/kvm-space
  nohup node cockpit/server/src/app.js > /tmp/cockpit.log 2>&1 &
  echo "[$(date)] Cockpit restarted" >> /tmp/kvm-space-watchdog.log
fi
