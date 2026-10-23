-- scripts/lab4/07-parametros-cambios.sql
WHENEVER SQLERROR CONTINUE
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF
COLUMN name FORMAT A16
COLUMN en_memoria FORMAT A12
COLUMN en_spfile FORMAT A16
COLUMN contenedor FORMAT A10
COLUMN update_comment FORMAT A40

PROMPT ===== 1. SCOPE MEMORY =====
ALTER SYSTEM SET open_cursors = 400 SCOPE = MEMORY;
SELECT p.name, p.value AS en_memoria, NVL(s.value, '(sin valor)') AS en_spfile
FROM v$parameter p JOIN v$spparameter s ON s.name = p.name
WHERE p.name = 'open_cursors';

PROMPT ===== 2. SCOPE BOTH =====
ALTER SYSTEM SET open_cursors = 500 COMMENT = 'Lab4: prueba SCOPE=BOTH' SCOPE = BOTH;
SELECT p.name, p.value AS en_memoria, s.value AS en_spfile, p.update_comment
FROM v$parameter p JOIN v$spparameter s ON s.name = p.name
WHERE p.name = 'open_cursors';

PROMPT Deshacer:
ALTER SYSTEM SET open_cursors = 300 COMMENT = '' SCOPE = BOTH;

PROMPT ===== 3. Parámetro ESTÁTICO (ORA-02095 esperado) =====
ALTER SYSTEM SET db_files = 300 SCOPE = MEMORY;

PROMPT SCOPE=SPFILE para estáticos:
ALTER SYSTEM SET db_files = 300 SCOPE = SPFILE;
SELECT p.name, p.value AS en_memoria, s.value AS en_spfile
FROM v$parameter p JOIN v$spparameter s ON s.name = p.name
WHERE p.name = 'db_files';

PROMPT Deshacer con RESET:
ALTER SYSTEM RESET db_files SCOPE = SPFILE;

PROMPT ===== 4. Parámetros a nivel de PDB =====
ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER SYSTEM SET open_cursors = 350 SCOPE = MEMORY;
SELECT SYS_CONTEXT('USERENV', 'CON_NAME') AS contenedor, name, value AS en_memoria
FROM v$parameter WHERE name = 'open_cursors';

PROMPT ORA-65040 esperado (no se puede cambiar parámetro de CDB desde PDB):
ALTER SYSTEM SET processes = 300 SCOPE = SPFILE;

PROMPT Deshacer en PDB:
ALTER SYSTEM RESET open_cursors SCOPE = MEMORY;
ALTER SESSION SET CONTAINER = CDB$ROOT;

PROMPT ===== 5. Generar PFILEs para versionar =====
CREATE PFILE = '/tmp/initFREE_lab4.ora' FROM SPFILE;
CREATE PFILE = '/tmp/initFREE_lab4_memoria.ora' FROM MEMORY;
EXIT
