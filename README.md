# CLIMA Y SALUD MÉXICO
### Sistema de integración, migración y análisis de datos climatológicos y epidemiológicos

**Proyecto Final de Base de Datos**  
Universidad Autónoma de Baja California (UABC)  
Campus Otay · 2026

---

## 1. INFORMACIÓN DEL PROYECTO

| Dato | Descripción |
|---|---|
| Proyecto | Clima y Salud México |
| Institución | Universidad Autónoma de Baja California |
| Campus | Otay |
| Asignatura | Base de Datos |
| Periodo | 2026 |
| Tipo | Integración de bases de datos relacionales y NoSQL |

**Integrantes:**
- Zoe Valentina Crespo Dorantes
- Ingrid Engracia Montesinos Jiménez
- Karla Stephanie Aparicio Garduño

---

## 2. DESCRIPCIÓN GENERAL

Clima y Salud México es un sistema diseñado para integrar, almacenar, migrar y analizar información climatológica y epidemiológica mediante dos modelos de bases de datos: relacional y documental.

La solución utiliza MySQL como base de datos de origen, MongoDB como destino de la migración y Python como herramienta para ejecutar los procesos de extracción, transformación y carga (ETL).

El sistema incorpora un dashboard desarrollado con Streamlit para consultar indicadores, analizar registros y comparar los resultados almacenados en ambos motores de bases de datos.

**Flujo principal:**

```text
MYSQL
Base de datos relacional
        |
        v
PYTHON
Extracción, transformación y carga (ETL)
        |
        v
MONGODB
Base de datos documental
        |
        v
STREAMLIT
Consultas, indicadores y visualización
```

---

## 3. OBJETIVO

Desarrollar un sistema de integración de datos climatológicos y epidemiológicos que permita administrar información en MySQL y MongoDB, implementar procesos de migración mediante Python y visualizar los resultados a través de una interfaz interactiva.

### Objetivos específicos

- Diseñar una estructura relacional en MySQL.
- Implementar consultas SQL y procedimientos almacenados.
- Construir una estructura documental en MongoDB.
- Desarrollar un proceso ETL para transferir información.
- Validar la integridad y consistencia de los datos migrados.
- Comparar los resultados entre ambas bases de datos.
- Generar indicadores y reportes mediante Streamlit.

---

## 4. TECNOLOGÍAS UTILIZADAS

| Tecnología | Función dentro del sistema |
|---|---|
| Python 3 | Procesamiento y migración de datos |
| MySQL 8 | Almacenamiento relacional |
| MongoDB 8 | Almacenamiento documental |
| PyMySQL | Conexión con MySQL |
| PyMongo | Conexión con MongoDB |
| Pandas | Manipulación y transformación de datos |
| Streamlit | Interfaz de consulta |
| Plotly | Gráficas y visualizaciones |
| Python-dotenv | Administración de variables de entorno |
| PyCharm | Entorno de desarrollo |

---

## 5. ESTRUCTURA DE LAS BASES DE DATOS

### 5.1 MySQL – Modelo relacional

**Base de datos:** `clima_salud_mx`

La estructura está integrada por nueve tablas:

| Tabla | Función |
|---|---|
| `estados` | Catálogo de estados de México |
| `municipios` | Información geográfica municipal |
| `estaciones_meteorologicas` | Información de estaciones climáticas |
| `registros_clima` | Registros de variables climatológicas |
| `unidades_salud` | Catálogo de unidades de atención médica |
| `enfermedades` | Catálogo de enfermedades |
| `casos_salud` | Registros epidemiológicos y defunciones |
| `resumen_mensual` | Resúmenes estadísticos por periodo |
| `auditoria` | Registro de operaciones y seguimiento |

### 5.2 MongoDB – Modelo documental

**Base de datos:** `clima_salud_mx`

Colecciones:

- `estados`
- `municipios`
- `enfermedades`
- `registros_clima`
- `casos_salud`
- `resumen_mensual`
- `auditoria`

La estructura documental permite almacenar información relacionada mediante documentos y subdocumentos, facilitando la consulta de datos geográficos, climatológicos y epidemiológicos.

---

## 6. PROCESO ETL Y MIGRACIÓN

**Archivo principal:** `Migracion_clima_salud.py`

El proceso ETL permite transferir información desde MySQL hacia MongoDB, transformando los registros relacionales en documentos.

### Etapas del proceso

| Etapa | Descripción |
|---|---|
| Extracción | Lectura de registros desde MySQL |
| Transformación | Organización y relación de información |
| Agrupación | Consolidación de registros por periodo |
| Conversión | Transformación de registros en documentos |
| Carga | Inserción o actualización en MongoDB |
| Validación | Comparación de resultados entre ambas bases |

### Flujo de migración

```text
MYSQL
  |
  v
EXTRACCIÓN DE REGISTROS
  |
  v
TRANSFORMACIÓN CON PYTHON
  |
  v
ORGANIZACIÓN DOCUMENTAL
  |
  v
CARGA EN MONGODB
  |
  v
VALIDACIÓN DE INFORMACIÓN
```

---

## 7. CONSULTAS Y REPORTES SQL

El sistema contempla consultas para obtener información epidemiológica y estadística.

### Consultas implementadas

- Casos y defunciones por enfermedad.
- Distribución de casos por municipio.
- Comportamiento mensual de los registros.
- Casos por grupo de edad.
- Totales generales de casos y defunciones.

### Procedimiento almacenado

Se implementó el procedimiento `consultar_enfermedad`, que permite consultar información asociada a una enfermedad específica.

Ejemplo:

```sql
CALL consultar_enfermedad('Dengue');
```

---

## 8. DASHBOARD Y VISUALIZACIÓN

**Archivo principal:** `dashboard.py`

La interfaz desarrollada con Streamlit permite consultar y visualizar los datos del proyecto.

| Módulo | Funcionalidad |
|---|---|
| Inicio | Indicadores generales |
| Enfermedades | Consulta de casos por enfermedad |
| Municipios | Distribución geográfica de casos |
| Análisis mensual | Comportamiento de registros por periodo |
| Grupos de edad | Distribución epidemiológica por edad |
| Información climática | Consulta de variables climatológicas |
| Bases de datos | Comparación de resultados entre MySQL y MongoDB |

Plotly se utiliza para representar gráficamente los indicadores y facilitar la interpretación de los resultados.

---

## 9. RESULTADOS Y VALIDACIÓN

La migración se evaluó mediante la comparación de los registros originales de MySQL y los documentos almacenados en MongoDB.

### Resultados obtenidos

| Indicador | Resultado |
|---|---:|
| Registros consultados en MySQL | 4,238 |
| Documentos preparados | 1,118 |
| Documentos almacenados en MongoDB | 1,118 |
| Total de casos en MySQL | 29,708 |
| Total de casos en MongoDB | 29,708 |
| Defunciones | 3 |
| Diferencia de casos | 0 |

### Criterios de validación

- Coincidencia del total de casos entre ambas bases de datos.
- Correspondencia entre documentos preparados y almacenados.
- Verificación de campos obligatorios.
- Detección de identificadores duplicados.
- Validación de que las defunciones no superen el número de casos.

**Resultado:** se obtuvo una diferencia de cero casos entre MySQL y MongoDB, conservando el total de 29,708 casos después de la migración.

---

## 10. INSTALACIÓN Y CONFIGURACIÓN

### Requisitos

- Python 3.
- MySQL Server 8.
- MongoDB Server 8.
- PyCharm o terminal.
- Archivos y estructuras de bases de datos del proyecto.

### 10.1 Instalar dependencias

```bash
pip install pymysql pymongo streamlit pandas plotly python-dotenv
```

### 10.2 Configurar variables de entorno

Crear un archivo `.env` en la carpeta principal:

```ini
MYSQL_HOST=localhost
MYSQL_USER=tu_usuario
MYSQL_PASSWORD=tu_contraseña
MYSQL_DATABASE=clima_salud_mx

MONGO_URI=mongodb://localhost:27017/
MONGO_DATABASE=clima_salud_mx
```

Sustituir los valores de ejemplo por las credenciales correspondientes.

**Importante:** no publicar el archivo `.env` en repositorios públicos.

---

## 11. EJECUCIÓN DEL SISTEMA

Para ejecutar el proyecto, seguir este orden:

**1. Iniciar los servicios**

Iniciar MySQL Server y MongoDB Server.

**2. Verificar las conexiones**

```bash
python probar_conexiones.py
```

**3. Ejecutar el proceso de migración**

```bash
python Migracion_clima_salud.py
```

**4. Iniciar el dashboard**

```bash
streamlit run dashboard.py
```

**5. Acceder a la interfaz**

Abrir en el navegador:

```text
http://localhost:8501
```

**6. Verificar resultados**

Consultar los módulos del dashboard y comprobar que los totales de casos coincidan entre MySQL y MongoDB.

---

## 12. ARCHIVOS PRINCIPALES

| Archivo | Descripción |
|---|---|
| `dashboard.py` | Interfaz de visualización y consulta |
| `Migracion_clima_salud.py` | Proceso ETL y migración |
| `probar_conexiones.py` | Verificación de conexiones |
| `.env` | Variables de configuración local |
| `.gitignore` | Exclusión de archivos privados |
| `README.md` | Documentación técnica |

---

## 13. CONCLUSIÓN

El proyecto Clima y Salud México integra dos modelos de bases de datos mediante un proceso ETL desarrollado en Python. Su implementación permite administrar información climatológica y epidemiológica en MySQL y MongoDB, además de facilitar su consulta y visualización mediante Streamlit.

La comparación de resultados permitió comprobar la conservación de los 29,708 casos registrados, obteniendo una diferencia de cero entre ambas bases de datos.

El desarrollo demuestra la aplicación de conceptos de modelado relacional, administración documental, consultas SQL, procedimientos almacenados, migración de información y validación de datos en una solución integrada.

---

## 14. REFERENCIAS TÉCNICAS

- MySQL. (s. f.). *MySQL 8.0 Reference Manual*. https://dev.mysql.com/doc/refman/8.0/en/
- MongoDB. (s. f.). *MongoDB Documentation*. https://www.mongodb.com/docs/
- Python Software Foundation. (s. f.). *Python Documentation*. https://docs.python.org/3/
- Streamlit. (s. f.). *Streamlit Documentation*. https://docs.streamlit.io/
- Pandas. (s. f.). *Pandas Documentation*. https://pandas.pydata.org/docs/
- Plotly. (s. f.). *Plotly Python Documentation*. https://plotly.com/python/

---

**CLIMA Y SALUD MÉXICO**  
Universidad Autónoma de Baja California · Campus Otay · 2026  
Proyecto Final de Base de Datos
