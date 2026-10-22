-- scripts/lab4/06-arranque-por-etapas.sql
WHENEVER SQLERROR CONTINUE
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF ECHO OFF
COLUMN instance_name FORMAT A10
COLUMN name FORMAT A40
COLUMN value FORMAT A70

PROMPT ===== 0. Punto de partida =====
SELECT instance_name, status, database_status FROM v$instance;

PROMPT ===== 1. SHUTDOWN IMMEDIATE =====
SHUTDOWN IMMEDIATE

PROMPT ===== 2. STARTUP NOMOUNT =====
STARTUP NOMOUNT
SELECT instance_name, status FROM v$instance;
PROMPT v$parameter responde (SPFILE en memoria):
SELECT name, value FROM v$parameter WHERE name IN ('control_files', 'db_name', 'spfile');
PROMPT v$database NO responde -> ORA-01507 esperado:
SELECT name, open_mode FROM v$database;

PROMPT ===== 3. ALTER DATABASE MOUNT =====
ALTER DATABASE MOUNT;
SELECT instance_name, status FROM v$instance;
SELECT name, open_mode, log_mode FROM v$database;
SELECT COUNT(*) AS datafiles_conocidos FROM v$datafile;
PROMPT El diccionario NO es accesible -> ORA-01219 esperado:
SELECT COUNT(*) FROM dba_tables;

PROMPT ===== 4. ALTER DATABASE OPEN =====
ALTER DATABASE OPEN;
SELECT instance_name, status, database_status FROM v$instance;
SELECT name, open_mode FROM v$database;
PROMPT Estado guardado de las PDB:
SELECT con_id, name, open_mode, restricted FROM v$pdbs ORDER BY con_id;

PROMPT ===== 5. ADR y alert log =====
SELECT name, value FROM v$diag_info WHERE name IN ('ADR Home', 'Diag Trace');
EXIT
