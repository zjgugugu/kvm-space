#!/bin/bash
# KVM Cloud - Libvirt 模式启动脚本
cd /opt/kvm-cloud/server
export KVM_MODE=libvirt
export PORT=3000

NODE=/usr/local/bin/node18

echo "=== KVM Cloud Libvirt 启动 ==="
echo "Node: $($NODE --version)"
echo "Mode: $KVM_MODE"
echo "Port: $PORT"

# 先测试关键模块
$NODE -e 'try{require("better-sqlite3");console.log("better-sqlite3: OK")}catch(e){console.error("better-sqlite3 FAIL:",e.message);process.exit(1)}'
if [ $? -ne 0 ]; then
  echo "请先运行: $NODE /usr/local/node-v18.20.8-linux-x64/lib/node_modules/npm/bin/npm-cli.js install"
  exit 1
fi

# 杀掉之前的实例
pkill -f "node.*app.js" 2>/dev/null
sleep 1

echo "启动服务..."
exec $NODE src/app.js
