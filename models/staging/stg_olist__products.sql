-- Un producto por fila. Los productos sin categoria pasan a 'unknown'
-- para que reciban el supuesto de costo de esa categoria.
with source as (
    select * from {{ source('olist', 'products') }}
)

select
    product_id,
    coalesce(product_category_name, 'unknown')              as product_category_name,
    product_photos_qty::int                                 as photos_qty,
    product_weight_g::number(10, 0)                         as weight_g
from source
