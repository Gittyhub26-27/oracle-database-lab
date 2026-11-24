# Guardia nocturna · Lab 6 · E008

## INC-601 · Bloqueo de fila en ACA_ESTUDIANTES al guardar ficha
- **Detección:** A las 18:27 UTC del 18 de noviembre de 2026, Ana García, del dpto. de secretaría, reporta que la ficha del alumno 101 en `FREEPDB1` se queda "colgada".
- **Impacto:** Afectó a las sesiones de secretaría (`SID 219` y `SID 220`) y a la sesión de matrículas (`SID 59`), que se quedaron esperando en `enq: TX - row lock contention`.
- **Diagnóstico:** Usando `08-diagnostico.sql` (`20261118T182823Z_08-diagnostico.script.log`), se comprobó en modo solo lectura que la sesión `SID 57, SERIAL# 35598` retenía un bloqueo exclusivo de transacción sobre `ACA_ESTUDIANTES`, parada en `PL/SQL lock timer`, con solo `USED_UBLK=1` y `USED_UREC=1` en `V$TRANSACTION`. Tras cerrarla, su sesión compañera `SID 59, SERIAL# 10369` heredó el bloqueo (`20261118T184145Z_08-diagnostico-inc2.script.log`).
- **Causa raíz:** El proceso `cierre-periodo` dejó una transacción abierta modificando la fila sin hacer `COMMIT` ni `ROLLBACK` mientras esperaba en un temporizador.
- **Intervención:** Se terminaron ambas sesiones bloqueadoras con `ALTER SYSTEM KILL SESSION '57,35598' IMMEDIATE` y `ALTER SYSTEM KILL SESSION '59,10369' IMMEDIATE` (deshaciendo de esta forma solo 1 registro de undo, sin reiniciar la base).
- **Validación:** Se comprobó que `blocking_session IS NOT NULL` quedó en `0` y el estado del alumno 101 en `ACTIVO`.
- **Acción preventiva:** Configurar *timeouts* cortos en transacciones interactivas del módulo `matriculas` y evitar esperas usando `SLEEP` con transacciones abiertas.

---

## INC-602 · Servicio academia_app caído (ORA-12514)
- **Detección:** A las 18:30 UTC, el dpto. de matrículas reporta que ninguna instancia de la aplicación logra conectar y recibe `ORA-12514`.
- **Impacto:** Indisponibilidad total del acceso de la aplicación de matrículas a `FREEPDB1`.
- **Diagnóstico:** Leyendo `20261118T184145Z_08-diagnostico-inc2.script.log` (apartado 6) se vio que `FREEPDB1` seguía abierta, por lo que la base no estaba caída, pero el servicio `academia_app` tenía `ARRANCADO = NO` y el *listener* no lo anunciaba.
- **Causa raíz:** El servicio `academia_app` estaba definido en el diccionario, pero detenido en memoria.
- **Intervención:** Se arrancó únicamente ese servicio usando `EXEC DBMS_SERVICE.START_SERVICE('academia_app')` dentro de `FREEPDB1`.
- **Validación:** Se verificó en `V$ACTIVE_SERVICES` (`20261118T184604Z_08-resolucion-incidente2.script.log`) que el servicio volvía a estar activo.
- **Acción preventiva:** Ejecutar `ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE` cada vez que se modifique un servicio y añadir comprobación de `V$ACTIVE_SERVICES` en la monitorización.

---

## INC-603 · Cuenta APP_ACADEMIA bloqueada tras script de bajas (ORA-28000)
- **Detección:** A las 18:46 UTC, tras el despliegue nocturno, no se permite autenticarse en la aplicación (`ORA-28000`).
- **Impacto:** Ningún módulo de la aplicación pudo iniciar sesión con su cuenta de servicio (`APP_ACADEMIA`).
- **Diagnóstico:** En `20261118T184802Z_08-diagnostico-inc3.script.log` (apartado 7), se comprobó que `APP_ACADEMIA` estaba en estado `LOCKED` (bloqueo manual a fecha `2026-11-18 18:47`), no `LOCKED(TIMED)` por fallos de contraseña (su perfil `DEFAULT` permite 10 intentos).
- **Causa raíz:** El script trimestral de bajas de personal no filtra las cuentas técnicas de servicio/aplicación y bloqueó `APP_ACADEMIA` por error.
- **Intervención:** Se desbloqueó con `ALTER USER app_academia ACCOUNT UNLOCK` en `FREEPDB1`.
- **Validación:** Se confirmó `ACCOUNT_STATUS = OPEN` en `DBA_USERS` (`20261118T184907Z_08-resolucion-incidente3.script.log`).
- **Acción preventiva:** Excluir explícitamente las cuentas de aplicación del script de bajas o asignarles un perfil específico de cuentas técnicas.
