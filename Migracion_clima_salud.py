
import os
import sys
from pathlib import Path
from datetime import datetime, timezone

import pymysql
from pymongo import MongoClient, ReplaceOne
from dotenv import load_dotenv

# ==========================================
# 1. CONEXIONES (credenciales en el archivo .env, igual que dashboard.py)
# ==========================================

load_dotenv(Path(__file__).resolve().parent / ".env", override=True)

conexion_mysql = pymysql.connect(
    host=os.getenv("MYSQL_HOST"),
    user=os.getenv("MYSQL_USER"),
    password=os.getenv("MYSQL_PASSWORD"),
    database=os.getenv("MYSQL_DATABASE"),
    cursorclass=pymysql.cursors.DictCursor
)

cliente_mongo = MongoClient(
    os.getenv("MONGO_URI"),
    serverSelectionTimeoutMS=5000
)
db = cliente_mongo[os.getenv("MONGO_DATABASE")]

exito = False

try:
    cliente_mongo.admin.command("ping")

    print("Conexiones establecidas correctamente")

    # ==========================================
    # 2. CONSULTAR LOS CASOS EN MYSQL
    # ==========================================

    consulta = """
        SELECT
            c.id_unidad AS unidad_id,
            u.id_municipio AS municipio_id,
            e.clave AS estado_clave,
            c.id_enfermedad AS enfermedad_id,
            enf.nombre AS enfermedad,
            enf.categoria AS categoria,
            c.fecha AS fecha,
            c.grupo_edad AS grupo,
            c.num_casos AS num_casos,
            c.defunciones AS defunciones
        FROM casos_salud c
        INNER JOIN unidades_salud u
            ON c.id_unidad = u.id_unidad
        INNER JOIN municipios m
            ON u.id_municipio = m.id_municipio
        INNER JOIN estados e
            ON m.id_estado = e.id_estado
        INNER JOIN enfermedades enf
            ON c.id_enfermedad = enf.id_enfermedad
        ORDER BY c.fecha, c.id_unidad, c.id_enfermedad
    """

    with conexion_mysql.cursor() as cursor:
        cursor.execute(consulta)
        registros = cursor.fetchall()

    print("Registros leídos de MySQL:", len(registros))

    # ==========================================
    # 3. CONSULTAR REFERENCIAS EN MONGODB
    # ==========================================

    municipios = {
        doc["_id"]: doc
        for doc in db.municipios.find()
    }

    enfermedades = {
        doc["_id"]: doc
        for doc in db.enfermedades.find()
    }

    # ==========================================
    # 4. AGRUPAR LOS REGISTROS
    # ==========================================

    grupos = {}

    orden_edades = ["0-14", "15-44", "45-64", "65+"]

    for r in registros:

        unidad_id = int(r["unidad_id"])
        municipio_id = int(r["municipio_id"])
        enfermedad_id = int(r["enfermedad_id"])

        municipio = municipios.get(municipio_id)
        enfermedad = enfermedades.get(enfermedad_id)

        if municipio is None:
            raise ValueError(
                f"No existe el municipio {municipio_id} en MongoDB"
            )

        if enfermedad is None:
            raise ValueError(
                f"No existe la enfermedad {enfermedad_id} en MongoDB"
            )

        unidades = municipio.get("unidades_salud", [])

        if not any(int(u["_id"]) == unidad_id for u in unidades):
            raise ValueError(
                f"La unidad {unidad_id} no existe en el municipio "
                f"{municipio_id} de MongoDB"
            )

        estado_clave = r["estado_clave"]

        if municipio["estado"]["clave"] != estado_clave:
            raise ValueError(
                f"La clave del estado no coincide para el municipio "
                f"{municipio_id}"
            )

        if enfermedad["nombre"] != r["enfermedad"]:
            raise ValueError(
                f"El nombre de la enfermedad {enfermedad_id} no coincide"
            )

        if enfermedad["categoria"] != r["categoria"]:
            raise ValueError(
                f"La categoría de la enfermedad {enfermedad_id} no coincide"
            )

        fecha = r["fecha"]

        clave = (
            unidad_id,
            municipio_id,
            enfermedad_id,
            fecha.year,
            fecha.month
        )

        if clave not in grupos:
            grupos[clave] = {
                "unidad_id": unidad_id,
                "municipio_id": municipio_id,
                "estado_clave": estado_clave,
                "enfermedad_id": enfermedad_id,
                "enfermedad": r["enfermedad"],
                "categoria": r["categoria"],
                "fecha": datetime(
                    fecha.year,
                    fecha.month,
                    1,
                    tzinfo=timezone.utc
                ),
                "por_grupo_edad": {},
                "total_casos": 0,
                "total_defunciones": 0
            }

        grupo = grupos[clave]["por_grupo_edad"]
        nombre_grupo = r["grupo"]

        if nombre_grupo in grupo:
            raise ValueError(
                f"Registro duplicado para el grupo {nombre_grupo}: {clave}"
            )

        casos = int(r["num_casos"])
        defunciones = int(r["defunciones"])

        if casos < 0 or defunciones < 0 or defunciones > casos:
            raise ValueError(
                f"Datos inválidos en el registro: {clave}"
            )

        grupo[nombre_grupo] = {
            "grupo": nombre_grupo,
            "num_casos": casos,
            "defunciones": defunciones
        }

        grupos[clave]["total_casos"] += casos
        grupos[clave]["total_defunciones"] += defunciones

    # ==========================================
    # 5. PREPARAR DOCUMENTOS PARA MONGODB
    # ==========================================

    documentos = []

    for clave, datos in grupos.items():

        datos["por_grupo_edad"] = [
            datos["por_grupo_edad"][edad]
            for edad in orden_edades
            if edad in datos["por_grupo_edad"]
        ]

        datos["_id"] = (
            f"caso_{datos['unidad_id']}_"
            f"{datos['enfermedad_id']}_"
            f"{datos['fecha'].year}_"
            f"{datos['fecha'].month:02d}"
        )

        documentos.append(datos)

    print("Documentos mensuales preparados:", len(documentos))

    # ==========================================
    # 6. INSERTAR / ACTUALIZAR EN MONGODB
    # ==========================================

    coleccion = db["casos_salud"]

    operaciones = [
        ReplaceOne(
            {"_id": documento["_id"]},
            documento,
            upsert=True
        )
        for documento in documentos
    ]

    if operaciones:
        resultado = coleccion.bulk_write(
            operaciones,
            ordered=False
        )

        print("Documentos insertados:", resultado.upserted_count)
        print("Documentos modificados:", resultado.modified_count)

    # Borrar documentos que ya no existen en MySQL (por ejemplo, si los
    # datos cambiaron). Sin esto, MongoDB conserva documentos viejos y los
    # totales dejan de coincidir.
    ids_actuales = [d["_id"] for d in documentos]
    obsoletos = coleccion.delete_many({"_id": {"$nin": ids_actuales}})
    print("Documentos obsoletos eliminados:", obsoletos.deleted_count)

    # ==========================================
    # 7. VALIDAR RESULTADOS (MySQL vs MongoDB)
    # ==========================================

    with conexion_mysql.cursor() as cursor:
        cursor.execute("""
            SELECT COUNT(*) AS registros,
                   COALESCE(SUM(num_casos), 0) AS casos,
                   COALESCE(SUM(defunciones), 0) AS defunciones
            FROM casos_salud
        """)
        mysql_tot = cursor.fetchone()

    mongo_tot = list(coleccion.aggregate([
        {
            "$group": {
                "_id": None,
                "documentos": {"$sum": 1},
                "casos": {"$sum": "$total_casos"},
                "defunciones": {"$sum": "$total_defunciones"}
            }
        }
    ]))
    mongo_tot = mongo_tot[0] if mongo_tot else {"documentos": 0, "casos": 0, "defunciones": 0}

    print("Registros en MySQL:", mysql_tot["registros"])
    print("Documentos en MongoDB:", mongo_tot["documentos"])
    print("Casos        MySQL:", int(mysql_tot["casos"]), "| MongoDB:", mongo_tot["casos"])
    print("Defunciones  MySQL:", int(mysql_tot["defunciones"]), "| MongoDB:", mongo_tot["defunciones"])

    if mongo_tot["documentos"] != len(documentos):
        raise ValueError("La cantidad de documentos en MongoDB no coincide con los preparados")

    if (int(mysql_tot["casos"]) != mongo_tot["casos"]
            or int(mysql_tot["defunciones"]) != mongo_tot["defunciones"]):
        raise ValueError("Los totales de MySQL y MongoDB no coinciden")

    print("MIGRACIÓN FINALIZADA CORRECTAMENTE")
    exito = True

except Exception as error:
    print("ERROR EN LA MIGRACIÓN:", error)

finally:
    conexion_mysql.close()
    cliente_mongo.close()
    print("Conexiones cerradas")

sys.exit(0 if exito else 1)
