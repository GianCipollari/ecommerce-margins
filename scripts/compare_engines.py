"""Muestra ventas y margenes por canal desde el archivo DuckDB.

Correr la misma consulta en Snowsight (ver COMPARE_SQL) y comparar:
los numeros tienen que ser identicos.

Uso: python scripts/compare_engines.py
"""
import duckdb

COMPARE_SQL = """
select channel,
       count(*)                         as items,
       round(sum(revenue), 2)           as venta,
       round(sum(cm3), 2)               as cm3
from {table}
group by channel
order by channel
"""

con = duckdb.connect("data/ecom_margins.duckdb", read_only=True)
table = con.execute("""
    select table_schema || '.' || table_name
    from information_schema.tables
    where lower(table_name) = 'fct_order_item_margins'
""").fetchone()[0]

print(f"DuckDB: {table}\n")
print(con.execute(COMPARE_SQL.format(table=table)).df().to_string(index=False))
print("\nEn Snowsight:")
print(COMPARE_SQL.format(table="ECOM_MARGINS.DEV_MARTS.FCT_ORDER_ITEM_MARGINS"))
