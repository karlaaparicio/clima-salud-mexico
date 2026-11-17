import zipfile
import pandas as pd

ZIP = "data/raw/salud/datos_abiertos_dengue_271223.zip"

with zipfile.ZipFile(ZIP) as z:
    for enc in ("utf-8", "latin-1"):
        try:
            with z.open("dengue_abierto.csv") as f:
                df = pd.read_csv(f, encoding=enc, low_memory=False)
            break
        except UnicodeDecodeError:
            continue

print("Total de filas:", len(df))

for col in ["ESTATUS_CASO", "DICTAMEN", "RESULTADO_PCR", "TIPO_PACIENTE", "DEFUNCION"]:
    print(f"\n{col}")
    print(df[col].value_counts(dropna=False))

print("\nCasos por ENTIDAD_RES")
print(df["ENTIDAD_RES"].value_counts().sort_index())

fechas = pd.to_datetime(df["FECHA_SIGN_SINTOMAS"], errors="coerce")
print("\nFechas de síntomas:", fechas.min(), "a", fechas.max())
print("Fechas inválidas:", fechas.isna().sum())
