-- Un item de pedido por fila. order_item_id es el numero de item dentro del pedido.
with source as (
    select * from {{ source('olist', 'order_items') }}
)

select
    order_id || '-' || order_item_id                        as order_item_key,
    order_id,
    order_item_id::int                                      as order_item_number,
    product_id,
    seller_id,
    shipping_limit_date::timestamp_ntz                      as shipping_limit_at,
    price::number(12, 2)                                    as price,
    freight_value::number(12, 2)                            as freight_value
from source
