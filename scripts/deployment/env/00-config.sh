# Configuración general y constantes del Lab 4
export HELPER_IMG="ubuntu:24.04"
export DATA_ROOT="/opt/oracle/oradata"
export EVID_LAB4="docs/bitacora/lab4/evidencia"
export BACKUP_DIR="$(pwd)/backups"
export VOL_NAME="oralab-26ai-data"
export CONT_NAME="oralab-26ai"
export SERVICE_CDB="FREE"
export SERVICE_PDB="FREEPDB1"
export PORT_DB="1521"
export PORT_ORDS="8181"

ts() { date -u +%Y%m%dT%H%M%SZ; }
export PORT_ORDS=8181 # Lab 4: OBSOLETA. ORDS corre en Linux y escucha en ORDS_PORT (8080)
