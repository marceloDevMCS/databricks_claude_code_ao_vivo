CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sales_by_product AS
SELECT product_id, product_name, SUM(quantity) AS units_sold,
       COUNT(DISTINCT transaction_id) AS orders, SUM(revenue) AS revenue
FROM ${medallion_catalog}.${silver_schema}.transactions
GROUP BY product_id, product_name;
