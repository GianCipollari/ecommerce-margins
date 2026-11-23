# Supuestos del modelo de márgenes

Olist publica precios, fletes y pagos, pero no los costos de la tienda. Para calcular márgenes, este proyecto simula esos costos con supuestos explícitos.

Los valores son **ilustrativos**: están elegidos para que los márgenes queden en rangos razonables, no para reflejar a una empresa real. Con datos de un cliente, se reemplazan en un solo lugar (`scripts/generate_seeds.py` o los CSV de `seeds/`) y el modelo se recalcula con `dbt build`.

Los seeds se generan con `python scripts/generate_seeds.py`. Usa una semilla fija (42), así que siempre da el mismo resultado.

## Definiciones del modelo

| Concepto | Definición |
| --- | --- |
| Pedidos incluidos | Solo `order_status = 'delivered'` |
| Grano | Un ítem de pedido |
| `revenue` | `price + freight_value`: lo que pagó el cliente por el ítem |
| `cogs` | `price × cogs_pct` de la categoría del producto |
| `cm1` | `revenue − cogs` |
| `shipping_cost` | `freight_value × shipping_cost_ratio` |
| `payment_fee` | Comisión del pedido, repartida entre sus ítems según el precio |
| `cm2` | `cm1 − shipping_cost − payment_fee` |
| `ad_cost` | `revenue × ad_cost_pct` del canal y mes del pedido |
| `cm3` | `cm2 − ad_cost` |

## Supuestos

| Supuesto | Valor | Dónde vive | Por qué |
| --- | --- | --- | --- |
| Costo del producto | Entre 35% y 65% del precio, distinto por categoría | `seeds/cogs_by_category.csv` | Rango típico de reventa minorista; varía para que haya categorías más y menos rentables |
| Productos sin categoría | 50% del precio (categoría `unknown`) | `seeds/cogs_by_category.csv` | Punto medio del rango, para no inflar ni castigar su margen |
| Comisión de pago | Tarjeta de crédito 3,5% + 0,8% por cuota adicional; débito 1,5%; boleto 1%; voucher 0% | `seeds/payment_fees.csv` | Las cuotas encarecen el cobro con tarjeta, algo común en Brasil y Argentina |
| Canal de adquisición | Orgánico 40%, Google Ads 30%, Meta Ads 20%, email 10% | `seeds/channel_mix.csv` | Olist no informa el canal. Se asigna por hash de `order_id`, así que cada pedido cae siempre en el mismo canal |
| Costo de publicidad | Google Ads 12% y Meta Ads 15% de la venta; email 1%; orgánico 0%. Varía ±20% por mes y sube 30% en noviembre | `seeds/ad_cost_pct_monthly.csv` | El costo de publicidad se expresa como % de la venta del canal; noviembre refleja la competencia de Black Friday |
| Costo real del envío | 1,15 × `freight_value` | Variable `shipping_cost_ratio` en `dbt_project.yml` | La tienda absorbe parte del flete: le cuesta 15% más de lo que cobra |

## Cómo se asigna el canal

Cada pedido recibe un número de 0 a 99 con `mod(abs(hash(order_id)), 100)`. Ese número cae en el rango (`bucket_from`–`bucket_to`) de un canal de `channel_mix.csv`. Como el hash de un mismo `order_id` es siempre el mismo, el resultado no cambia entre corridas.

## Limitaciones

- Los márgenes absolutos dependen de los supuestos. Lo que el modelo demuestra es la lógica (qué costos entran en cada nivel y cómo se reparten), no la rentabilidad real de Olist.
- El canal es simulado, así que las diferencias entre canales reflejan los supuestos de publicidad y no comportamiento real de los clientes.
