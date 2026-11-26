# CLIMA Y SALUD MÉXICO
### Sistema de integración, migración y análisis de datos climatológicos y epidemiológicos

**Proyecto Final de Base de Datos**  
Universidad Autónoma de Baja California (UABC)  
Campus Otay · 2026

**Integrantes:**
- Zoe Valentina Crespo Dorantes
- Ingrid Engracia Montesinos Jiménez
- Karla Stephanie Aparicio Garduño

---

## DESCRIPCIÓN DEL PROYECTO

Clima y Salud México es un sistema que integra información climatológica y epidemiológica mediante dos modelos de bases de datos: relacional y documental.

Utiliza MySQL para almacenar los datos de origen, MongoDB para su almacenamiento documental y Python para realizar la extracción, transformación y migración de información. Además, incorpora un dashboard desarrollado con Streamlit para consultar indicadores, generar reportes y visualizar resultados.

## PROPÓSITO

Organizar e integrar información climática y de salud para facilitar su almacenamiento, consulta, comparación y análisis mediante diferentes tecnologías de bases de datos.

## OBJETIVO GENERAL

Desarrollar un sistema que permita administrar, migrar, consultar y visualizar datos climatológicos y epidemiológicos de México utilizando MySQL, MongoDB y Python.

## TECNOLOGÍAS UTILIZADAS

| Tecnología | Función |
|---|---|
| Python 3 | Procesamiento y migración de datos |
| MySQL 8 | Base de datos relacional |
| MongoDB 8 | Base de datos documental |
| PyMySQL | Conexión con MySQL |
| PyMongo | Conexión con MongoDB |
| Pandas | Manipulación de datos |
| Streamlit | Interfaz de usuario |
| Plotly | Gráficas y visualizaciones |
| Python-dotenv | Variables de entorno |
| PyCharm | Entorno de desarrollo |

---

# 1. ANÁLISIS

El proyecto aborda la necesidad de organizar e integrar información climatológica y epidemiológica para facilitar su consulta y análisis.

La solución relaciona registros climáticos, información geográfica y datos de salud mediante una estructura que permite consultar casos por enfermedad, municipio, periodo y grupo de edad.

**Propósito del análisis:**
- Identificar los datos necesarios para el sistema.
- Establecer las relaciones entre información geográfica, climática y epidemiológica.
- Definir las consultas e indicadores requeridos.
- Determinar el uso de bases de datos relacionales y NoSQL.

**Flujo general del sistema:**

```text
MYSQL
   |
   v
PYTHON - ETL
   |
   v
MONGODB
   |
   v
STREAMLIT
   |
   v
CONSULTAS, REPORTES Y VISUALIZACIONES
```

# 2. ESTRUCTURA DE LA BASE DE DATOS

El sistema utiliza dos modelos de almacenamiento con el nombre `clima_salud_mx`.

### 2.1 MySQL – Modelo relacional

La base de datos está integrada por nueve tablas:

| Tabla | Función |
|---|---|
| `estados` | Catálogo de estados |
| `municipios` | Información de municipios |
| `estaciones_meteorologicas` | Datos de estaciones climáticas |
| `registros_clima` | Registros climatológicos |
| `unidades_salud` | Unidades de atención médica |
| `enfermedades` | Catálogo de enfermedades |
| `casos_salud` | Casos epidemiológicos y defunciones |
| `resumen_mensual` | Resúmenes estadísticos |
| `auditoria` | Registro de operaciones |

La estructura utiliza llaves primarias, llaves foráneas y restricciones para mantener la integridad de los datos.

### 2.2 MongoDB – Modelo NoSQL

Se utiliza una estructura documental integrada por siete colecciones:

- `estados`
- `municipios`
- `enfermedades`
- `registros_clima`
- `casos_salud`
- `resumen_mensual`
- `auditoria`

Los documentos y subdocumentos permiten organizar información relacionada y facilitar su consulta dentro de MongoDB.

# 3. FUNCIONES, CONSULTAS, REPORTES Y PROCESOS

El sistema contempla consultas y procesos para obtener información estadística y epidemiológica.

**Consultas principales:**
- Casos y defunciones por enfermedad.
- Casos registrados por municipio.
- Distribución mensual de los registros.
- Casos por grupo de edad.
- Totales generales de casos y defunciones.

**Funciones almacenadas:**

| Función | Descripción |
|---|---|
| `fn_temp_promedio(max, min)` | Temperatura promedio del día |
| `fn_nivel_riesgo_calor(temp_max)` | Nivel de riesgo por calor: bajo, moderado, alto o extremo |
| `fn_tasa_letalidad(casos, defunciones)` | Porcentaje de defunciones sobre casos |
| `fn_tasa_100k(casos, poblacion)` | Casos por cada 100,000 habitantes |

**Procedimientos almacenados:**

- **CRUD** para las 7 entidades (`estado`, `municipio`, `estacion`, `registro_clima`, `enfermedad`, `unidad_salud`, `caso_salud`): `sp_<entidad>_crear`, `_leer`, `_listar`, `_actualizar` y `_eliminar`. En `_actualizar`, un parámetro en `NULL` conserva el valor actual.
- **Reportes:** `sp_reporte_clima_por_estado()`, `sp_reporte_casos_por_municipio()` y `sp_reporte_dinamico(estado, categoria, fecha_inicio, fecha_fin)`, donde `NULL` significa "todos".
- **Proceso:** `sp_proceso_resumen_mensual(anio)` recalcula la tabla `resumen_mensual` dentro de una transacción.

Ejemplos de ejecución:

```sql
CALL sp_reporte_dinamico('Sonora', 'golpe_de_calor', NULL, NULL);
CALL sp_municipio_crear(2, 'Ensenada', 443807, @id);
SELECT fn_nivel_riesgo_calor(42.5);
```

El archivo `pruebas_clima_salud.sql` ejecuta todas las funciones y procedimientos.

**Triggers y seguridad:**

- Triggers de auditoría (`INSERT`, `UPDATE`, `DELETE`) en las 7 entidades. La tabla `auditoria` es de solo lectura.
- Triggers de validación que impiden registrar fechas futuras.
- Roles: `rol_administrador` (todo), `rol_analista` (solo lectura y reportes) y `rol_usuario` (captura sin eliminar).

**Procesos del sistema:**
- Conexión con MySQL y MongoDB.
- Extracción y transformación de registros.
- Organización de información por periodo.
- Generación de indicadores y reportes.
- Comparación de resultados entre las bases de datos.

# 4. MIGRACIÓN, ESTRUCTURA NoSQL Y VALIDACIÓN

**Archivo principal:** `Migracion_clima_salud.py`

Se utiliza Python para realizar el proceso ETL, que permite transferir información desde MySQL hacia MongoDB.

### Etapas de migración

| Etapa | Descripción |
|---|---|
| Extracción | Consulta de registros en MySQL |
| Transformación | Organización y relación de datos |
| Agrupación | Consolidación de información por periodo |
| Conversión | Transformación de registros en documentos |
| Carga | Inserción de documentos en MongoDB |
| Validación | Comparación de resultados entre ambas bases |

### Validación NoSQL

Se consideran los siguientes criterios:

- Comparación de totales de casos.
- Correspondencia entre documentos preparados y almacenados.
- Verificación de campos obligatorios.
- Detección de identificadores duplicados.
- Comprobación de que las defunciones no superen los casos.

### Resultados de validación

| Indicador | Resultado |
|---|---:|
| Registros consultados en MySQL | 4,300 |
| Documentos preparados | 1,183 |
| Documentos almacenados en MongoDB | 1,183 |
| Casos en MySQL | 37,231 |
| Casos en MongoDB | 37,231 |
| Defunciones (MySQL y MongoDB) | 249 |
| Diferencia de casos | 0 |

*Resultados con `climasalud.sql` recién cargado. La migración compara los totales de MySQL y MongoDB al terminar, y si no coinciden se detiene con error. También elimina de MongoDB los documentos que ya no existen en MySQL.*

**Nota sobre los datos:** las tablas de MySQL se llenan con datos sintéticos de 2025, generados por `climasalud.sql` con patrones realistas de temperatura y lluvia por ciudad. Los datos reales descargados (Open-Meteo y datos abiertos de dengue 2023) se encuentran procesados en `data/processed/`.

# 5. PRESENTACIÓN DEL SISTEMA (UI) Y CIERRE

**Archivo principal:** `dashboard.py`

El dashboard desarrollado con Streamlit permite consultar información y visualizar los indicadores del proyecto.

| Módulo | Funcionalidad |
|---|---|
| Inicio | Indicadores generales |
| Enfermedades | Casos por enfermedad |
| Municipios | Distribución de casos |
| Análisis mensual | Comportamiento por periodo |
| Grupos de edad | Distribución epidemiológica |
| Información climática | Consulta de registros climatológicos |
| Bases de datos | Comparación entre MySQL y MongoDB |

Plotly permite representar los resultados mediante gráficas para facilitar su interpretación.

### Conclusión

El proyecto integra bases de datos relacionales y documentales mediante un proceso ETL desarrollado en Python. Permite organizar, migrar, consultar y visualizar información climatológica y epidemiológica.

La comparación de los resultados permite evaluar la consistencia de la información almacenada en MySQL y MongoDB, aplicando conocimientos de diseño de bases de datos, consultas, migración y validación.

### Repositorio

El código fuente, los archivos de configuración de ejemplo y la documentación del proyecto se encuentran organizados en este repositorio.

---

## INSTALACIÓN Y CONFIGURACIÓN

### Requisitos
- Python 3.
- MySQL Server 8.
- MongoDB Server 8.
- PyCharm o terminal.

### 1. Instalar dependencias

```bash
pip install pymysql pymongo streamlit pandas plotly python-dotenv
```

### 2. Configurar variables de entorno

Crear un archivo `.env` en la carpeta principal del proyecto:

```ini
MYSQL_HOST=localhost
MYSQL_USER=analista_clima
MYSQL_PASSWORD=tu_contraseña
MYSQL_DATABASE=clima_salud_mx

MONGO_URI=mongodb://localhost:27017/
MONGO_DATABASE=clima_salud_mx
```

Sustituir los valores de ejemplo por las credenciales correspondientes. Para el dashboard y la migración basta con `analista_clima`, que solo tiene permisos de lectura y lo crea `climasalud.sql`. `dashboard.py`, `probar_conexiones.py` y `Migracion_clima_salud.py` toman las credenciales de este archivo.

### Crear la base de datos MySQL

Abrir `climasalud.sql` en MySQL Workbench, conectado como `root`, y ejecutarlo completo. El script borra y vuelve a crear la base `clima_salud_mx`, y se puede ejecutar varias veces. Después, `pruebas_clima_salud.sql` verifica que todas las funciones y procedimientos funcionen.

### 3. Ejecutar el sistema

## Instalación y ejecución

### . Requisitos previos
- Python 3 instalado.
- MySQL 8.
- MongoDB 8.

### . Instalar dependencias

Desde la terminal, dentro de la carpeta del proyecto, ejecutar:

```bash
python3 -m pip install -r requirements.txt
```

Este comando instala las librerías necesarias para ejecutar el proyecto.

### . Configurar las conexiones

Crear un archivo `.env` con las credenciales de MySQL y MongoDB. Este archivo es privado y no debe subirse al repositorio.

### . Probar las conexiones

```bash
python3 probar_conexiones.py
```

### . Ejecutar la migración

```bash
python3 Migracion_clima_salud.py
```

### . Iniciar el dashboard

```bash
python3 -m streamlit run dashboard.py
```

Streamlit abrirá la interfaz en el navegador, normalmente en:

http://localhost:8501

**Nota:** Para ejecutar correctamente el sistema, es necesario tener las bases de datos configuradas y disponibles.
---

## ARCHIVOS PRINCIPALES

| Archivo | Descripción |
|---|---|
| `dashboard.py` | Interfaz de consulta y visualización |
| `Migracion_clima_salud.py` | Proceso ETL |
| `probar_conexiones.py` | Verificación de conexiones |
| `climasalud.sql` | Estructura, datos, funciones, procedimientos, triggers y roles de MySQL |
| `pruebas_clima_salud.sql` | Ejecución de prueba de todas las funciones y procedimientos |
| `.env` | Variables de configuración local |
| `.gitignore` | Exclusión de archivos privados |
| `README.md` | Documentación del proyecto |

---

## REFERENCIAS TÉCNICAS

- MySQL. (s. f.). *MySQL 8.0 Reference Manual*. https://dev.mysql.com/doc/refman/8.0/en/
- MongoDB. (s. f.). *MongoDB Documentation*. https://www.mongodb.com/docs/
- Python Software Foundation. (s. f.). *Python Documentation*. https://docs.python.org/3/
- Streamlit. (s. f.). *Streamlit Documentation*. https://docs.streamlit.io/
- Pandas. (s. f.). *Pandas Documentation*. https://pandas.pydata.org/docs/
- Plotly. (s. f.). *Plotly Python Documentation*. https://plotly.com/python/

---

**CLIMA Y SALUD MÉXICO**  
Universidad Autónoma de Baja California · Campus Otay · 2026  
Proyecto Final de Base de Datos.
