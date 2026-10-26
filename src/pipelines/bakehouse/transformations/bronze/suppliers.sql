CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.suppliers
COMMENT 'Raw copy of source suppliers with ingestion metadata'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'sales_suppliers' AS _source_table
FROM samples.bakehouse.sales_suppliers;
