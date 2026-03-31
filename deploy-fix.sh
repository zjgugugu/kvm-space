#!/bin/bash
echo "=== 检查 dist 结构 ==="
ls -la /opt/kvm-cloud/web/dist/
echo "---"
ls /opt/kvm-cloud/web/dist/assets/ | head -5
echo "=== 检查新文件 ==="
# 新构建的 Dashboard 文件
ls -la /opt/kvm-cloud/web/dist/assets/Dashboard-*.js 2>/dev/null
ls -la /opt/kvm-cloud/web/dist/assets/Reports-*.js 2>/dev/null
echo "=== 如果有嵌套dist，移动文件 ==="
if [ -d /opt/kvm-cloud/web/dist/dist ]; then
  echo "发现嵌套dist目录，修复..."
  cp -r /opt/kvm-cloud/web/dist/dist/* /opt/kvm-cloud/web/dist/
  rm -rf /opt/kvm-cloud/web/dist/dist
  echo "修复完成"
fi
echo "=== 重启服务 ==="
pkill -f 'node.*app.js' 2>/dev/null
sleep 1
cd /opt/kvm-cloud/server
nohup bash start-libvirt.sh > /tmp/kvm-cloud.log 2>&1 &
sleep 5
cat /tmp/kvm-cloud.log
echo
curl -s http://localhost:3000/api/info
echo
echo "DONE"
