CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.customers
COMMENT 'Raw copy of source customers with ingestion metadata'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'sales_customers' AS _source_table
FROM samples.bakehouse.sales_customers;
