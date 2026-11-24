-- Un pedido por fila. Se conservan todos los estados; el filtro de entregados
-- se aplica en el mart para no romper las relaciones con items y pagos.
with source as (
    select * from {{ source('olist', 'orders') }}
)

select
    order_id,
    customer_id,
    order_status,
    order_status = 'delivered'                              as is_delivered,
    order_purchase_timestamp::timestamp                 as purchased_at,
    order_approved_at::timestamp                        as approved_at,
    order_delivered_carrier_date::timestamp             as shipped_at,
    order_delivered_customer_date::timestamp            as delivered_at,
    order_estimated_delivery_date::timestamp            as estimated_delivery_at,
    date_trunc('month', order_purchase_timestamp)::date     as order_month
from source
