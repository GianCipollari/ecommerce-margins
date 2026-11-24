-- Un pago por fila. Un pedido puede pagarse con varios medios (payment_sequential).
with source as (
    select * from {{ source('olist', 'order_payments') }}
)

select
    order_id || '-' || payment_sequential::varchar                  as payment_key,
    order_id,
    payment_sequential::int                                 as payment_sequence,
    payment_type,
    payment_installments::int                               as installments,
    payment_value::decimal(12, 2)                            as payment_value
from source
