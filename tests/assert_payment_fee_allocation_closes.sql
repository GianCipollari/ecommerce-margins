-- El reparto de comisiones no pierde ni inventa plata: la suma de las
-- comisiones de los items de un pedido tiene que dar la comision del pedido.
select
    order_id,
    max(order_payment_fee)  as order_fee,
    sum(payment_fee)        as allocated_fee
from {{ ref('int_order_payment_fees') }}
group by order_id
having abs(max(order_payment_fee) - sum(payment_fee)) > 0.01
