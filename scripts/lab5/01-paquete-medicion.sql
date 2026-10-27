-- scripts/lab5/01-paquete-medicion.sql
WHENEVER SQLERROR EXIT SQL.SQLCODE
ALTER SESSION SET CONTAINER = FREEPDB1;

DECLARE
  v_existe NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_existe FROM dba_users WHERE username = 'LAB_TOOLS';
  IF v_existe = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER lab_tools IDENTIFIED BY "LabTools_2026_*" DEFAULT TABLESPACE USERS TEMPORARY TABLESPACE TEMP';
  END IF;
END;
/

GRANT UNLIMITED TABLESPACE TO lab_tools;
GRANT CREATE SESSION, CREATE PROCEDURE TO lab_tools;
GRANT SELECT ON v_$mystat TO lab_tools;
GRANT SELECT ON v_$statname TO lab_tools;

CREATE OR REPLACE PACKAGE lab_tools.medir AUTHID DEFINER AS
  PROCEDURE iniciar;
  PROCEDURE mostrar_resultado(p_etiqueta VARCHAR2 DEFAULT 'Medición');
END medir;
/

CREATE OR REPLACE PACKAGE BODY lab_tools.medir AS
  g_cpu_start NUMBER;
  g_reads_start NUMBER;

  PROCEDURE iniciar IS
  BEGIN
    g_cpu_start := DBMS_UTILITY.GET_CPU_TIME;
    SELECT m.value INTO g_reads_start
    FROM v$mystat m JOIN v$statname n ON n.statistic# = m.statistic#
    WHERE n.name = 'session logical reads';
  END iniciar;

  PROCEDURE mostrar_resultado(p_etiqueta VARCHAR2 DEFAULT 'Medición') IS
    v_cpu_end NUMBER := DBMS_UTILITY.GET_CPU_TIME;
    v_reads_end NUMBER;
    v_cpu_ms NUMBER;
    v_reads NUMBER;
  BEGIN
    SELECT m.value INTO v_reads_end
    FROM v$mystat m JOIN v$statname n ON n.statistic# = m.statistic#
    WHERE n.name = 'session logical reads';

    v_cpu_ms := (v_cpu_end - g_cpu_start) * 10;
    v_reads := v_reads_end - g_reads_start;

    DBMS_OUTPUT.PUT_LINE(RPAD(p_etiqueta, 35) || ' | Lecturas Lógicas: ' || LPAD(v_reads, 8) || ' | CPU: ' || LPAD(v_cpu_ms, 6) || ' ms');
  END mostrar_resultado;
END medir;
/
GRANT EXECUTE ON lab_tools.medir TO PUBLIC;
EXIT
