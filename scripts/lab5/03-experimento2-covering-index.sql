-- scripts/lab5/03-experimento2-covering-index.sql
-- Experimento 2: Impacto de un Índice Cubridor (Index Only Access)
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = ADMIN_RETAIL;

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT =========================================================
PROMPT 1. Consulta accediendo a Tabla mediante Índice Estándar
PROMPT =========================================================

DECLARE
  v_conteo NUMBER;
BEGIN
  lab_tools.medir.iniciar;

  SELECT COUNT(p.total) INTO v_conteo
  FROM ts_pedidos p
  WHERE p.estado = 'ENTREGADO'
    AND p.canal = 'WEB';

  lab_tools.medir.mostrar_resultado('Acceso con Indice + Tabla');
END;
/

PROMPT =========================================================
PROMPT 2. Creación de Índice Cubridor (Covering Index)
PROMPT =========================================================

DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_indexes WHERE owner = 'ADMIN_RETAIL' AND index_name = 'IDX_TS_PEDIDOS_COVERING';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_ts_pedidos_covering ON ts_pedidos(estado, canal, total) TABLESPACE TBS_RETAIL';
  END IF;
END;
/

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS('ADMIN_RETAIL', 'TS_PEDIDOS');
END;
/

PROMPT =========================================================
PROMPT 3. Consulta usando ÚNICAMENTE el Índice Cubridor
PROMPT =========================================================

DECLARE
  v_conteo NUMBER;
BEGIN
  lab_tools.medir.iniciar;

  SELECT COUNT(p.total) INTO v_conteo
  FROM ts_pedidos p
  WHERE p.estado = 'ENTREGADO'
    AND p.canal = 'WEB';

  lab_tools.medir.mostrar_resultado('Acceso Solo Indice (Covering)');
END;
/

EXIT
