-- Margen de contribucion por item de pedido (solo pedidos entregados).
-- Grano: un item de pedido. Desde aca se agrega a producto, categoria, canal o mes.
--
--   revenue       = price + freight_value            (lo que pago el cliente)
--   cogs          = price x cogs_pct de la categoria
--   cm1           = revenue - cogs
--   shipping_cost = freight_value x shipping_cost_ratio
--   payment_fee   = parte del item en la comision del pedido
--   cm2           = cm1 - shipping_cost - payment_fee
--   ad_cost       = revenue x % de publicidad del canal y mes
--   cm3           = cm2 - ad_cost
--
-- Los componentes se redondean a 2 decimales y los margenes se calculan
-- desde los componentes redondeados, para que siempre cierren exacto.

with items as (
    select * from {{ ref('stg_olist__order_items') }}
),

orders as (
    select * from {{ ref('stg_olist__orders') }}
    where is_delivered
),

products as (
    select * from {{ ref('stg_olist__products') }}
),

customers as (
    select * from {{ ref('stg_olist__customers') }}
),

cogs as (
    select * from {{ ref('cogs_by_category') }}
),

payment_fees as (
    select order_item_key, payment_fee from {{ ref('int_order_payment_fees') }}
),

ad_costs as (
    select order_item_key, channel, ad_cost from {{ ref('int_ad_cost_allocated') }}
),

components as (
    select
        i.order_item_key,
        i.order_id,
        i.order_item_number,
        i.product_id,
        i.seller_id,
        o.customer_id,
        cu.state                                                        as customer_state,
        o.purchased_at,
        o.order_month,
        a.channel,
        p.product_category_name,
        cg.product_category_name_english                                as category,
        cg.cogs_pct,
        i.price,
        i.freight_value,

        round(i.price + i.freight_value, 2)                             as revenue,
        round(i.price * cg.cogs_pct, 2)                                 as cogs,
        round(i.freight_value * {{ var('shipping_cost_ratio') }}, 2)    as shipping_cost,
        round(coalesce(pf.payment_fee, 0), 2)                           as payment_fee,
        round(coalesce(a.ad_cost, 0), 2)                                as ad_cost
    from items i
    join orders o           on i.order_id = o.order_id
    join products p         on i.product_id = p.product_id
    left join customers cu  on o.customer_id = cu.customer_id
    left join cogs cg       on p.product_category_name = cg.product_category_name
    left join payment_fees pf on i.order_item_key = pf.order_item_key
    left join ad_costs a    on i.order_item_key = a.order_item_key
)

select
    *,
    revenue - cogs                                                      as cm1,
    revenue - cogs - shipping_cost - payment_fee                        as cm2,
    revenue - cogs - shipping_cost - payment_fee - ad_cost              as cm3
from components
