Cuestionario de Laboratorio: Docker, Git, Seguridad y Oracle

8.1.1. Docker

1. ¿Qué diferencia hay entre una imagen y un contenedor? Usa como ejemplo lo que hiciste en los ejercicios G2 y G4.

Una imagen es básicamente la plantilla , mientras que el contenedor es esa imagen pero ya ejecutándose, con una capa de escritura encima. Por ej, en el ejercicio G2 se descarga la imagen de Oracle o de Ubuntu, y en el G4 se ejecuta esa imagen creando el contenedor oralab-26ai, que ya era una instancia donde se puede interactuar, guardar cosas o lanzar comandos.


2. En el Ejercicio G5 el archivo nota.txt desapareció y en el G6 no. Explica por qué.

Se basa en el dónde se guardan las cosas. En G5, el archivo se crea dentro de la capa efímera del contenedor, así que al destruirlo o apagarlo de cierta forma, desaparece. En cambio, en el G6 los datos viven en el disco de la máquina física, en el host y no dentro de la vida útil del contenedor.


3. ¿Qué diferencia hay entre docker ps y docker ps -a, y qué significa STATUS = Exited (0)?

- docker ps muestra únicamente los contenedores que están vivos & corriendo en ese preciso instante. 
- docker ps -a enseña absolutamente todos, incluidos los que ya se apagaron (y el instante de tiempo)
- Exited (0) significa que el contenedor ya finalizó la ejecución. (0) indica que ha finalizado corrctamente.


4. En -p 8181:8181, ¿qué número corresponde a tu equipo y cuál al contenedor? ¿Qué pasaría con -p 80:8080 en el ejercicio de nginx?

- 8181 es el puerto del pc 
- 818) es el puerto interno donde escucha el contenedor. Con -p 80:8080, se enlaza el puerto 80 del PC con el 8080 de Nginx, se entraría con http://localhost (que usa el 80 por defecto) y te redirige al servicio web del contenedor en el 8080.


5. ¿Por qué un contenedor de Oracle se queda en marcha y el de hello-world termina solo?

Porque depende del proceso principal que llevan dentro. El de hello-world simplemente imprime un texto por pantalla y el proceso muere al instante, haciendo que el contenedor apague su motor. 
En el de Oracle, se levanta una base de datos entera con servicios de escucha y procesos en segundo plano que se quedan escuchando conexiones indefinidamente, por lo que el contenedor se mantiene activo hasta que se decidas pararlo.


6. ¿Qué es el digest de una imagen y por qué lo registramos si ya sabemos que usamos :latest?

El digest es una huella digital única (SHA-256). Aunque uses la etiqueta :latest, esa etiqueta puede cambiar mañana si el creador sube una versión nueva y se machaca la anterior.
Registrar el digest te garantiza reproducibilidad absoluta: sabes exactamente que se ha utilizado el mismo, sin modificación alguna.


7. ¿Qué comando borraría realmente los datos de Oracle? ¿Por qué docker rm oralab-26ai no lo hace?

Para borrar los datos de verdad habría que eliminar el volumen asociado con docker volume rm.
El comando docker rm oralab-26ai solo borra el contenedor en sí, es decir, la carcasa y su capa de escritura temporal, pero no elimina los volúmenes persistentes para que no pierdas la base de datos.



8.1.2. Git, organización y evidencia

8. ¿Por qué este laboratorio se hace dentro del repositorio oracle-database-lab, con Issue, branch y Pull Request, en vez de en una carpeta aparte?

Se simula un flujo de trabajo profesional y colaborativo de desarrollo de software (GitFlow/GitHub Flow). Trabajar con Issues, ramas específicas y Pull Requests deja una trazabilidad limipa de qué problema se resuelve, qué código tocaste y quién lo revisó, alejándose de los errores de versión: v2_final_final3.zip


9. ¿Qué diferencia hay entre source 00-config.sh y bash 00-config.sh? ¿Por qué usamos source?

Cuando se usa bash, el script se ejecuta en una subshell aislada. Las variables que declare ahí dentro mueren en cuanto el script se termina. En cambio, source ejecuta el script en el shell actual, lo que permite que las variables de entorno o configuraciones que se carguen, se queden guardadas en tu sesión de terminal para que los siguientes scripts puedan usarlas.


10. Explica cada parte del nombre 20260915T091230Z_02-docker.script.log.

Siguiendo la estandarización de nombres:

20260915: La fecha en formato año, mes y día, que sería 15 de septiembre de 2026

T091230Z: La hora exacta en formato UTC , que sería las 09:12:30 AM, con la 'T' separando fecha de hora y la 'Z' indicando Zulu/UTC.

02-docker: El identificador del bloque.

script.log: Indica que es un fichero de registro .log.


11. ¿Para qué sirve .gitattributes y qué error evita?

Sirve para decirle a Git cómo debe tratar ciertos ficheros, máxime en lo que respecta a los finales de línea, previendo que Git piense que has modificado medio repositorio solo por abrir un fichero en un sistema operativo distinto.


12. ¿Por qué en este Pull Request elegimos Create a merge commit en lugar de Squash and merge?

Porque en un entorno de laboratorio y auditoría nos interesa conservar el historial detallado de los commits que han sido parciales, que se fueron haciendo paso a paso para demostrar cómo se ha construido la solución. El Squash compacta todo en un único commit, lo cual está bien para producción en algunos equipos, pero aquí perderíamos la evidencia del proceso de aprendizaje.


8.1.3. Seguridad

13. Describe las cuatro capas de la estrategia de contraseñas (Parte D) y qué pasaría si te saltas la primera.

1- Variables de entorno/contraseñas
2- Permisos restrictivos en los ficheros de configuración
3- Exclusión mediante .gitignore para no subir bajo ninguna circunstancia, las credenciales al remoto
4- Políticas de complejidad y rotación de claves. Si te saltas la primera (por ejemplo, quemando la contraseña en texto plano en el script), dejas la puerta abierta a que cualquiera con acceso de lectura al fichero vea tus credenciales a la primera de cambio (el historial).


14. ¿Por qué no escribimos la contraseña directamente en el comando docker run, aunque el script no se suba a Git?

Porque cualquier usuario con permisos en la máquina que mire el historial de procesos activos en el  momento en el que se lanza el comando, podrá leer la contraseña en texto plano. Las contraseñas nunca deben viajar como argumentos visibles de comandos si se puede evitar.


15. Si descubres tu contraseña en un commit ya publicado, ¿basta con borrarla en un commit nuevo? ¿Qué debes hacer?

NO. Una vez que un commit suba a un repositorio remoto, esa contraseña ya forma parte del historial de Git y cualquier persona con acceso puede recuperarla usando comandos de recuperación o mirando las versiones anteriores. Hay cambiar la contraseña inmediatamente en el sistema afectado, y luego limpiar el historial de Git si de verdad se necesita purgarla del registro histórico.



8.1.4. Oracle y herramientas

16. ¿Por qué no usamos SPOOL ni @archivo.sql con sqlplus dentro del contenedor, y qué hicimos en su lugar?

Muchas veces, interactuar directamente dentro de contenedores efímeros complica la gestión de ficheros locales. En su lugar, se suele lanzar la ejecución con comandos desde el host hacia el contenedor o utilizando herramientas de migración estructuradas que manejan la conexión y la salida de errores de forma limpia sin depender de sesiones interactivas manuales de sqlplus.


17. ¿Qué hace WHENEVER SQLERROR EXIT SQL.SQLCODE al inicio de V000 y V001, y qué pasaría sin esa línea?

Le indica a la herramienta de base de datos que, en cuanto ocurra el primer fallo SQL, se debe abortar la ejecución inmediatamente y tiene que devolver el código de error.
Si una sentencia de creación de tablas falla en la mitad del script, el motor se la saltaría y se terminaría con una base de datos a medias, generando un estado inconsistente sin que el script te avise de forma explícita.


18. ¿Qué es una migración y por qué V000 y V001 no se deben editar una vez aplicadas?

Una migración es un script versionado que aplica un cambio estructurado y controlado sobre el esquema de la base de datos. No se debe editar una vez aplicado, porque la base de datos ya registró que ese script (con su checksum original) y se ejecutó.
Si se cambia a posteriori, las herramientas de control de versiones de bases de datos detectarán una discrepancia y romperán el despliegue porque el historial ya no cuadra con la realidad del servidor.


19. ¿Por qué en SQL Developer se usa el servicio FREEPDB1 y no FREE ni un SID?

Porque FREE suele ser el nombre de la base de datos contenedora global, mientras que las buenas prácticas de Oracle dictan que las aplicaciones y usuarios se conectan a una base de datos pluggable aislada dentro de ella, que en la edición gratuita,  viene por defecto con el nombre de servicio FREEPDB1.


20. ¿Qué aporta SQLcl frente a SQL*Plus, y por qué un DBA debe dominar ambas?

SQLcl es la evolución moderna basada en Java de SQLPlus: incluye auto-completado, historiales más atractivos, soporte nativo para comandos de JavaScript, además se formatean salidas a JSON o CSV de forma nativa, y un largo etc. Un DBA debe dominar SQLPlus porque viene instalado por defecto en prácticamente cualquier servidor Oracle antiguo o minimalista donde no haya ese tipo de lujos, y SQLcl porque te hace la vida infinitamente más productiva en el día a día.


8.1.5. Entorno de trabajo

21. ¿Por qué el curso pasa de Git Bash a Ubuntu en WSL 2? Da al menos dos problemas concretos de Git Bash que desaparecen en Ubuntu.

Porque Git Bash emula un entorno Linux sobre Windows de forma muy justa y suele dar problemas de rendimiento y compatibilidad con herramientas pesadas.
Problemas:
1- Bloqueos rarosde rutas con barras invertidas (\ vs /) al ejecutar scripts complejos de Docker
2 -La pésima gestión de rendimiento en operaciones masivas de ficheros debido a cómo emula el sistema de archivos de Windows.


22. ¿Por qué clonamos el repositorio en ~/oracle-database-lab y no trabajamos sobre la carpeta de Windows (/mnt/c/...)? ¿Y por qué recomendamos bash frente a zsh para los scripts del curso?

Porque trabajar dentro del sistema de ficheros nativo de Linux en WSL 2 ofrece una velocidad de lectura y escritura superior a hacerlo a través de Windows, lo cual evita fallos raros con permisos de ficheros y volúmenes de Docker. 
Se recomienda bash frente a zsh porque es el estándar universal predeterminado en entornos de serv. corporativos y garantiza que los scripts funcionen exactamente igual para todo el mundo sin sorpresas de sintaxis propia de otras shells.
