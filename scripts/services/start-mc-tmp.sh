#!/bin/bash
cd /opt/kvm-space
rm -f server/data/kvm-cloud.db
nohup /usr/local/node-v14.21.3-linux-arm64/bin/node server/src/app.js > /tmp/mc.log 2>&1 &
echo "MC PID: $!"
sleep 3
curl -s http://127.0.0.1:8444/api/info
