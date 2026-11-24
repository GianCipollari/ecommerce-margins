-- Numero fijo de 0 a 99 a partir de un texto, igual en Snowflake y DuckDB.
-- Se usa md5 (mismo resultado en ambos motores) y no hash(), que cada motor
-- calcula distinto. Se toman los primeros 8 caracteres hexadecimales del md5.
{% macro channel_bucket(column) %}
    {{ return(adapter.dispatch('channel_bucket')(column)) }}
{% endmacro %}

{% macro snowflake__channel_bucket(column) %}
    mod(to_number(upper(substr(md5({{ column }}), 1, 8)), 'XXXXXXXX'), 100)
{% endmacro %}

{% macro duckdb__channel_bucket(column) %}
    mod(('0x' || substr(md5({{ column }}), 1, 8))::bigint, 100)
{% endmacro %}
