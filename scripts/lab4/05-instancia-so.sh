#!/usr/bin/env bash
# scripts/lab4/05-instancia-so.sh
set -euo pipefail
source scripts/deployment/env/00-config.sh

echo "== 1. Procesos de la instancia FREE =="
docker top "$CONT_NAME" -eo pid,user,rss,args | grep -E '(ora|db)_[a-z0-9]+_FREE' | head -15
echo " ... total de procesos de background: $(docker top "$CONT_NAME" -eo pid,args | grep -cE '(ora|db)_[a-z0-9]+_FREE')"

echo "== 2. Memoria del contenedor (incluye la SGA) =="
docker stats --no-stream --format 'table {{.Name}}\t{{.MemUsage}}\t{{.CPUPerc}}' "$CONT_NAME"

echo "== 3. La base de datos en disco: archivos del CDB y de FREEPDB1 =="
docker exec "$CONT_NAME" bash -c 'ls -lh /opt/oracle/oradata/FREE | grep -v ^total; echo "-- FREEPDB1 --"; ls -lh /opt/oracle/oradata/FREE/FREEPDB1 | grep -v ^total'

echo "== 4. Listener: servicios registrados =="
docker exec "$CONT_NAME" lsnrctl status | grep -E 'Service|Instance|Listening|Uptime'
