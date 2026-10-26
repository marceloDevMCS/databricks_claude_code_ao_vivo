CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.reviews_sentiment (
  CONSTRAINT review_id_present EXPECT (review_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT review_text_present EXPECT (review_text IS NOT NULL) ON VIOLATION DROP ROW
)
AS
SELECT
  CAST(r.new_id AS STRING) AS review_id,
  CAST(r.franchiseID AS STRING) AS franchise_id,
  CAST(r.review_date AS TIMESTAMP) AS review_ts,
  to_date(r.review_date) AS review_day,
  to_date(date_trunc('MONTH', CAST(r.review_date AS TIMESTAMP))) AS review_month,
  r.review AS review_text,
  ai_analyze_sentiment(r.review) AS sentiment,
  f.franchise_name,
  f.city,
  f.country,
  f.latitude,
  f.longitude,
  r._ingested_at
FROM ${medallion_catalog}.${bronze_schema}.reviews r
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises f
  ON CAST(r.franchiseID AS STRING) = f.franchise_id
WHERE r.review IS NOT NULL;
