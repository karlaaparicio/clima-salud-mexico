
import os
from pathlib import Path
import pymysql
from pymongo import MongoClient
from dotenv import load_dotenv

carpeta = Path(__file__).resolve().parent
load_dotenv(dotenv_path=carpeta / ".env", override=True)

# Conexión MySQL
try:
    conexion = pymysql.connect(
        host=os.getenv("MYSQL_HOST"),
        user=os.getenv("MYSQL_USER"),
        password=os.getenv("MYSQL_PASSWORD"),
        database=os.getenv("MYSQL_DATABASE")
    )

    print("MySQL: conexión exitosa")

    with conexion.cursor() as cursor:
        cursor.execute("SELECT COUNT(*) FROM casos_salud")
        print("Registros en casos_salud:", cursor.fetchone()[0])

    conexion.close()

except Exception as error:
    print("Error en MySQL:", error)


# Conexión MongoDB
try:
    cliente = MongoClient(
        os.getenv("MONGO_URI"),
        serverSelectionTimeoutMS=5000
    )

    cliente.admin.command("ping")

    db = cliente[os.getenv("MONGO_DATABASE")]

    print("MongoDB: conexión exitosa")
    print("Colecciones:", db.list_collection_names())
    print("Documentos en casos_salud:", db.casos_salud.count_documents({}))

    cliente.close()

except Exception as error:
    print("Error en MongoDB:", error)

