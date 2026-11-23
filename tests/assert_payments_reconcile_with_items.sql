-- Conciliacion de cobros: por pedido entregado, lo cobrado (payment_value)
-- tiene que igualar lo facturado en items (price + freight_value).
-- Olist tiene pedidos que no cierran (vouchers, intereses de cuotas, pedidos
-- sin pago registrado). Por eso es warn: no frena el build, pero informa
-- cuantos son. Cada fila devuelta es un pedido con diferencia mayor a 1 BRL.
{{ config(severity='warn') }}

with delivered as (
    select order_id from {{ ref('stg_olist__orders') }} where is_delivered
),

billed as (
    select order_id, sum(price + freight_value) as billed_amount
    from {{ ref('stg_olist__order_items') }}
    group by order_id
),

collected as (
    select order_id, sum(payment_value) as collected_amount
    from {{ ref('stg_olist__order_payments') }}
    group by order_id
)

select
    d.order_id,
    coalesce(b.billed_amount, 0)                                        as billed_amount,
    coalesce(c.collected_amount, 0)                                     as collected_amount,
    coalesce(c.collected_amount, 0) - coalesce(b.billed_amount, 0)      as difference
from delivered d
left join billed b    on d.order_id = b.order_id
left join collected c on d.order_id = c.order_id
where abs(coalesce(c.collected_amount, 0) - coalesce(b.billed_amount, 0)) > 1
