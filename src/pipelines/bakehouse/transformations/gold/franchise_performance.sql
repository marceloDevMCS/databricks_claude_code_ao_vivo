CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.franchise_performance AS
SELECT franchise_id, franchise_name, city, country, latitude, longitude,
       COUNT(DISTINCT transaction_id) AS orders, SUM(revenue) AS revenue,
       SUM(revenue) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS average_order_value,
       COUNT(DISTINCT transaction_day) AS active_days
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY franchise_id, franchise_name, city, country, latitude, longitude;
