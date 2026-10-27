-- database/migrations/V004_tiendasur_benchmark.sql
WHENEVER SQLERROR EXIT SQL.SQLCODE
SET FEEDBACK ON
ALTER SESSION SET CONTAINER = FREEPDB1;

DECLARE
  v_existe NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_existe FROM dba_tablespaces WHERE tablespace_name = 'TBS_RETAIL';
  IF v_existe = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLESPACE TBS_RETAIL DATAFILE ''/opt/oracle/oradata/FREE/FREEPDB1/retail01.dbf'' SIZE 100M AUTOEXTEND ON NEXT 50M MAXSIZE 1G';
  END IF;
END;
/

ALTER SESSION SET CURRENT_SCHEMA = ADMIN_RETAIL;

DECLARE
  v_tabla NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_tabla FROM dba_tables WHERE owner = 'ADMIN_RETAIL' AND table_name = 'TS_CLIENTES';
  IF v_tabla = 0 THEN
    EXECUTE IMMEDIATE '
      CREATE TABLE ts_clientes (
        cliente_id       NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_ts_clientes PRIMARY KEY,
        codigo_cliente   VARCHAR2(20) NOT NULL,
        nombre           VARCHAR2(100) NOT NULL,
        email            VARCHAR2(150),
        provincia        VARCHAR2(50),
        fecha_alta       DATE DEFAULT SYSDATE NOT NULL,
        estado           VARCHAR2(15) DEFAULT ''ACTIVO'' NOT NULL
      ) TABLESPACE TBS_RETAIL';
  END IF;

  SELECT COUNT(*) INTO v_tabla FROM dba_tables WHERE owner = 'ADMIN_RETAIL' AND table_name = 'TS_PEDIDOS';
  IF v_tabla = 0 THEN
    EXECUTE IMMEDIATE '
      CREATE TABLE ts_pedidos (
        pedido_id        NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT pk_ts_pedidos PRIMARY KEY,
        cliente_id       NUMBER NOT NULL,
        fecha_pedido     DATE DEFAULT SYSDATE NOT NULL,
        estado           VARCHAR2(20) DEFAULT ''PENDIENTE'' NOT NULL,
        total            NUMBER(10,2) DEFAULT 0 NOT NULL,
        canal            VARCHAR2(15) DEFAULT ''WEB'' NOT NULL
      ) TABLESPACE TBS_RETAIL';
  END IF;
END;
/

DECLARE
  v_filas NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_filas FROM admin_retail.ts_clientes;
  IF v_filas = 0 THEN
    INSERT INTO admin_retail.ts_clientes (codigo_cliente, nombre, email, provincia, estado)
    SELECT 'CLI' || LPAD(level, 6, '0'),
           'Cliente ' || level,
           'cli' || level || '@tiendasur.es',
           CASE MOD(level, 5)
             WHEN 0 THEN 'MADRID'
             WHEN 1 THEN 'BARCELONA'
             WHEN 2 THEN 'SEVILLA'
             WHEN 3 THEN 'VALENCIA'
             ELSE 'MURCIA'
           END,
           CASE WHEN MOD(level, 20) = 0 THEN 'INACTIVO' ELSE 'ACTIVO' END
    FROM dual CONNECT BY level <= 50000;
  END IF;

  SELECT COUNT(*) INTO v_filas FROM admin_retail.ts_pedidos;
  IF v_filas = 0 THEN
    INSERT INTO admin_retail.ts_pedidos (cliente_id, fecha_pedido, estado, total, canal)
    SELECT MOD(level, 50000) + 1,
           TRUNC(SYSDATE) - MOD(level, 365),
           CASE MOD(level, 4)
             WHEN 0 THEN 'ENTREGADO'
             WHEN 1 THEN 'ENVIADO'
             WHEN 2 THEN 'PROCESANDO'
             ELSE 'PENDIENTE'
           END,
           ROUND(DBMS_RANDOM.VALUE(10, 500), 2),
           CASE WHEN MOD(level, 3) = 0 THEN 'TIENDA' ELSE 'WEB' END
    FROM dual CONNECT BY level <= 150000;
  END IF;
  COMMIT;
END;
/

BEGIN
  DBMS_STATS.GATHER_SCHEMA_STATS('ADMIN_RETAIL');
END;
/
EXIT
