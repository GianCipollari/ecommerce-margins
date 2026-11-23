"""Genera los seeds de supuestos de costos para el modelo de margenes.

Lee los CSV crudos de Olist en data/raw y escribe en seeds/:
  - cogs_by_category.csv     costo del producto como % del precio, por categoria
  - payment_fees.csv         comision por medio de pago y recargo por cuota
  - channel_mix.csv          canales de adquisicion, su peso y su rango de hash
  - ad_cost_pct_monthly.csv  costo de publicidad como % de la venta, por canal y mes

Los valores son supuestos ilustrativos, documentados en docs/assumptions.md.
La semilla fija (42) hace que el resultado sea siempre el mismo.

Uso (desde la raiz del repo, con el entorno activado):
    python scripts/generate_seeds.py
"""
from pathlib import Path

import numpy as np
import pandas as pd

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
SEEDS = ROOT / "seeds"
RNG = np.random.default_rng(42)

# --- Supuestos -------------------------------------------------------------

# Costo del producto: entre 35% y 65% del precio segun la categoria.
COGS_MIN, COGS_MAX = 0.35, 0.65
COGS_UNKNOWN = 0.50  # productos sin categoria: punto medio del rango

# Comision por medio de pago: % fijo + % extra por cada cuota despues de la primera.
PAYMENT_FEES = [
    # payment_type, fee_pct, installment_fee_pct
    ("credit_card", 0.035, 0.008),
    ("debit_card", 0.015, 0.000),
    ("boleto", 0.010, 0.000),
    ("voucher", 0.000, 0.000),
    ("not_defined", 0.000, 0.000),
]

# Canales: peso en los pedidos y costo base de publicidad como % de la venta.
CHANNELS = [
    # channel, weight, base_ad_cost_pct
    ("organic", 0.40, 0.00),
    ("google_ads", 0.30, 0.12),
    ("meta_ads", 0.20, 0.15),
    ("email", 0.10, 0.01),
]
AD_NOISE = (0.80, 1.20)       # variacion mensual de +/-20%
NOVEMBER_UPLIFT = 1.30        # Black Friday: la publicidad cuesta 30% mas


# --- Generadores -----------------------------------------------------------

def build_cogs() -> pd.DataFrame:
    """Una fila por categoria de producto, con su % de costo."""
    products = pd.read_csv(RAW / "olist_products_dataset.csv",
                           usecols=["product_category_name"])
    translation = pd.read_csv(RAW / "product_category_name_translation.csv",
                              encoding="utf-8-sig")

    # Se parte de las categorias de PRODUCTS, no de la traduccion:
    # algunas categorias no tienen traduccion y no deben quedar sin costo.
    categories = sorted(products["product_category_name"].dropna().unique())
    df = pd.DataFrame({"product_category_name": categories})
    df = df.merge(translation, on="product_category_name", how="left")
    df["product_category_name_english"] = (
        df["product_category_name_english"].fillna(df["product_category_name"])
    )
    df["cogs_pct"] = RNG.uniform(COGS_MIN, COGS_MAX, len(df)).round(3)

    unknown = pd.DataFrame([{
        "product_category_name": "unknown",
        "product_category_name_english": "unknown",
        "cogs_pct": COGS_UNKNOWN,
    }])
    return pd.concat([df, unknown], ignore_index=True)


def build_payment_fees() -> pd.DataFrame:
    return pd.DataFrame(PAYMENT_FEES,
                        columns=["payment_type", "fee_pct", "installment_fee_pct"])


def build_channel_mix() -> pd.DataFrame:
    """Canales con su rango de buckets (0-99) para asignarlos por hash en dbt."""
    df = pd.DataFrame(CHANNELS, columns=["channel", "weight", "base_ad_cost_pct"])
    assert abs(df["weight"].sum() - 1) < 1e-9, "los pesos de los canales deben sumar 1"
    upper = (df["weight"].cumsum() * 100).round().astype(int)
    df["bucket_from"] = upper.shift(fill_value=0)
    df["bucket_to"] = upper - 1
    return df[["channel", "weight", "bucket_from", "bucket_to"]]


def build_ad_cost_monthly() -> pd.DataFrame:
    """% de publicidad por canal y mes, cubriendo todo el rango de pedidos."""
    orders = pd.read_csv(RAW / "olist_orders_dataset.csv",
                         usecols=["order_purchase_timestamp"],
                         parse_dates=["order_purchase_timestamp"])
    first = orders["order_purchase_timestamp"].min().to_period("M").to_timestamp()
    last = orders["order_purchase_timestamp"].max().to_period("M").to_timestamp()
    months = pd.date_range(first, last, freq="MS")

    rows = []
    for channel, _, base in CHANNELS:
        for month in months:
            season = NOVEMBER_UPLIFT if month.month == 11 else 1.0
            pct = base * RNG.uniform(*AD_NOISE) * season
            rows.append({
                "order_month": month.strftime("%Y-%m-%d"),
                "channel": channel,
                "ad_cost_pct": round(pct, 4),
            })
    return pd.DataFrame(rows)


# --- Main ------------------------------------------------------------------

def main() -> None:
    SEEDS.mkdir(exist_ok=True)
    outputs = {
        "cogs_by_category.csv": build_cogs(),
        "payment_fees.csv": build_payment_fees(),
        "channel_mix.csv": build_channel_mix(),
        "ad_cost_pct_monthly.csv": build_ad_cost_monthly(),
    }
    for name, df in outputs.items():
        df.to_csv(SEEDS / name, index=False)
        print(f"{name:<28} {len(df):>5} filas")


if __name__ == "__main__":
    main()
