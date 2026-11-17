import zipfile
import requests
import pandas as pd
from pathlib import Path

ANIO = 2023
ARCHIVO = "datos_abiertos_dengue_271223.zip"
URL = ("https://datosabiertos.salud.gob.mx/gobmx/salud/datos_abiertos/"
       f"etv/historicos/{ANIO}/{ARCHIVO}")
CARPETA = Path("data/raw/salud")
DESTINO = CARPETA / ARCHIVO


def descargar():
    CARPETA.mkdir(parents=True, exist_ok=True)
    if DESTINO.exists():
        print("El archivo ya estaba descargado")
        return
    print("Descargando (puede tardar unos minutos)...")
    with requests.get(URL, stream=True, timeout=120) as r:
        r.raise_for_status()
        with open(DESTINO, "wb") as f:
            for bloque in r.iter_content(chunk_size=1024 * 1024):
                f.write(bloque)
    print("Descarga lista")


def explorar():
    with zipfile.ZipFile(DESTINO) as z:
        nombres = z.namelist()
        print("Contenido del ZIP:", nombres)
        csvs = [n for n in nombres if n.lower().endswith(".csv")]
        for enc in ("utf-8", "latin-1"):
            try:
                with z.open(csvs[0]) as f:
                    df = pd.read_csv(f, nrows=5, encoding=enc)
                break
            except UnicodeDecodeError:
                continue
    print("Columnas:", df.columns.tolist())
    print(df.head())


if __name__ == "__main__":
    descargar()
    explorar()