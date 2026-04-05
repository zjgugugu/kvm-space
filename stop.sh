#!/bin/bash
# KVM Cloud 管理平台 - 停止脚本
PID=$(lsof -ti:8444 2>/dev/null)
if [ -n "$PID" ]; then
    echo "正在停止 KVM Cloud (PID: $PID)..."
    kill $PID
    echo "已停止"
else
    echo "KVM Cloud 未在运行"
fi
