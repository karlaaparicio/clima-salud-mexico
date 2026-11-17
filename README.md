# clima-salud-mexico

Proyecto ETL y dashboards sobre la relación entre el clima (temperatura, humedad y lluvia) y las enfermedades en México.

> **Estado:** en desarrollo · Proyecto final de Base de Datos · UABC Campus Otay

---

## Tabla de contenido

1. [Descripción](#descripción)
2. [Problemática y objetivos](#problemática-y-objetivos)
3. [Fuentes de datos](#fuentes-de-datos)
4. [Arquitectura del proyecto](#arquitectura-del-proyecto)
5. [Modelo de datos](#modelo-de-datos)
6. [Proceso ETL](#proceso-etl)
7. [Funcionalidades de la base de datos](#funcionalidades-de-la-base-de-datos)
8. [Migración a MongoDB](#migración-a-mongodb)
9. [Dashboards](#dashboards)
10. [Estructura del repositorio](#estructura-del-repositorio)
11. [Requisitos e instalación](#requisitos-e-instalación)
12. [Uso](#uso)
13. [Equipo](#equipo)

---

## Descripción

Este proyecto integra datos climatológicos y datos de salud de México para analizar cómo variables como la **temperatura**, la **humedad** y la **lluvia** se relacionan con la incidencia de distintas enfermedades. El flujo completo cubre:

- **Extracción** de datos desde fuentes abiertas.
- **Transformación y limpieza** de los datos.
- **Carga** en una base de datos relacional.
- **Migración** de tablas seleccionadas a MongoDB.
- **Visualización** de resultados en dashboards.

## Problemática y objetivos

**Problemática:** _(describir aquí la problemática de empresa o negocio local que atiende el proyecto)_

**Objetivo general:** Construir una base de datos y un pipeline ETL que permitan analizar la relación entre clima y enfermedades en México.

**Objetivos específicos:**

- Diseñar una base de datos relacional con al menos 7 entidades.
- Automatizar la extracción, limpieza y carga de datos.
- Implementar procedimientos almacenados, triggers de auditoría y roles de usuario.
- Migrar tablas seleccionadas a MongoDB mediante un script migrador con interfaz gráfica.
- Presentar los hallazgos en dashboards interactivos.

## Fuentes de datos

| Fuente | Tipo de dato | Formato | Periodo |
|--------|--------------|---------|---------|
| _(por definir)_ | Clima (temperatura, humedad, lluvia) | _CSV / API_ | _—_ |
| _(por definir)_ | Salud (enfermedades) | _CSV / API_ | _—_ |

## Arquitectura del proyecto

```
Fuentes de datos  ->  Extracción  ->  Transformación  ->  Carga (SQL)  ->  Migración (MongoDB)
                                                              |
                                                              v
                                                         Dashboards
```

_(Se puede reemplazar por un diagrama de imagen en `docs/`.)_

## Modelo de datos

Base de datos relacional con **7 o más entidades**.

| Entidad | Descripción |
|---------|-------------|
| _(por definir)_ | _—_ |

_Agregar aquí el diagrama entidad-relación (`docs/modelo_er.png`)._

## Proceso ETL

1. **Extracción:** descarga/lectura de los datos desde las fuentes.
2. **Transformación:** limpieza de nulos y duplicados, estandarización de fechas y estados/municipios, y unión de datasets de clima y salud.
3. **Carga:** inserción de los datos limpios en la base de datos.

## Funcionalidades de la base de datos

- **Procedimientos almacenados (CRUD):** consulta y operaciones de alta, baja y modificación.
- **Triggers y tabla de auditoría:** registro de cambios (entidad, fecha, acción, usuario).
- **Roles de usuario:**

| Rol | Permisos |
|-----|----------|
| Administrador | _(por definir)_ |
| Usuario | _(por definir)_ |
| Analista | _(por definir)_ |

- **Reportes:**
  - Reporte 1 (lista): _(por definir)_
  - Reporte 2 (lista): _(por definir)_
  - Reporte 3: generado según los parámetros que se soliciten.

## Migración a MongoDB

Script migrador que clona tablas seleccionadas de SQL a MongoDB, con:

- Lectura de las tablas origen.
- Migración de los datos y validación de la estructura NoSQL.
- Manejo de errores.
- Interfaz gráfica.

**Colecciones resultantes:** _(por definir)_

## Dashboards

_(Agregar capturas en `docs/` y describir los indicadores principales: por ejemplo, enfermedades vs. temperatura, humedad y precipitación por estado y periodo.)_

## Estructura del repositorio

```
clima-salud-mexico/
├── data/            # datos crudos y limpios
├── etl/             # scripts de extracción, transformación y carga
├── sql/             # esquema, procedimientos, triggers, roles y reportes
├── migracion/       # script migrador a MongoDB e interfaz gráfica
├── dashboards/      # archivos de dashboards
├── docs/            # diagramas y capturas
└── README.md
```

_(Ajustar a la estructura real del repositorio.)_

## Requisitos e instalación

**Requisitos:**

- Python 3.x
- _Motor de base de datos SQL (por definir)_
- MongoDB
- _Librerías: pandas, ... (por definir)_

**Instalación:**

```bash
git clone <url-del-repositorio>
cd clima-salud-mexico
pip install -r requirements.txt
```

## Uso

1. Crear la base de datos ejecutando los scripts de `sql/`.
2. Ejecutar el proceso ETL desde `etl/`.
3. Ejecutar el migrador de `migracion/`.
4. Abrir los dashboards.

## Equipo

| Nombre | Rol |
|--------|-----|
| Zoe Valentina Crespo Dorantes | _(por definir)_ 
| Ingrid Engracia Montesinos Jimenez | _(por definir)_ |
| Karla Stephanie Aparicio Garduño | _(por definir)_ |

---

Proyecto académico · UABC Campus Otay · 2026
