CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.transactions
COMMENT 'Raw copy of source transactions with ingestion metadata'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'sales_transactions' AS _source_table
FROM samples.bakehouse.sales_transactions;
