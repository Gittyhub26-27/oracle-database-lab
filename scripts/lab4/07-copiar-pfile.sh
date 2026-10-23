#!/usr/bin/env bash
# scripts/lab4/07-copiar-pfile.sh
set -euo pipefail
source scripts/deployment/env/00-config.sh

DEST="docs/bitacora/lab4/evidencia/config"
mkdir -p "$DEST"

for f in initFREE_lab4.ora initFREE_lab4_memoria.ora; do
  docker cp "$CONT_NAME:/tmp/$f" "$DEST/$f"
done

wc -l "$DEST"/initFREE_lab4*.ora
