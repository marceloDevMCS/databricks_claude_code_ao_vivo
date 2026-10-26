CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.franchises
COMMENT 'Raw copy of source franchises with ingestion metadata'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'sales_franchises' AS _source_table
FROM samples.bakehouse.sales_franchises;
