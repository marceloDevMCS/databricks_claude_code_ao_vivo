CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_payment_method AS
SELECT payment_method,
       COUNT(DISTINCT transaction_id) AS orders,
       SUM(revenue) AS revenue,
       SUM(revenue) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS average_order_value
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY payment_method;
