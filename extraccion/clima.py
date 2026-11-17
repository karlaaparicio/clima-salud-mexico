import time
import requests
import pandas as pd
from pathlib import Path

URL = "https://archive-api.open-meteo.com/v1/archive"
SALIDA = Path("data/raw/clima_crudo.csv")

# ciudad: (estado, latitud, longitud)
CIUDADES = {
    "Tijuana":          ("Baja California", 32.51, -117.04),
    "Mexicali":         ("Baja California", 32.66, -115.47),
    "Hermosillo":       ("Sonora",          29.07, -110.96),
    "Monterrey":        ("Nuevo León",      25.67, -100.31),
    "Ciudad de México": ("Ciudad de México", 19.43,  -99.13),
    "Guadalajara":      ("Jalisco",         20.67, -103.35),
    "Veracruz":         ("Veracruz",        19.17,  -96.13),
    "Mérida":           ("Yucatán",         20.97,  -89.62),
    "Villahermosa":     ("Tabasco",         17.99,  -92.93),
    "Tuxtla Gutiérrez": ("Chiapas",         16.75,  -93.12),
    "Acapulco":         ("Guerrero",        16.85,  -99.82),
    "Oaxaca":           ("Oaxaca",          17.07,  -96.72),
}

VARIABLES = [
    "temperature_2m_max",
    "temperature_2m_min",
    "precipitation_sum",
    "relative_humidity_2m_mean",
]


def obtener_clima(ciudad, estado, lat, lon, inicio, fin, reintentos=3):
    params = {
        "latitude": lat,
        "longitude": lon,
        "start_date": inicio,
        "end_date": fin,
        "daily": VARIABLES,
        "timezone": "America/Mexico_City",
    }
    for intento in range(1, reintentos + 1):
        try:
            r = requests.get(URL, params=params, timeout=30)
            r.raise_for_status()
            df = pd.DataFrame(r.json()["daily"])
            df.insert(0, "latitud", lat)
            df.insert(0, "longitud", lon)
            df.insert(0, "estado", estado)
            df.insert(0, "ciudad", ciudad)
            return df
        except requests.RequestException as e:
            print(f"  Intento {intento} falló para {ciudad}: {e}")
            time.sleep(5 * intento)
    return None


def extraer_todo(inicio="2020-01-01", fin="2024-12-31"):
    frames = []
    for ciudad, (estado, lat, lon) in CIUDADES.items():
        print(f"Descargando {ciudad}...")
        df = obtener_clima(ciudad, estado, lat, lon, inicio, fin)
        if df is not None:
            frames.append(df)
        time.sleep(2)  # pausa para no saturar la API
    return pd.concat(frames, ignore_index=True)


if __name__ == "__main__":
    clima = extraer_todo()
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    clima.to_csv(SALIDA, index=False)
    print(clima.groupby("ciudad").size())
    print(f"Total de registros: {len(clima)}")

