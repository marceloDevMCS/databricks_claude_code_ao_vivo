CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.franchises (
  CONSTRAINT franchise_id_present EXPECT (franchise_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_coordinates EXPECT (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180)
)
AS
SELECT
  CAST(franchiseID AS STRING) AS franchise_id,
  name AS franchise_name,
  city,
  CASE
    WHEN upper(trim(country)) IN ('US', 'USA', 'UNITED STATES') THEN 'USA'
    ELSE upper(trim(country))
  END AS country,
  CAST(latitude AS DOUBLE) AS latitude,
  CAST(longitude AS DOUBLE) AS longitude,
  _ingested_at
FROM ${medallion_catalog}.${bronze_schema}.franchises
WHERE franchiseID IS NOT NULL;
