-- scripts/lab5/02-experimento1-indices.sql
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER SESSION SET CURRENT_SCHEMA = ADMIN_RETAIL;

SET SERVEROUTPUT ON SIZE UNLIMITED;

PROMPT =========================================================
PROMPT 1. Medición SIN ÍNDICE (Full Table Scan)
PROMPT =========================================================

DECLARE
  v_conteo NUMBER;
BEGIN
  lab_tools.medir.iniciar;

  SELECT COUNT(*) INTO v_conteo
  FROM ts_pedidos p
  JOIN ts_clientes c ON p.cliente_id = c.cliente_id
  WHERE c.provincia = 'SEVILLA'
    AND p.estado = 'PENDIENTE';

  lab_tools.medir.mostrar_resultado('Sin indice (Full Table Scan)');
END;
/

PROMPT =========================================================
PROMPT 2. Creación de índices tácticos
PROMPT =========================================================

DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_count FROM dba_indexes WHERE owner = 'ADMIN_RETAIL' AND index_name = 'IDX_TS_CLIENTES_PROVINCIA';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_ts_clientes_provincia ON ts_clientes(provincia) TABLESPACE TBS_RETAIL';
  END IF;

  SELECT COUNT(*) INTO v_count FROM dba_indexes WHERE owner = 'ADMIN_RETAIL' AND index_name = 'IDX_TS_PEDIDOS_ESTADO_CLI';
  IF v_count = 0 THEN
    EXECUTE IMMEDIATE 'CREATE INDEX idx_ts_pedidos_estado_cli ON ts_pedidos(estado, cliente_id) TABLESPACE TBS_RETAIL';
  END IF;
END;
/

BEGIN
  DBMS_STATS.GATHER_TABLE_STATS('ADMIN_RETAIL', 'TS_CLIENTES');
  DBMS_STATS.GATHER_TABLE_STATS('ADMIN_RETAIL', 'TS_PEDIDOS');
END;
/

PROMPT =========================================================
PROMPT 3. Medición CON ÍNDICE (Index Range Scan / Join)
PROMPT =========================================================

DECLARE
  v_conteo NUMBER;
BEGIN
  lab_tools.medir.iniciar;

  SELECT COUNT(*) INTO v_conteo
  FROM ts_pedidos p
  JOIN ts_clientes c ON p.cliente_id = c.cliente_id
  WHERE c.provincia = 'SEVILLA'
    AND p.estado = 'PENDIENTE';

  lab_tools.medir.mostrar_resultado('Con indice tactico');
END;
/

EXIT
