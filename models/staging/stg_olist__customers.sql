-- customer_id cambia en cada pedido; customer_unique_id identifica a la persona.
with source as (
    select * from {{ source('olist', 'customers') }}
)

select
    customer_id,
    customer_unique_id,
    lpad(customer_zip_code_prefix::varchar, 5, '0')         as zip_code_prefix,
    customer_city                                           as city,
    customer_state                                          as state
from source
