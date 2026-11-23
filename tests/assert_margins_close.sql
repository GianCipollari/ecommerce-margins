-- Cada nivel de margen cierra con sus componentes.
select order_item_key, revenue, cogs, shipping_cost, payment_fee, ad_cost, cm1, cm2, cm3
from {{ ref('fct_order_item_margins') }}
where abs(cm1 - (revenue - cogs)) > 0.01
   or abs(cm2 - (cm1 - shipping_cost - payment_fee)) > 0.01
   or abs(cm3 - (cm2 - ad_cost)) > 0.01
