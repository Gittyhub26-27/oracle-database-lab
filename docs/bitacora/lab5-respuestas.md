# Respuestas y Memoria del Laboratorio 5

## 8. Preguntas de comprobación

### 8.1. Punto de partida y banco de medida (A, B)

1. **Compara el paso 6 de tu copia lab4-final con el de la copia lab3-final. ¿Qué demuestra la diferencia?**
   - *Respuesta:* En el backup del Lab 3 todavía teníamos 5 datafiles desperdigados fuera del volumen principal. En cambio, al revisar la salida de `lab4-final`, vemos el mensaje `ninguno: el volumen contiene toda la base de datos`. Esto confirma que la reubicación de datafiles hacia el volumen persistente que hicimos en el Lab 4 se completó con éxito.
   - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_00-backup-lab4.script.log`

2. **Calcula el factor de bloqueo (bfr) de CLIENTE y de PEDIDO con sus estadísticas. ¿Por me PEDIDO cabe casi el triple de filas por bloque?**
   - *Respuesta:* Para la tabla `CLIENTE`, con un tamaño medio de fila R_BYTES = 98 B, obtenemos $bfr = \lfloor 8028 / 98 \rfloor = 81$ (en la práctica se midieron 68 filas/bloque). Para `PEDIDO`, con R_BYTES = 32 B, nos da $bfr = \lfloor 8028 / 32 \rfloor = 250$ (medidas 188 filas/bloque). La razón por la que en `PEDIDO` entra prácticamente el triple de registros por bloque es puramente física: sus filas ocupan 32 bytes de media frente a los 98 bytes de `CLIENTE`.
   - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_01-perfil-tiendasur.script.log`

3. **¿Por qué el banco de medida ejecuta cada sentencia dos veces y mide solo la segunda?**
   - *Respuesta:* Porque el primer disparo incluye la penalización del análisis sintáctico (*parse*) y la carga inicial de datos y diccionario en la caché. Medir únicamente la segunda ejecución nos garantiza registrar métricas "en caliente", evaluando el coste real en memoria sin el sesgo de la E/S física inicial.
   - *Evidencia:* `scripts/lab5/01-herramienta-medir.sql`

---

### 8.1.1. Anatomía y tipos de índice (C, D)

4. **Con tu evidencia 02: altura, número de hojas y factor de ramificación (fan-out) real de IX_PED_CLIENTE. ¿Qué altura tendría con mil millones de filas?**
   - *Respuesta:* `IX_PED_CLIENTE` cuenta actualmente con una altura de 3, 2216 bloques de hoja y un factor de ramificación (*fan-out*) medio real de 370 (con un máximo de 543). Si la tabla creciera hasta los $1.000.000.000$ de filas, la altura del árbol apenas subiría a 5 (necesitando 6 lecturas lógicas para recuperar una fila: 5 accesos a bloques de índice más 1 a la tabla).
   - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_02-anatomia-indice.script.log`

5. **En el volcado de la hoja de PK_CLIENTE, localiza una entrada y descompón el ROWID que guarda en bloque y fila. ¿Por qué no aparece el número de archivo?**
   - *Respuesta:* La entrada `row#0` expone el valor interno `data: (6): 00 00 03 1b 00 00`, lo que equivale al número de bloque $0\times31B = 795$ y al slot `0`. No se guarda el número de datafile porque la tabla se aloja en un tablespace tipo BIGFILE; al constar de un único archivo de datos gigante, la dirección de bloque de 4 bytes es unívoca en todo el segmento.
   - *Evidencia:* `docs/bitacora/lab5/evidencia/config/*_02-volcado-indice.trc.txt`

6. **Elige tres pruebas de la Parte D y explica, con las lecturas lógicas medidas, por qué un tipo de índice gana al otro.**
   - *Respuesta:*
     - **Q13 (Consulta por DNI):** Pasa de requerir 1436 lecturas lógicas con un escaneo completo (`FULL SCAN`) a tan solo 3 lecturas usando `UX_CLI_DNI` (`INDEX UNIQUE SCAN`), añadiendo además el control de unicidad a nivel de motor (ORA-00001).
     - **Q7 (Historial de pedidos):** Baja de 15 lecturas con `IX_PED_CLIENTE` a solo 3 lecturas lógicas al utilizar el índice cubriente `IX_PED_CLI_FEC_CUB`, evitando por completo visitar la tabla (`TABLE ACCESS`).
     - **Q12 (Pedidos pendientes):** El índice parcial `IX_PED_PENDIENTES` (basado en una columna virtual) necesita 239 lecturas frente a las 246 del índice compuesto `IX_PED_EST_FEC`. Lo decisivo es la huella: ocupa solo 54 hojas frente a las 2933 del compuesto, lo que supone 54 veces menos sobrecarga en escrituras DML.
   - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_03-tipos-indice.script.log`

---

### 8.1.2. Agrupamiento, equilibrio y sargabilidad (E, F)

7. **¿Por qué IX_PED_FECHA tiene un clustering factor cercano al número de bloques e IX_PED_CLIENTE cercano al de filas? ¿Lo arreglaría un REBUILD?**
   - *Respuesta:* `IX_PED_FECHA` presenta un *Clustering Factor* (CF) de 5220 (muy próximo a los 5320 bloques totales) debido a que los datos se insertaron físicamente siguiendo el orden cronológico. En `IX_PED_CLIENTE`, el CF se dispara a 999041 (cercano al millón de filas) porque las claves de cliente quedaron dispersas al azar. Hacer un `REBUILD` del índice no soluciona nada, ya que el CF mide la disposición de las filas dentro de la tabla, no la salud interna del índice.
   - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_04-agrupamiento-equilibrio.script.log`

8. **Según tu curva de la Parte E, ¿a partir de qué porcentaje deja de compensar cada índice? Compáralo con la fórmula de la Unidad 3.**
   - *Respuesta:* En el índice de mal agrupamiento (`IX_PED_CLIENTE`), el acceso por índice deja de ser rentable entre el 0.1% y el 0.2% de los registros, pasando a costar más que una lectura completa a partir del 1%. Esto encaja con la fórmula teórica: $k/r < (1/bfr) \cdot (c_{sec}/c_{aleat}) = (1/188) \cdot (1/5) = 0.11\%$. Por contra, en el índice de buen agrupamiento (`IX_PED_FECHA`), resulta más eficiente acudir al índice casi hasta alcanzar el 100% de los datos.
   - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_04-agrupamiento-equilibrio.script.log`

9. **Explica por qué Q4b ('Gonz%') usa el índice y aun así lee más bloques que un recorrido completo.**
   - *Respuesta:* La condición `LIKE 'Gonz%'` es sargable porque permite buscar por prefijo en la estructura B-tree. El problema es que al recuperar el 2.1% de la tabla (2024 filas) sobre un índice con pésimo agrupamiento, el motor realiza 2024 lecturas aleatorias a disco para traer esos bloques, mientras que un *Full Table Scan* lee la tabla entera de forma secuencial y en bloques multientrada ocupando solo 1472 lecturas.
   - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_05-sargabilidad.script.log`

---

### 8.1.3. Coste de escritura y mantenimiento (G, H)

10. **Con tu evidencia 06: bloques modificados por INSERT con 4, 9 y 5 índices. ¿Qué índices de la propuesta del compañero rechazaste y con qué dato?**
    - *Respuesta:* En el escenario inicial con 4 índices, cada `INSERT` modificaba 10.1 bloques/fila. La propuesta pesada del compañero (9 índices) elevaba ese coste a 20.2 bloques/fila, mientras que con nuestro diseño `V005` (5 índices) se ajustó a 12.2 bloques/fila. Descartamos `IX_PED_CANAL` por su mala selectividad (solo 3 valores), `IX_PED_ESTADO` por abarcar 4 valores (mejor resuelto con un índice parcial) e `IX_PED_FEC_CLI` por ser redundante al compartir prefijo con `IX_PED_FECHA`.
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_06-indices.script.log`

11. **Distingue, con tus gráficos de la Parte H, un índice con divisiones 50/50, uno con divisiones 90/10 y uno con patrón cola.**
    - *Respuesta:*
      - **División 50/50 (`IX_AZAR`):** Las claves aleatorias provocan que las hojas se partan por la mitad; la densidad se concentra entre el 60-80% y el mapa muestra un patrón uniforme de `=` y `-`.
      - **División 90/10 (`IX_CRECIENTE`):** Las claves consecutivas llenan las hojas al 100% (representadas con `#`) y van abriendo bloques nuevos en el extremo derecho.
      - **Patrón cola (`IX_COLA`):** Inserciones por la derecha combinadas con borrados por la izquierda dejan el lateral izquierdo del mapa con bloques totalmente vacíos (`.`) mientras el lado derecho permanece saturado (`#`).
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_07a-grafico-*.script.log` y `*_07b-grafico-*.script.log`

12. **¿Qué remedio elegirías para el patrón cola en producción, en horario de servicio, y por qué?**
    - *Respuesta:* La opción ideal es `ALTER INDEX ... COALESCE`. Trabaja 100% en línea, no requiere espacio extra en disco, no aplica bloqueos exclusivos sobre la tabla y compacta al instante las hojas vacías del extremo izquierdo, reduciendo las lecturas de consulta de 253 a solo 2.
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_07c-remedios.script.log`

---

### 8.1.4. SCN, control files, redo y FRA (I a L)

13. **Con tu evidencia 08: ¿qué valores compara Oracle al abrir para decidir si hace falta recuperación?**
    - *Respuesta:* Revisa el valor de `checkpoint_change#` registrado en la sección de datafiles del *control file* (`v$datafile`) y lo contrasta con el `checkpoint_change#` escrito en la cabecera de cada archivo físico (`v$datafile_header`). Si todos coinciden tras un apagado limpio, la base de datos se abre de inmediato.
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_08-scn-checkpoint.script.log`

14. **¿Qué protege la multiplexación del control file en el mismo volumen y qué no? ¿Cómo se haría en producción?**
    - *Respuesta:* Multiplexar dentro del mismo volumen únicamente nos aísla frente al borrado accidental o la corrupción lógica de un archivo `.ctl` puntual. No ofrece protección si cae el volumen o el disco físico subyacente. En producción, cada réplica debe alojarse en discos y controladoras independientes (o en grupos ASM con redundancia).
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_09-multiplexar-controlfile.script.log`

15. **Explica los estados CURRENT, ACTIVE e INACTIVE con tu evidencia 10 y por qué Oracle rechaza los tres borrados del paso 4.**
    - *Respuesta:* `CURRENT` identifica el grupo activo donde escribe LGWR; `ACTIVE` guarda cambios cuyo volcado a disco por checkpoint todavía no ha finalizado; `INACTIVE` señala que todos sus bloques sucios ya están consolidados en datafiles. Oracle bloquea los borrados porque prohíbe eliminar el grupo `CURRENT` (ORA-01623), un miembro del grupo `CURRENT` en uso (ORA-01609) o dejar la instancia con menos de 2 grupos de redo en total (ORA-01567).
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_10-redo.script.log`

16. **Describe la cadena de causas del escenario de la FRA llena, desde ORA-19815 hasta que la base deja de aceptar cambios.**
    - *Respuesta:* 1) Al llegar al 100% del límite `db_recovery_file_dest_size`, salta la alerta ORA-19815 en el alert log. 2) El proceso ARCn queda incapacitado para generar nuevos archivos de redo archivado, arrojando errores ORA-19809/ORA-16038. 3) LGWR agota los *online redo logs* y no encuentra ningún grupo liberado al que conmutar, entrando en la espera `log file switch (archiving needed)`. 4) Toda la actividad DML se congela y los intentos de conexión responden con ORA-00257.
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_11-fra-llena.script.log`

---

### 8.1.5. Undo, WAL y simulacros (M a P)

17. **Explica, con los pasos 1 a 4 de tu evidencia 12, la frase "lectores no bloquean a escritores".**
    - *Respuesta:* En el paso 1, aunque la Sesión A mantenía modificada la fila 101 sin haber hecho COMMIT, la Sesión B pudo leer la fila en paralelo sin bloquearse (recuperando el estado anterior `ACTIVO` mediante los segmentos de undo). En cambio, en el paso 4, cuando la Sesión B intentó lanzar un `FOR UPDATE` sobre esa misma fila, quedó inmediatamente bloqueada con ORA-00054 (evidenciando que solo los escritores bloquean a otros escritores).
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_12-lectura-consistente.script.log`

18. **¿Por qué un DELETE genera más undo que un INSERT? ¿Por qué el ROLLBACK también genera redo?**
    - *Respuesta:* Un `INSERT` solo necesita registrar en el undo la operación de borrado de ese ROWID (141 bloques/10k filas). Por el contrario, un `DELETE` debe respaldar la fila completa con todos sus datos e entradas de índice para poder reconstruirla si es necesario (427 bloques). El `ROLLBACK` genera redo porque la operación de deshacer aplica cambios reales sobre la base de datos, y según el principio WAL, todo cambio en bloques de datos o undo debe quedar protegido en el diario de redo.
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_12-undo-y-redo.script.log`

19. **Con tu evidencia 13: ¿dónde está la garantía de durabilidad justo después del COMMIT y después del checkpoint?**
    - *Respuesta:* Inmediatamente después de ejecutar el COMMIT, la garantía de durabilidad descansa en el **redo log online** (LGWR ya ha volcado el buffer de redo a disco). Una vez ejecutado el checkpoint, la durabilidad se traslada de forma definitiva a los **datafiles** (DBWn ha volcado a disco los 231 bloques de datos que estaban en memoria).
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_13-lgwr-dbwn.script.log`

20. **Simulacro A: explica roll forward y roll back con las filas 102 y 103 y las líneas del alert log.**
    - *Respuesta:* Al reiniciar tras el `SHUTDOWN ABORT`, el proceso SMON arrancó el `Beginning crash recovery`. Primero completó la fase de *roll forward* aplicando el redo a partir del último SCN de checkpoint, reconstruyendo tanto la transacción confirmada (102) como la pendiente (103). Seguidamente ejecutó la fase de *roll back* apoyándose en el undo para revertir los cambios no confirmados de la fila 103 (restaurándola a `ACTIVO`), mientras que la fila 102 conservó su cambio a `EGRESADO`.
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_14a-caida-instancia.script.log`

21. **Simulacros C y D: tu RTO y tu RPO en cada uno. ¿Por qué son tan distintos?**
    - *Respuesta:*
      - **Simulacro C (Borrado de tabla):** Registró un RTO = 53 s y un RPO = 2 s (al requerir la restauración de todo el volumen completo de la base de datos).
      - **Simulacro D (Pérdida de datafile):** Consiguió un RTO = 9 s y un RPO = 0 s (al restaurar y aplicar *recover* exclusivamente sobre el archivo `academia01.dbf` mediante RMAN y redo archivado).
      - *Explicación:* El Simulacro C fuerza una restauración total de la base de datos sin importar el tamaño del impacto, mientras que el Simulacro D ejecuta una recuperación de medios (*media recovery*) selectiva y en línea sobre el archivo dañado, manteniendo operativa la base de datos.
    - *Evidencia:* `docs/bitacora/lab5/evidencia/script/*_14c-simulacro-restauracion.script.log` y `*_14d-perdida-datafile.script.log`

22. **Clasifica cada error ORA- del bloque 5 de tu runbook: incidente real, efecto del laboratorio o ruido conocido.**
    - *Respuesta:*
      - `ORA-63999` y `ORA-01113` / `ORA-01110`: Efectos esperados del laboratorio (derivados de la simulación de pérdida del datafile `academia01.dbf` durante el Simulacro D).
      - `ORA-20013`: Ruido conocido del entorno (causado por la ejecución de scripts del paquete `DBMS_QOPATCH` en la infraestructura de contenedores).
    - *Evidencia:* `docs/bitacora/lab5/evidencia/spool/*_15-healthcheck.spool.log`
