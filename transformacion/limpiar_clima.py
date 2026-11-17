import pandas as pd
from pathlib import Path

ENTRADA = "data/raw/clima_crudo.csv"
SALIDA = Path("data/processed/clima_ciudad_mes.csv")
UMBRAL_CALOR = 40  # °C

df = pd.read_csv(ENTRADA)
print("Filas leídas:", len(df))

df["fecha"] = pd.to_datetime(df["time"])
df["anio"] = df["fecha"].dt.year
df["mes"] = df["fecha"].dt.month
df["calor_extremo"] = (df["temperature_2m_max"] >= UMBRAL_CALOR).astype(int)

resumen = (
    df.groupby(["ciudad", "estado", "latitud", "longitud", "anio", "mes"])
    .agg(
        temp_max_prom=("temperature_2m_max", "mean"),
        temp_max_abs=("temperature_2m_max", "max"),
        temp_min_prom=("temperature_2m_min", "mean"),
        precipitacion_total=("precipitation_sum", "sum"),
        humedad_prom=("relative_humidity_2m_mean", "mean"),
        dias_calor_extremo=("calor_extremo", "sum"),
        dias_registrados=("time", "count"),
    )
    .reset_index()
)

columnas_num = ["temp_max_prom", "temp_max_abs", "temp_min_prom",
                "precipitacion_total", "humedad_prom"]
resumen[columnas_num] = resumen[columnas_num].round(2)

SALIDA.parent.mkdir(parents=True, exist_ok=True)
resumen.to_csv(SALIDA, index=False, encoding="utf-8-sig")

print("Tabla final:", resumen.shape)
print("Ciudades:", resumen["ciudad"].nunique())
print(resumen.head())
print("\nDías de calor extremo por ciudad:")
print(resumen.groupby("ciudad")["dias_calor_extremo"].sum()
      .sort_values(ascending=False))