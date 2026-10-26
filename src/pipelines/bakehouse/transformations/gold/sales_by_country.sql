CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_country AS
SELECT country, COUNT(DISTINCT transaction_id) AS orders, SUM(revenue) AS revenue,
       SUM(revenue) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS average_order_value,
       COUNT(DISTINCT franchise_id) AS active_franchises
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY country;
