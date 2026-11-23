# Decisiones técnicas

Problemas que aparecieron al construir el proyecto y cómo se resolvieron.

## Entorno

**dbt fijado en la versión 1.x.** La instalación de dbt 2.x descarga un componente extra desde GitHub durante el `pip install`, y esa descarga fallaba por verificación de certificado SSL en el entorno local. Se fijó `dbt-core<2` y `dbt-snowflake<2` en `requirements.txt`. La versión 1.x cubre todo lo que necesita el proyecto.

## Carga de datos

**Columnas en mayúscula al inferir el esquema.** `INFER\\\_SCHEMA` toma los nombres de columna tal cual vienen en el CSV, en minúscula, y `CREATE TABLE ... USING TEMPLATE` los crea entre comillas (`"order\\\_id"`). Eso obliga a citarlos en todo el SQL. Se aplicó `UPPER(COLUMN\\\_NAME)` en el template para que queden como identificadores normales.

**Contexto explícito en cada script.** En Snowsight cada worksheet tiene su propio contexto de rol, warehouse y base. Todos los scripts empiezan con `USE ROLE`, `USE WAREHOUSE` y `USE SCHEMA`, para que den el mismo resultado sin depender de lo que esté elegido en pantalla. Además, así el consumo queda dentro del warehouse con resource monitor.

**Control de costos desde el primer paso.** Warehouse XS con `AUTO\\\_SUSPEND = 60` y un resource monitor de 10 créditos que avisa al 80% y suspende al 100%. Consumo total del día 1: 0.20 créditos.

## Modelado

**El filtro de pedidos entregados se aplica en el mart, no en staging.** Si `stg\\\_olist\\\_\\\_orders` filtrara, los ítems y pagos de pedidos no entregados quedarían sin pedido y los tests de relaciones fallarían. Staging conserva todos los estados con la bandera `is\\\_delivered`.

**Las categorías salen de PRODUCTS, no de la tabla de traducción.** Algunas categorías de Olist no tienen traducción al inglés. Generar los costos desde la traducción habría dejado productos sin costo. Esas categorías conservan su nombre en portugués.

**Columnas de seeds sin comillas.** Se configuró `+quote\\\_columns: false` para que las columnas de los seeds queden en mayúscula, igual que el resto de las tablas.

**Redondeo antes de calcular márgenes.** Cada componente (venta, costo, envío, comisión, publicidad) se redondea a 2 decimales, y CM1–CM3 se calculan desde esos valores. Así los márgenes cierran exacto con sus componentes.

## Calidad de datos

**Conciliación de cobros como advertencia.** Se compara, por pedido entregado, lo cobrado (`payment\\\_value`) contra lo facturado (`price + freight\\\_value`). De 96.478 pedidos entregados, 247 (0,26%) tienen una diferencia mayor a 1 BRL:

|Tipo|Pedidos|Diferencia total (BRL)|
|-|-|-|
|Cobrado de más (intereses, recargos)<br /><br />Cobrado de menos (vouchers, descuentos)<br /><br />Sin pago registrado|229<br /><br />17<br /><br />1|3.026,76<br /><br />−197,57<br /><br />−143,46|

El test está configurado como `warn`: informa los casos sin frenar el pipeline, porque las diferencias vienen de la fuente (vouchers, intereses de cuotas, pagos sin registrar) y no de un error del modelo.







