-- Un cliente por pedido (customer_id). customer_unique_id agrupa recompras.
select
    customer_id,
    customer_unique_id,
    city,
    state,
    zip_code_prefix
from {{ ref('stg_olist__customers') }}
