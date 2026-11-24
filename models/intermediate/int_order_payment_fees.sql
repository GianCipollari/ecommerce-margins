-- Comision de pago de cada item.
-- 1) Por cada pago: payment_value x (fee_pct + installment_fee_pct x cuotas adicionales).
-- 2) Se suma por pedido.
-- 3) Se reparte entre los items del pedido segun el peso de su precio.

with payments as (
    select * from {{ ref('stg_olist__order_payments') }}
),

fees as (
    select * from {{ ref('payment_fees') }}
),

items as (
    select * from {{ ref('stg_olist__order_items') }}
),

order_fees as (
    select
        p.order_id,
        sum(
            p.payment_value
            * (coalesce(f.fee_pct, 0)
               + coalesce(f.installment_fee_pct, 0) * greatest(p.installments - 1, 0))
        ) as order_payment_fee
    from payments p
    left join fees f on p.payment_type = f.payment_type
    group by p.order_id
)

select
    i.order_item_key,
    i.order_id,
    coalesce(o.order_payment_fee, 0)                                    as order_payment_fee,
    coalesce(i.price / nullif(sum(i.price) over (partition by i.order_id), 0), 0)
                                                                        as price_share,
    coalesce(o.order_payment_fee, 0)
        * coalesce(i.price / nullif(sum(i.price) over (partition by i.order_id), 0), 0)
                                                                        as payment_fee
from items i
left join order_fees o on i.order_id = o.order_id
