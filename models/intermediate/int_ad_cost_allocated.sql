-- Costo de publicidad de cada item: venta del item x % de publicidad
-- de su canal en el mes del pedido. Equivale a repartir el gasto del
-- canal-mes entre sus pedidos segun la venta.

with items as (
    select * from {{ ref('stg_olist__order_items') }}
),

orders as (
    select order_id, order_month from {{ ref('stg_olist__orders') }}
),

channels as (
    select order_id, channel from {{ ref('int_order_channel') }}
),

ad_pct as (
    select * from {{ ref('ad_cost_pct_monthly') }}
)

select
    i.order_item_key,
    i.order_id,
    o.order_month,
    c.channel,
    coalesce(a.ad_cost_pct, 0)                              as ad_cost_pct,
    (i.price + i.freight_value) * coalesce(a.ad_cost_pct, 0) as ad_cost
from items i
join orders o   on i.order_id = o.order_id
join channels c on i.order_id = c.order_id
left join ad_pct a
  on a.order_month = o.order_month
 and a.channel = c.channel
