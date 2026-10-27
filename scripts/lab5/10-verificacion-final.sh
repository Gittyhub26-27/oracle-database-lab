#!/usr/bin/env bash
# scripts/lab5/10-verificacion-final.sh
set -euo pipefail
source scripts/deployment/env/00-config.sh

echo "== Verificación Final del Lab 5 =="

# 1. Comprobar existencia de archivos clave
[ -f database/migrations/V004_tiendasur_benchmark.sql ] && echo "[OK] Migración V004 presente"
[ -f scripts/lab5/01-paquete-medicion.sql ] && echo "[OK] Script paquete medición presente"
[ -f scripts/lab5/02-experimento1-indices.sql ] && echo "[OK] Experimento 1 presente"
[ -f scripts/lab5/03-experimento2-covering-index.sql ] && echo "[OK] Experimento 2 presente"

# 2. Comprobar objeto lab_tools.medir en DB
v_pkg=$(docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba <<'EOF'
SET HEAD OFF FEED OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT status FROM dba_objects WHERE owner = 'LAB_TOOLS' AND object_name = 'MEDIR' AND object_type = 'PACKAGE';
EXIT
EOF
)

if echo "$v_pkg" | grep -q "VALID"; then
  echo "[OK] Paquete lab_tools.medir VÁLIDO en FREEPDB1"
else
  echo "[ERROR] El paquete lab_tools.medir no está válido"
  exit 1
fi

echo ""
echo "RESULTADO: TODO OK. Lab 5 listo para entregar."

