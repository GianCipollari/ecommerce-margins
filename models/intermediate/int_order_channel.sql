-- Canal de adquisicion simulado de cada pedido (Olist no lo informa).
-- El md5 de order_id da un numero fijo de 0 a 99 (macro channel_bucket), que cae
-- en el rango de un canal. Da el mismo numero en Snowflake y en DuckDB.
-- Mismo pedido = mismo canal en todas las corridas.

with orders as (
    select order_id from {{ ref('stg_olist__orders') }}
),

channel_mix as (
    select * from {{ ref('channel_mix') }}
),

bucketed as (
    select
        order_id,
        {{ channel_bucket('order_id') }} as bucket
    from orders
)

select
    b.order_id,
    b.bucket,
    c.channel
from bucketed b
join channel_mix c
  on b.bucket between c.bucket_from and c.bucket_to
