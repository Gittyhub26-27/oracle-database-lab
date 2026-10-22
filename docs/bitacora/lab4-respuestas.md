# Respuestas Laboratorio 4 - Oracle DBA Workflow I

## 8. Preguntas de Comprobación

### 8.1.1 Respaldo
1. ¿Por qué la copia de la Parte B es consistente? ¿Qué pasaría si se tomara con la base abierta?
   - Quedó consistente porque lanzamos un SHUTDOWN IMMEDIATE antes de copiar el volumen. Eso asegura que se hizo un checkpoint completo donde todos los datafiles están sincronizados en el mismo SCN y no hay transacciones colgadas en el undo. Si se copiara con la base abierta, la mitad de los bloques quedarían modificados a medias y la copia serviría de poco; tocaría levantarla aplicando redo logs en modo ARCHIVELOG.

2. ¿Para qué sirven manifiesto.txt y SHA256SUMS? ¿Qué comprueba restaurar-estado.sh antes de tocar nada?
   - El manifiesto.txt guarda los datos clave del respaldo (la fecha, el commit de Git, la etiqueta y cómo estaban los archivos). El archivo SHA256SUMS tiene los hashes de cada uno para asegurarnos de que nada esté corrupto. Por eso, antes de hacer cualquier cambio destructivo, el script restaurar-estado.sh corre un sha256sum -c para verificar que la copia está intacta antes de vaciar o borrar el volumen actual.

3. RPO y RTO:
   - RPO: Representa los datos que se perderían si pasa un desastre (en este caso, todo lo que se haya hecho después de respaldar la Parte B).
   - RTO: Es el tiempo que tardamos en recuperar la operación completa usando el script, que suele andar entre los 30 y 60 segundos.

### 8.1.2 Diagnóstico y correcciones
4. ¿Dónde creó Oracle los datafiles de V000 y por qué? ¿Qué parámetro habría evitado el problema?
   - Los mandó directo a rutas relativas dentro de /dbs, que está fuera del volumen persistente. Cuando lanzamos el CREATE TABLESPACE no le dijimos una ruta absoluta y tampoco estaba activo OMF. Con OMF configurado nos hubiéramos ahorrado el dolor de cabeza.

5. ¿Por qué ALTER TABLESPACE ... RENAME DATAFILE no basta para mover un archivo?
   - Porque ese comando solo le avisa al control file que cambió la ruta del archivo en el papel, pero no mueve ni copia físicamente el archivo de un directorio a otro en el sistema operativo. Eso hay que hacerlo a mano o por script.

6. ¿Por qué no se edita V000 y se crea V003? ¿Por qué invalidar una contraseña es mejor que borrarla del archivo?
   - Porque V000 ya se ejecutó y forma parte del historial de Git; modificar migraciones viejas rompe la regla de las migraciones forward-only. Y sobre las contraseñas, invalidarlas con NO AUTHENTICATION deja la cuenta como schema-only (sin acceso directo por login), lo cual es más seguro que andar borrando cosas o dejando credenciales expuestas en texto plano.

7. ¿Qué demuestra la prueba de persistencia y por qué se ejecuta después de reubicar?
   - Básicamente comprueba que si tiramos el contenedor (docker rm), los datos no desaparecen porque están en el volumen. Se hace después de reubicar los datafiles para asegurarnos de que ya están a salvo en la ruta persistente y no atrapados en la capa efímera del contenedor.

### 8.1.3 Instancia y arranque
8. Tres datos de la instancia y tres de la base de datos:
   - Instancia: El nombre (FREE), el estado actual (OPEN) y la hora en que arrancó (STARTUP_TIME).
   - Base de datos: El identificador (DBID), la fecha de creación (CREATED) y el modo de bitácora (LOG_MODE en NOARCHIVELOG).

9. ¿Qué lee Oracle en NOMOUNT, MOUNT y OPEN?
   - NOMOUNT: Lee únicamente el SPFILE o PFILE para levantar la memoria SGA y los procesos. Si intentas consultar v aquí, te tira error porque ni los control files están abiertos.
   - MOUNT: Abre y lee los control files. Ya sabes que si intentas mirar tablas del diccionario como dba_tables, te bota un error porque los datafiles siguen cerrados.
   - OPEN: Abre por fin los datafiles y los redo logs, dejando la base lista para que cualquiera trabaje.

10. ¿Por qué FREEPDB1 se abre sola tras ALTER DATABASE OPEN?
    - Por el comando SAVE STATE que ejecutamos antes (ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE), que guarda la configuración para que Oracle la levante automáticamente.

11. Errores ORA-00800 y ORA-20013 en el alert log:
    - Son avisos clásicos que no afectan mucho en contenedores. El ORA-00800 pasa porque Docker limita ciertos privilegios de prioridades de procesos (CAP_SYS_NICE), y el ORA-20013 es por un rollo al intentar leer parches internos con DBMS_QOPATCH dentro del entorno dockerizado.

### 8.1.4 Parámetros
12. Diferencia entre v y v (ejemplo db_files):
    - v te muestra el valor que está usando la instancia en la memoria ahorita mismo. En cambio, v mira lo que está grabado físicamente en el archivo de parámetros (SPFILE) para el próximo reinicio.

13. ¿Qué hace SCOPE=BOTH y cuál es el SCOPE por defecto?
    - SCOPE=BOTH aplica el cambio al instante en la memoria y de una vez lo guarda en el SPFILE para que persista. Si la base arrancó usando SPFILE, ese BOTH suele ser el comportamiento por defecto al modificar un parámetro.

14. ¿Por qué PROCESSES rechaza el cambio en memoria aunque marque IMMEDIATE?
    - Porque define estructuras estáticas de la SGA que se reservan al arrancar los procesos y no se pueden alterar al vuelo solo porque se antoje.

15. ¿Para qué sirve versionar el PFILE? Explica configuration drift:
    - Tener versiones del PFILE nos da una foto clara y legible de cómo estaba configurada la base en un momento dado. Lo del configuration drift es justo cuando la base real en producción se va desviando poco a poco de esa configuración base ideal sin que nadie lo documente bien.

### 8.1.5 Memoria y procesos
16. Modelo de gestión de memoria de la instancia:
    - Está corriendo con ASMM (Automatic Shared Memory Management); lo ves fácil porque sga_target tiene valor, memory_target está en 0 y pga_aggregate_target maneja la memoria de trabajo privada.

17. Cifras del experimento de caché (08-experimento-cache.sql):
    - En la primera ronda (en frío), tiró de disco con 245 lecturas físicas y 247 lógicas. En la segunda ronda (en caliente), ya todo estaba en RAM, así que dio 0 lecturas físicas (un 100% de acierto en caché).

18. ¿Por qué no se suma el RSS de los procesos para saber la memoria de la instancia?
    - Porque si sumas el RSS de cada proceso por separado vas a terminar contando varias veces la misma memoria compartida (la SGA) que está mapeada en cada uno.

19. SPID de v vs PID de /proc:
    - Apuntan al mismo proceso pero vistos desde mundos distintos. El spid de Oracle es el identificador interno, mientras que el PID que ves en /proc o con docker top es el que le asignó el sistema operativo host.

20. PMON vs SMON:
    - PMON: Se encarga de limpiar las conexiones huérfanas, liberar bloqueos y barrer procesos caídos de usuarios.
    - SMON: Es el que rescata la instancia si hubo un apagón feo y se encarga de limpiar segmentos temporales viejos al arrancar.

### 8.1.6 Seguridad y trabajo profesional
21. ¿Por qué C##OPS_RO y no SYSTEM para observar?
    - Por el principio de privilegios mínimos. No le vas a dar las llaves de la casa a cualquiera; C##OPS_RO solo tiene permisos de lectura (SELECT_CATALOG_ROLE) para auditar sin chance de romper nada con DDL o DML.


22. Dos vías de exposición de contraseñas corregidas:
    - Evitar pasar la contraseña de SYS en texto plano directo en la terminal al correr comandos de docker (/ as sysdba), y quitarle los privilegios de login directo a los dueños de esquemas usando cuentas de solo esquema (NO AUTHENTICATION).

---


