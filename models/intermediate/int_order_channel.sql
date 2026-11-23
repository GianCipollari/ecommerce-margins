-- Canal de adquisicion simulado de cada pedido (Olist no lo informa).
-- El hash de order_id da un numero fijo de 0 a 99, que cae en el rango de un canal.
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
        mod(abs(hash(order_id)), 100) as bucket
    from orders
)

select
    b.order_id,
    b.bucket,
    c.channel
from bucketed b
join channel_mix c
  on b.bucket between c.bucket_from and c.bucket_to
