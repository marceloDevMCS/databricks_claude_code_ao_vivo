CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${bronze_schema}.reviews
COMMENT 'Raw copy of source customer reviews with ingestion metadata'
AS
SELECT
  *,
  current_timestamp() AS _ingested_at,
  'media_customer_reviews' AS _source_table
FROM samples.bakehouse.media_customer_reviews;
