CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.daily_sales_by_franchise
AS
SELECT transaction_day, franchise_id, franchise_name, city, country,
       COUNT(DISTINCT transaction_id) AS orders,
       SUM(revenue) AS revenue,
       SUM(quantity) AS units_sold,
       SUM(revenue) / NULLIF(COUNT(DISTINCT transaction_id), 0) AS average_order_value
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY transaction_day, franchise_id, franchise_name, city, country;
