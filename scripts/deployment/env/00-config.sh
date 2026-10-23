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

#!/usr/bin/env bash
# scripts/deployment/env/00-config.sh
# Constantes del proyecto oracle-database-lab. Uso: source scripts/deployment/env/00-config.sh
# NO contiene secretos: las contraseñas viven en config/.env (Parte D).

export CONT_NAME="oralab-26ai"
export VOL_NAME="oralab-26ai-data"
export IMG="container-registry.oracle.com/database/free:latest"
export PORT_DB=1521
export PORT_ORDS=8181
export SERVICE_CDB="FREE"
export SERVICE_PDB="FREEPDB1"
export BACKUP_DIR="$(pwd)/backups"
export EVID="docs/bitacora/evidencia"

# Marca de tiempo ISO 8601 en UTC para nombrar la evidencia: $(ts)
ts() { date -u +%Y%m%dT%H%M%SZ; }
export -f ts
# ORDS (Parte M): middleware instalado en Linux, fuera del contenedor de la base
export ORDS_HOME="/opt/oracle/ords"
export ORDS_CONFIG="/etc/ords/config"
export ORDS_LOGS="/var/log/ords"
export ORDS_PORT=8080

# ORDS (Parte M): middleware instalado en Linux, fuera del contenedor de la base
export ORDS_HOME="/opt/oracle/ords"
export ORDS_CONFIG="/etc/ords/config"
export ORDS_LOGS="/var/log/ords"
export ORDS_PORT=8080
>>>>>>> 6aee3c297cf52b7a2be0d7417103372b05eb9680
