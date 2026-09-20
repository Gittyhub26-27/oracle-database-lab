# Laboratorio 1: Git Fundamentals - Respuestas de Comprobación

**Alumno:** Bruno C  
**Asignatura:** Administración de Bases de Datos  
**Curso académico:** 2026-2027  

---

## 1. Preguntas de comprobación

### 1. ¿Cuál es la diferencia entre Working Directory, Staging Area y Local Repository? Da un ejemplo de un archivo pasando por las tres.
* **Working Directory:** Directorio donde se editan los archivos y donde se trabaja.
* **Staging Area:** Es donde preparamos y seleccionamos qué cambios queremos hacer y preparar para que sean incluidos en la siguiente confirmación.
* **Local Repository:** Lugar donde se almacenan los commits de forma permanente. Es además una base de datos interna.

**Ejemplo de flujo:**
1. Creamos un archivo cualquiera (en el *working directory*).
2. Ejecutamos `git add <nombre>`, para que pase a la bandeja de salida (*staging area*), a la espera de que se ejecute la instrucción de envío. En este lugar aún se pueden añadir más archivos para el commit.
3. Se ejecuta `git commit` (recomendable con mensaje `-m "mensaje"`) y entonces el archivo o archivos que estaban en la bandeja pasan a guardarse en el historial del repositorio local (*local repository*).

---

### 2. Si modificas un archivo pero no haces git add, ¿aparece ese cambio en tu próximo commit? Explica por qué.
Como se ha comentado en el punto 1, no se incluirá. El comando `add` lo que hace es añadir a "pendientes" de subida o bandeja, esperando al `git commit`. Sólo haciendo un commit (poniendo el archivo antes en `add`) se registrarán los cambios en dicho commit.

---

### 3. ¿Por qué git status no mostraba las carpetas vacías que creaste en la Parte C? ¿Qué truco usamos para solucionarlo?
Git sólo registra y administra cambios en archivos. Una carpeta completamente vacía no tiene archivos, por lo que no se muestra en el estado. El truco consiste en meter un archivo vacío dentro (por convención llamado `.gitkeep`) para que así sea detectada y visionada por Git.

---

### 4. Explica con tus palabras qué es HEAD.
Es el puntero interno de Git que nos indica exactamente en qué commit o rama nos encontramos trabajando en ese momento. Es fundamental para saber en qué contexto estamos operando.

---

### 5. ¿Qué diferencia hay entre crear una branch con git switch -c y crear una carpeta nueva con mkdir? ¿Cómo lo comprobamos en la Parte G?
`mkdir` (*make directory*) crea un directorio físico en el disco, mientras que `git switch -c` crea y cambia a una rama nueva de control de versiones, sin duplicar ni crear carpetas físicas nuevas.
Como indica la práctica, al ejecutar `ls -la` comprobamos que se muestran exactamente las mismas carpetas y archivos que antes, ya que una rama no es una carpeta física.

---

### 6. Durante el conflicto de la Parte H, ¿qué representaba el contenido entre <<<<<<< HEAD y =======? ¿Y entre ======= y >>>>>>>?
* **Entre `<<<<<<< HEAD` y `=======`:** Hace referencia a los cambios de la versión de la rama actual en la que estás posicionado.
* **Entre `=======` y `>>>>>>>`:** Hace referencia a los cambios que proceden de la rama externa que se quiere fusionar.

---

### 7. ¿Por qué NO se debe hacer git commit --amend sobre un commit que ya se subió con git push?
Porque modifica y reescribe el historial local generando un nuevo hash y destruyendo el anterior. En el momento en que el commit viejo ya se había compartido o subido, se rompen las referencias compartidas, provocando divergencias e historiales incompatibles que arruinan el control de versiones en equipo.

---

### 8. Si borras por accidente la carpeta .git de tu proyecto, ¿qué se pierde exactamente? ¿Se pierde también el código fuente que está en el disco?
El código fuente en el disco no se pierde, pero el directorio deja de ser un repositorio Git. Se pierde por completo todo el historial de commits, las ramas, los registros y la *Staging Area*.

---

### 9. Explica con tus palabras la diferencia entre Git y GitHub, sin usar la palabra "nube".
Mientras que Git es el software de control de versiones que se ejecuta de forma local en tu propia máquina para gestionar el historial de un individuo, GitHub es una plataforma web externa diseñada para alojar repositorios y permitir que equipos enteros colaboren en el mismo proyecto sin pisar el trabajo de los demás.

---

### 10. ¿Por qué no se debe subir un archivo .env con contraseñas reales a un repositorio, aunque el repositorio sea privado?
Un archivo `.env` (*environment file*) contiene variables de entorno, contraseñas y credenciales sensibles en texto plano. Si se suben a un repositorio remoto, corren el riesgo de quedar expuestas ante brechas de seguridad, errores de configuración de privacidad o si se comprometen las credenciales de acceso de la cuenta.

---

### 11. Un compañero te dice: "hice push y ahora GitHub me rechaza el segundo push con 'non-fast-forward'". ¿Qué ha ocurrido probablemente y qué comando ejecutarías primero?
Significa que el repositorio remoto tiene commits nuevos que no están sincronizados en tu copia local (por ejemplo, cambios hechos por otro compañero o directamente en la interfaz web). El comando que ejecutarías primero para integrar esos cambios es `git pull`.

---

### 12. ¿Qué tipo de Conventional Commit (feat, fix, docs, test…) usarías para: añadir un índice de rendimiento a una tabla, corregir una restricción mal definida, y actualizar el README?
* **perf:** Para añadir un índice de rendimiento a una tabla.
* **fix:** Para corregir una restricción mal definida.
* **docs:** Para actualizar el archivo README.