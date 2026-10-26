CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.customers (
  CONSTRAINT customer_id_present EXPECT (customer_id IS NOT NULL) ON VIOLATION DROP ROW
)
AS
SELECT
  CAST(customerID AS STRING) AS customer_id,
  concat_ws(' ', first_name, last_name) AS customer_name,
  email_address AS email,
  city,
  CASE
    WHEN upper(trim(country)) IN ('US', 'USA', 'UNITED STATES') THEN 'USA'
    ELSE upper(trim(country))
  END AS country,
  _ingested_at
FROM ${medallion_catalog}.${bronze_schema}.customers;
