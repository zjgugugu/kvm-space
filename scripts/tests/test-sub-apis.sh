#!/bin/bash
TOKEN=$(curl -sk -X POST https://localhost:8444/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}' | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])")
for ep in /api/system-extra/zombie-servers /api/system-extra/detection /api/clients/tasks/list /api/apps/builtin-rules /api/apps/custom-rules /api/apps/software /api/apps/publish; do
  CODE=$(curl -sk -o /dev/null -w '%{http_code}' -H "Authorization: Bearer $TOKEN" "https://localhost:8444$ep")
  echo "$CODE $ep"
done
