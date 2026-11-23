-- Un producto por fila, con su categoria en ingles y el supuesto de costo.
with products as (
    select * from {{ ref('stg_olist__products') }}
),

cogs as (
    select * from {{ ref('cogs_by_category') }}
)

select
    p.product_id,
    p.product_category_name,
    c.product_category_name_english     as category,
    c.cogs_pct,
    p.weight_g,
    p.photos_qty
from products p
left join cogs c on p.product_category_name = c.product_category_name
