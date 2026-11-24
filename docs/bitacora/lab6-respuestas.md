# Respuestas y simulacro 1Z0-182 · Lab 6 · E008

## 1. Preguntas de comprobación

### Partes A–C · Rol operativo, parámetros y estados

**1. Errores ORA- en 24 h (Parte B)**
En el log `20261118T180048Z_01-turno.script.log` salieron `12` errores `ORA-` acumulados en las últimas 24 horas. Se deben principalmente a los fallos provocados en los simulacros del Lab 5 (`ORA-01113`, `ORA-01110`, etc.) junto con los avisos habituales del arranque del contenedor (`ORA-00800` y `ORA-20013`). Este número no es una alarma por sí solo porque, sin compararlo con una línea base conocida de errores esperados, una cifra suelta no permite distinguir el ruido heredado de un fallo nuevo.

**2. Ventana de mantenimiento del miércoles y tareas automáticas (Parte B)**
Revisando `20261118T180103Z_01-automatizacion.spool.log`, la ventana `WEDNESDAY_WINDOW` empieza a las `22:00` (`byhour=22`) y tiene una duración de `4` horas. Dentro de esa ventana corren las tres tareas automáticas de AutoTask en estado `ENABLED`: `auto optimizer stats collection`, `auto space advisor` y `sql tuning advisor`.

**3. Diferencia entre V$SPPARAMETER y V$PARAMETER tras SCOPE=SPFILE (Parte C)**
En `20261118T180110Z_02-parametros.script.log` se ve que, tras lanzar el cambio con `SCOPE=SPFILE`, `V$SPPARAMETER` pasó a marcar `250` con `ISSPECIFIED = TRUE`, mientras que `V$PARAMETER` seguía mostrando `200` en la memoria en uso. De no haber hecho el `RESET`, en el siguiente reinicio la instancia habría leído el SPFILE y arrancado aplicando `db_files = 250`.

**4. Por qué RESET sirvió para db_files y no habría servido para processes (Parte C)**
En `db_files`, `ISSPECIFIED` valía `FALSE` antes del cambio, es decir, no estaba escrito en el SPFILE; por tanto, `RESET` lo devolvió exactamente a su estado original sin fijar. En cambio, en el PFILE de respaldo (`init_desde_spfile.ora`) el parámetro `processes` sí aparece fijado explícitamente (`*.processes=200`), así que hacerle `RESET` habría borrado esa línea y alterado su valor en el siguiente arranque.

**5. Reinicio sin estado guardado (Parte C)**
En `20261118T180111Z_02-estados-pdb.script.log`, tras descartar el estado y reiniciar, `C##OPS_RO` recibió el error `ORA-01109: database not open` al intentar conectar por `freepdb1`. La instancia indicaba `Database opened` porque el contenedor raíz (`CDB$ROOT`) sí se abre al arrancar, pero al haberse ejecutado `DISCARD STATE`, las PDB arrancan por defecto cerradas en estado `MOUNTED`.

---

### Partes D–E · Servicios, sesiones y diccionario

**6. SID, SPID, evento e instrumentación de la aplicación (Parte D)**
En `20261118T180822Z_03-sesiones.script.log`, la sesión de la aplicación tenía `SID = 219`, `SERIAL# = 24541`, `SPID = 2537` (su proceso dedicado en Linux) y estaba en el evento de espera `PL/SQL lock timer`. Los campos `MODULE` (`matriculas`), `ACTION` (`cierre-periodo`) y `CLIENT_IDENTIFIER` (`ana.garcia@ucam`) permiten identificar qué proceso concreto y qué persona real están operando detrás de una cuenta genérica como `APP_ACADEMIA`.

**7. Efecto de CANCEL SQL frente a KILL SESSION y estado de la fila 101 (Parte D)**
Según se ve en `20261118T180822Z_03-sesiones.script.log`, tras ejecutar `ALTER SYSTEM CANCEL SQL` seguía habiendo `1` transacción abierta, ya que solo se cancela la llamada en curso (`SLEEP`), manteniendo viva la sesión y su transacción. Tras lanzar `ALTER SYSTEM KILL SESSION ... IMMEDIATE`, las transacciones abiertas bajaron a `0` y el estudiante `101` volvió a quedar en `ACTIVO`, porque PMON deshizo (`ROLLBACK`) el `UPDATE` que estaba sin confirmar.

**8. Valor de common_user_prefix y su implicación (Parte D)**
En `20261118T180647Z_03-cuenta-app.script.log`, el parámetro `common_user_prefix` tiene el valor `C##`. Esto obliga a que cualquier cuenta común que se cree desde `CDB$ROOT` empiece por ese prefijo (como ocurre con `C##OPS_RO`), diferenciándola de las cuentas locales de cada PDB.

**9. Tabla de las tres miradas al diccionario (Parte E)**
De acuerdo con los resultados de `20261118T181127Z_04-tres-miradas.script.log`:

| Vista | C##OPS_RO en CDB$ROOT | C##OPS_RO en FREEPDB1 | APP_ACADEMIA en FREEPDB1 |
| :--- | :---: | :---: | :---: |
| **ALL_TABLES** (de `ADMIN_ACADEMIA`) | 0 | 0 | 1 |
| **DBA_USERS** | 37 | 46 | `ORA-00942` |
| **CDB_USERS** | `CON_ID 1`: 37 / `CON_ID 3`: 46 | `CON_ID 3`: 46 | `ORA-00942` |
| **V$DATAFILE** | 16 | 9 | `ORA-00942` |

*Explicación de la diferencia:* Aunque `C##OPS_RO` tiene `CONTAINER_DATA = ALL`, al entrar directamente por el servicio `freepdb1` su visibilidad queda filtrada solo a ese contenedor (`CON_ID = 3`), mostrando únicamente los `9` datafiles y `46` usuarios de la PDB en lugar de los `16` datafiles totales del CDB.

**10. Lecturas lógicas, DB time y relación con DB CPU (Parte E)**
En `20261118T181140Z_04-deltas.script.log`, los 10 recorridos costaron `59` lecturas lógicas por recorrido (`585` en total) y `0,04 s` de `DB time`. Como `DB time` (`0,04 s`) y `DB CPU` (`0,04 s`) coinciden prácticamente al cien por cien, significa que todo el tiempo se empleó trabajando en CPU leyendo bloques desde la caché, sin esperas de disco ni bloqueos.

---

### Partes F–G · Espacio y acceso

**11. Tres medidas de TBS_ACADEMIA_HIST y cuál usar para alertar (Parte F)**
En `20261118T181457Z_05-almacenamiento.script.log`, antes de la carga `TBS_ACADEMIA_HIST` tenía `10 MB` asignados, `3,9 MB` libres dentro de lo asignado y `40 MB` de máximo alcanzable (`MAXSIZE`). Para alertar hay que vigilar el porcentaje sobre el máximo alcanzable (`15,16 %` en `DBA_TABLESPACE_USAGE_METRICS`), ya que los `3,9 MB` libres solo reflejan el espacio antes de que el datafile se autoextienda.

**12. Quién insertó, quién pagó la cuota y por qué no bastaba ampliar el tablespace (Parte F)**
En `20261118T181457Z_05-almacenamiento.script.log`, quien lanzó el `INSERT` fue `SYS`, pero quien pagó el espacio fue `CARGA_HIST`, al ser el dueño del segmento (`CARGA_HIST.REGISTRO`). Ampliar el tablespace no habría resuelto el `ORA-01536` porque al tablespace le sobraba sitio; el bloqueo venía de la cuota de `2 MB` fijada al usuario propietario.

**13. Carga reanudable y evidencia en el alert log (Parte F)**
En `20261118T181500Z_05-resumable.script.log`, la sesión `carga-historico` quedó en estado `SUSPENDED` con un timeout configurado de `180 s` (unos 12–14 segundos reales hasta que se amplió la cuota a `30 MB`). Oracle dejó rastro en `alert_FREE.log` con las entradas `FREEPDB1(3):statement in resumable session 'carga-historico' was suspended due to ORA-01536...` y su posterior `was resumed`.

**14. Antes y después de SHRINK SPACE (Parte F)**
En `20261118T181519Z_05-hwm-shrink.script.log`:
- **Antes del DELETE:** `20 000` filas, `2 944` bloques y `23 MB`.
- **Tras el DELETE (90 % borrado):** `2 000` filas, manteniendo los mismos `2 944` bloques y `23 MB`.
- **Tras SHRINK SPACE:** `2 000` filas compactadas en `304` bloques y `2,4 MB` de cuota usada.
Un `DELETE` normal no devuelve espacio porque vacía registros dentro de los bloques asignados, pero no compacta las filas ni baja la marca de agua alta (HWM).

**15. Perfil DEFAULT frente a PRF_PERSONAS (Parte G)**
En `20261118T182006Z_06-gobierno-acceso.script.log`, el perfil `DEFAULT` tenía `FAILED_LOGIN_ATTEMPTS = 10` y `PASSWORD_VERIFY_FUNCTION = NULL`. Para una cuenta nominal como `ANA_GARCIA`, `PRF_PERSONAS` justifica fijar `FAILED_LOGIN_ATTEMPTS = 3` (bloquea rápido ante intentos de fuerza bruta) y `PASSWORD_VERIFY_FUNCTION = ora12c_verify_function` (impide claves débiles como `"corta"`, que dio `ORA-28003`).

**16. Privilegio de esquema y error de columna de Ana García (Parte G)**
En `20261118T182009Z_06-probar-acceso.script.log`, Ana pudo consultar `ACA_MATRICULAS` porque su rol `ROL_SECRETARIA_ACADEMIA` hereda `ROL_LECTURA_ACADEMIA`, que posee el privilegio de esquema `SELECT ANY TABLE ON SCHEMA admin_academia`. Al intentar modificar el nombre de un estudiante recibió `ORA-41900: missing UPDATE privilege on "ADMIN_ACADEMIA"."ACA_ESTUDIANTES"`, ya que solo tiene permiso de actualización sobre la columna `ESTADO`.

---

### Partes H–I · Objetos, diagnóstico y guardia

**17. Invalidaciones en los tres cambios de columna (Parte H)**
En `20261118T182349Z_07-objetos.script.log`: al añadir `telefono` no se invalidó ningún objeto gracias a las dependencias de grano fino (ninguna vista usaba esa columna); al ampliar `email_institucional` pasó a `INVALID` únicamente `V_CONTACTO_LAB6`; y al ampliar `nombres` se invalidaron `V_ACTIVOS_LAB6` y, en cascada, la función `F_TOTAL_ACTIVOS_LAB6` que depende de dicha vista.

**18. Advisors de SGA y PGA (Parte H)**
Según `20261118T182406Z_07-memoria.spool.log`, duplicar la SGA (de `1536 MB` a `3072 MB`, factor `2`) mantiene `ESTD_DB_TIME_FACTOR = 1` y `ESTD_PHYSICAL_READS = 24513`, por lo que no mejoraría el `DB time`. En cuanto a la PGA, por debajo de `384 MB` (a partir de `256 MB`, factor `0.5`) ya aparecen sobreasignaciones (`OVERALLOC = 3` y el porcentaje de acierto cae al `66 %`).

**19. Lecturas lógicas de la consulta en la traza (Parte H)**
En `20261118T182414Z_07-adr-trazas.script.log`, la consulta necesitó `247` lecturas lógicas. Lo indican tanto el campo `cr=247` de la línea `FETCH #...` de la traza en bruto como el valor `247` en la columna `query` de la fila `Fetch` del informe `tkprof`.

**20. Resumen de los tres incidentes de guardia (Parte I)**
- **INC-601:** Evidencia de `SID 57` reteniendo bloqueo `TX` sobre `ACA_ESTUDIANTES` (`20261118T182823Z_08-diagnostico.script.log`); intervención con `ALTER SYSTEM KILL SESSION '57,35598' IMMEDIATE` (y `'59,10369'`); validación con `0` bloqueos y alumno 101 en `ACTIVO`.
- **INC-602:** Evidencia de servicio `academia_app` con `ARRANCADO = NO` (`20261118T184145Z_08-diagnostico-inc2.script.log`); intervención con `DBMS_SERVICE.START_SERVICE('academia_app')`; validación activo en `V$ACTIVE_SERVICES`.
- **INC-603:** Evidencia de cuenta `APP_ACADEMIA` en estado `LOCKED` manual (`20261118T184802Z_08-diagnostico-inc3.script.log`); intervención con `ALTER USER app_academia ACCOUNT UNLOCK`; validación en `DBA_USERS` con `ACCOUNT_STATUS = OPEN`.

---

## 2. Simulacro de examen 1Z0-182

- **S1:** B (Parte B)
- **S2:** C (Parte C)
- **S3:** B (Parte C)
- **S4:** B y C (Parte C)
- **S5:** C (Parte C)
- **S6:** B (Parte C)
- **S7:** A (Parte D)
- **S8:** B (Parte D)
- **S9:** C (Parte D)
- **S10:** C (Parte D)
- **S11:** B (Parte E)
- **S12:** A y C (Parte E)
- **S13:** B (Parte F)
- **S14:** A y C (Parte F)
- **S15:** A y C (Parte F)
- **S16:** B (Parte F)
- **S17:** B (Parte G)
- **S18:** B (Parte G)
- **S19:** A y B (Parte H)
- **S20:** B (Parte H)
- **S21:** C (Parte H)
- **S22:** C (Parte I)
