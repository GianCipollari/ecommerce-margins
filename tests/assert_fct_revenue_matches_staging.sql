-- Los joins del mart no pierden ni duplican filas: la venta total del mart
-- tiene que igualar la de los items de pedidos entregados en staging.
with mart as (
    select sum(revenue) as total from {{ ref('fct_order_item_margins') }}
),

staging as (
    select sum(i.price + i.freight_value) as total
    from {{ ref('stg_olist__order_items') }} i
    join {{ ref('stg_olist__orders') }} o on i.order_id = o.order_id
    where o.is_delivered
)

select m.total as mart_total, s.total as staging_total
from mart m cross join staging s
where abs(m.total - s.total) > 1
