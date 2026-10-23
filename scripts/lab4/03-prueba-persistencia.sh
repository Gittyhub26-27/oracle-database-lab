#!/usr/bin/env bash
# scripts/lab4/03-prueba-persistencia.sh
set -euo pipefail
source scripts/deployment/env/00-config.sh

sysdba() { docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba; }

echo "== 1. ANTES: entornos de negocio =="
sysdba < scripts/lab4/03-verificar-negocio.sql

echo "== 2. Parada limpia (SHUTDOWN IMMEDIATE) y borrado del contenedor =="
printf 'SHUTDOWN IMMEDIATE\nEXIT\n' | sysdba || true
docker stop -t 120 "$CONT_NAME" >/dev/null || true
docker rm "$CONT_NAME"
docker volume ls --filter "name=$VOL_NAME"

echo "== 3. Recrear el contenedor con la definición corregida =="
bash scripts/deployment/env/05-crear-contenedor.sh
bash scripts/ops/esperar-healthy.sh

echo "== 4. DESPUÉS: mismos entornos, mismos datos =="
sysdba < scripts/lab4/03-verificar-negocio.sql

echo "== 5. Puertos publicados ahora (ya no aparece 8181) =="
docker port "$CONT_NAME"
