import zipfile
import pandas as pd
from pathlib import Path

ZIP = "data/raw/salud/datos_abiertos_dengue_271223.zip"
SALIDA = Path("data/processed/dengue_estado_mes_2023.csv")

# Verificar en el catálogo de la DGE:
# ESTATUS_CASO: 1 = probable, 2 = confirmado, 3 = descartado
# DEFUNCION: 1 = sí, 2 = no
CONFIRMADO = 2
SI = 1

ESTADOS = {
    1: "Aguascalientes", 2: "Baja California", 3: "Baja California Sur",
    4: "Campeche", 5: "Coahuila", 6: "Colima", 7: "Chiapas",
    8: "Chihuahua", 9: "Ciudad de México", 10: "Durango",
    11: "Guanajuato", 12: "Guerrero", 13: "Hidalgo", 14: "Jalisco",
    15: "México", 16: "Michoacán", 17: "Morelos", 18: "Nayarit",
    19: "Nuevo León", 20: "Oaxaca", 21: "Puebla", 22: "Querétaro",
    23: "Quintana Roo", 24: "San Luis Potosí", 25: "Sinaloa",
    26: "Sonora", 27: "Tabasco", 28: "Tamaulipas", 29: "Tlaxcala",
    30: "Veracruz", 31: "Yucatán", 32: "Zacatecas",
}

COLUMNAS = ["ID_REGISTRO", "ENTIDAD_RES", "FECHA_SIGN_SINTOMAS",
            "ESTATUS_CASO", "DEFUNCION"]


def leer():
    with zipfile.ZipFile(ZIP) as z:
        for enc in ("utf-8", "latin-1"):
            try:
                with z.open("dengue_abierto.csv") as f:
                    return pd.read_csv(f, usecols=COLUMNAS,
                                       encoding=enc, low_memory=False)
            except UnicodeDecodeError:
                continue


def transformar(df):
    df = df[df["ESTATUS_CASO"] == CONFIRMADO].copy()
    print("Casos confirmados:", len(df))
    df = df[df["ENTIDAD_RES"].between(1, 32)]
    df["fecha"] = pd.to_datetime(df["FECHA_SIGN_SINTOMAS"], errors="coerce")
    df = df.dropna(subset=["fecha"])
    df["anio"] = df["fecha"].dt.year
    df["mes"] = df["fecha"].dt.month
    df["murio"] = (df["DEFUNCION"] == SI).astype(int)

    resumen = (
        df.groupby(["ENTIDAD_RES", "anio", "mes"])
        .agg(casos_confirmados=("ID_REGISTRO", "count"),
             defunciones=("murio", "sum"))
        .reset_index()
    )

    # todas las combinaciones estado-mes, con 0 donde no hubo casos
    completo = pd.MultiIndex.from_product(
        [range(1, 33), [2023], range(1, 13)],
        names=["ENTIDAD_RES", "anio", "mes"],
    ).to_frame(index=False)
    resumen = completo.merge(resumen, how="left",
                             on=["ENTIDAD_RES", "anio", "mes"]).fillna(0)
    resumen[["casos_confirmados", "defunciones"]] = (
        resumen[["casos_confirmados", "defunciones"]].astype(int)
    )

    resumen.insert(1, "estado", resumen["ENTIDAD_RES"].map(ESTADOS))
    return resumen.rename(columns={"ENTIDAD_RES": "id_estado"})


if __name__ == "__main__":
    df = leer()
    print("Filas leídas:", len(df))
    resumen = transformar(df)
    SALIDA.parent.mkdir(parents=True, exist_ok=True)
    resumen.to_csv(SALIDA, index=False, encoding="utf-8-sig")
    print("Tabla final:", resumen.shape)
    print("Total confirmados:", resumen["casos_confirmados"].sum())
    print("Total defunciones:", resumen["defunciones"].sum())
    print(resumen.groupby("estado")["casos_confirmados"].sum()
          .sort_values(ascending=False).head(5))