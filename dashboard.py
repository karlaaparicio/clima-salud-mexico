
import os
from pathlib import Path

import streamlit as st
import pandas as pd
import plotly.express as px
import pymysql
from pymongo import MongoClient
from dotenv import load_dotenv

# CONFIGURACIÓN
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(BASE_DIR / ".env", override=True)

st.set_page_config(
    page_title="Clima y Salud México",
    page_icon="🌎",
    layout="wide"
)

# CONEXIONES
def conectar_mysql():
    return pymysql.connect(
        host=os.getenv("MYSQL_HOST"),
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        database=os.getenv("MYSQL_DATABASE"),
        cursorclass=pymysql.cursors.DictCursor
    )


@st.cache_resource
def conectar_mongo():
    cliente = MongoClient(
        os.getenv("MONGO_URI"),
        serverSelectionTimeoutMS=5000
    )
    cliente.admin.command("ping")
    return cliente[os.getenv("MONGO_DATABASE")]


def consultar_mysql(consulta):
    conexion = conectar_mysql()
    try:
        with conexion.cursor() as cursor:
            cursor.execute(consulta)
            resultados = cursor.fetchall()
        return pd.DataFrame(resultados)
    finally:
        conexion.close()


# ENCABEZADO
st.title("Clima y Salud México")
st.subheader("Sistema de análisis climático y epidemiológico")
st.caption("Panel interactivo conectado a MySQL y MongoDB")

# VERIFICAR CONEXIONES
try:
    db_mongo = conectar_mongo()

    conexion = conectar_mysql()
    conexion.close()

    st.success("Conexión con MySQL y MongoDB establecida")

except Exception as error:
    st.error(f"No fue posible conectar las bases de datos: {error}")
    st.stop()


# MENÚ
st.sidebar.title("Menú principal")

seccion = st.sidebar.radio(
    "Selecciona una sección:",
    [
        "Inicio",
        "Enfermedades",
        "Municipios",
        "Análisis mensual",
        "Grupos de edad",
        "Información climática",
        "Bases de datos"
    ]
)

# INICIO
if seccion == "Inicio":

    st.header("Resumen general")

    indicadores = consultar_mysql("""
        SELECT
            SUM(num_casos) AS casos,
            SUM(defunciones) AS defunciones,
            COUNT(*) AS registros
        FROM casos_salud
    """)

    total_casos = int(indicadores.iloc[0]["casos"] or 0)
    total_defunciones = int(indicadores.iloc[0]["defunciones"] or 0)
    total_registros = int(indicadores.iloc[0]["registros"] or 0)

    total_clima = db_mongo.registros_clima.count_documents({})
    total_municipios = db_mongo.municipios.count_documents({})

    col1, col2, col3, col4 = st.columns(4)

    col1.metric("Total de casos", f"{total_casos:,}")
    col2.metric("Defunciones", f"{total_defunciones:,}")
    col3.metric("Registros climáticos", f"{total_clima:,}")
    col4.metric("Municipios", f"{total_municipios:,}")

    st.divider()

    st.subheader("Distribución de casos por enfermedad")

    datos = consultar_mysql("""
        SELECT
            e.nombre AS enfermedad,
            SUM(c.num_casos) AS casos
        FROM casos_salud c
        INNER JOIN enfermedades e
            ON c.id_enfermedad = e.id_enfermedad
        GROUP BY e.nombre
        ORDER BY casos DESC
    """)

    figura = px.bar(
        datos,
        x="enfermedad",
        y="casos",
        title="Casos registrados por enfermedad"
    )

    st.plotly_chart(figura, use_container_width=True)


# ENFERMEDADES
elif seccion == "Enfermedades":

    st.header("Análisis de enfermedades")

    datos = consultar_mysql("""
        SELECT
            e.nombre AS enfermedad,
            SUM(c.num_casos) AS casos,
            SUM(c.defunciones) AS defunciones
        FROM casos_salud c
        INNER JOIN enfermedades e
            ON c.id_enfermedad = e.id_enfermedad
        GROUP BY e.nombre
        ORDER BY casos DESC
    """)

    st.plotly_chart(
        px.bar(
            datos,
            x="enfermedad",
            y="casos",
            color="casos",
            title="Casos por enfermedad"
        ),
        use_container_width=True
    )

    st.dataframe(datos, use_container_width=True)


# MUNICIPIOS
elif seccion == "Municipios":

    st.header("Análisis por municipio")

    datos = consultar_mysql("""
        SELECT
            m.nombre AS municipio,
            SUM(c.num_casos) AS casos,
            SUM(c.defunciones) AS defunciones
        FROM casos_salud c
        INNER JOIN unidades_salud u
            ON c.id_unidad = u.id_unidad
        INNER JOIN municipios m
            ON u.id_municipio = m.id_municipio
        GROUP BY m.nombre
        ORDER BY casos DESC
    """)

    st.plotly_chart(
        px.bar(
            datos.sort_values("casos"),
            x="casos",
            y="municipio",
            orientation="h",
            title="Casos registrados por municipio"
        ),
        use_container_width=True
    )

    st.dataframe(datos, use_container_width=True)


# ANÁLISIS MENSUAL
elif seccion == "Análisis mensual":

    st.header("Comportamiento mensual")

    datos = consultar_mysql("""
        SELECT
            MONTH(fecha) AS numero_mes,
            SUM(num_casos) AS casos,
            SUM(defunciones) AS defunciones
        FROM casos_salud
        GROUP BY MONTH(fecha)
        ORDER BY numero_mes
    """)

    nombres_meses = [
        "Enero", "Febrero", "Marzo", "Abril",
        "Mayo", "Junio", "Julio", "Agosto",
        "Septiembre", "Octubre", "Noviembre", "Diciembre"
    ]

    datos["mes"] = datos["numero_mes"].apply(
        lambda numero: nombres_meses[int(numero) - 1]
    )

    st.plotly_chart(
        px.line(
            datos,
            x="mes",
            y="casos",
            markers=True,
            title="Evolución mensual de casos"
        ),
        use_container_width=True
    )

    st.dataframe(datos, use_container_width=True)


# GRUPOS DE EDAD
elif seccion == "Grupos de edad":

    st.header("Distribución por grupo de edad")

    datos = consultar_mysql("""
        SELECT
            grupo_edad,
            SUM(num_casos) AS casos,
            SUM(defunciones) AS defunciones
        FROM casos_salud
        GROUP BY grupo_edad
        ORDER BY casos DESC
    """)

    st.plotly_chart(
        px.pie(
            datos,
            names="grupo_edad",
            values="casos",
            title="Distribución de casos por edad"
        ),
        use_container_width=True
    )

    st.dataframe(datos, use_container_width=True)


# INFORMACIÓN CLIMÁTICA
elif seccion == "Información climática":

    st.header("Información climática")

    coleccion = db_mongo.registros_clima

    total = coleccion.count_documents({})

    st.metric("Registros meteorológicos", f"{total:,}")

    st.subheader("Muestra de registros climáticos")

    documentos = list(coleccion.find({}, {"_id": 0}).limit(20))

    if documentos:
        st.dataframe(
            pd.json_normalize(documentos),
            use_container_width=True
        )
    else:
        st.info("No hay registros climáticos disponibles.")


# BASES DE DATOS
elif seccion == "Bases de datos":

    st.header("Administración de bases de datos")

    st.subheader("MySQL - Base de datos relacional")

    conexion = conectar_mysql()

    try:
        with conexion.cursor() as cursor:
            cursor.execute("SHOW TABLES")
            tablas = cursor.fetchall()

        nombres_tablas = [list(tabla.values())[0] for tabla in tablas]

        st.write("Base de datos: clima_salud_mx")
        st.write("Tablas disponibles:")

        st.dataframe(
            pd.DataFrame({"Tablas MySQL": nombres_tablas}),
            use_container_width=True
        )
    finally:
        conexion.close()

    st.divider()

    st.subheader("MongoDB - Base de datos NoSQL")

    colecciones = db_mongo.list_collection_names()

    st.write("Base de datos: clima_salud_mx")
    st.write("Colecciones disponibles:")

    conteos = []

    for nombre in colecciones:
        conteos.append({
            "Colección": nombre,
            "Documentos": db_mongo[nombre].count_documents({})
        })

    st.dataframe(
        pd.DataFrame(conteos),
        use_container_width=True
    )

    st.divider()

    st.subheader("Validación de migración")

    total_mysql = consultar_mysql("""
        SELECT SUM(num_casos) AS total
        FROM casos_salud
    """).iloc[0]["total"]

    total_mongo = list(
        db_mongo.casos_salud.aggregate([
            {
                "$group": {
                    "_id": None,
                    "total": {"$sum": "$total_casos"}
                }
            }
        ])
    )

    total_mongo = total_mongo[0]["total"] if total_mongo else 0

    col1, col2 = st.columns(2)

    col1.metric("Casos en MySQL", f"{int(total_mysql):,}")
    col2.metric("Casos en MongoDB", f"{int(total_mongo):,}")

    if int(total_mysql) == int(total_mongo):
        st.success("La cantidad de casos coincide entre ambas bases de datos.")
    else:
        st.warning("Los totales de ambas bases de datos no coinciden.")


# PIE DE PÁGINA
st.sidebar.divider()
st.sidebar.caption("Proyecto académico")
st.sidebar.caption("Clima y Salud México")
st.sidebar.caption("Bases de datos MySQL y MongoDB")


