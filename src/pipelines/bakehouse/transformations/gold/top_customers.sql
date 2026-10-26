CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.top_customers AS
SELECT customer_id, customer_name, customer_email, customer_country,
       COUNT(DISTINCT transaction_id) AS orders, SUM(revenue) AS revenue,
       SUM(revenue) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS average_order_value
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY customer_id, customer_name, customer_email, customer_country;
