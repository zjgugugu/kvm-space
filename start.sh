#!/bin/bash
# KVM Cloud 管理平台 - 启动脚本
# 使用独立端口8444，不影响原有系统

export PATH=/usr/local/node-v14.21.3-linux-arm64/bin:$PATH
export KVM_MODE=libvirt
export PORT=8444
export NODE_ENV=production

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/server"

# 创建数据目录
mkdir -p data

# 检查是否已有进程在端口8444上运行
PID=$(lsof -ti:8444 2>/dev/null)
if [ -n "$PID" ]; then
    echo "[INFO] 正在停止旧进程 (PID: $PID)..."
    kill $PID 2>/dev/null
    sleep 2
fi

echo "==========================================="
echo "  KVM Cloud 虚拟化管理平台"
echo "  端口: $PORT  模式: $KVM_MODE"
echo "==========================================="

exec node src/app.js
