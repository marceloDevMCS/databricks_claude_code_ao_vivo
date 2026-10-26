CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${silver_schema}.transactions (
  CONSTRAINT transaction_id_present EXPECT (transaction_id IS NOT NULL) ON VIOLATION DROP ROW,
  CONSTRAINT valid_quantity_and_price EXPECT (quantity > 0 AND unit_price >= 0) ON VIOLATION DROP ROW
)
AS
SELECT
  CAST(t.transactionID AS STRING) AS transaction_id,
  CAST(t.franchiseID AS STRING) AS franchise_id,
  CAST(t.customerID AS STRING) AS customer_id,
  CAST(t.dateTime AS TIMESTAMP) AS transaction_ts,
  to_date(t.dateTime) AS transaction_day,
  to_date(date_trunc('MONTH', CAST(t.dateTime AS TIMESTAMP))) AS transaction_month,
  CAST(t.product AS STRING) AS product_id,
  t.product AS product_name,
  CAST(t.quantity AS INT) AS quantity,
  CAST(t.unitPrice AS DECIMAL(18,2)) AS unit_price,
  CAST(t.totalPrice AS DECIMAL(18,2)) AS revenue,
  t.paymentMethod AS payment_method,
  f.franchise_name,
  f.city,
  f.country,
  f.latitude,
  f.longitude,
  c.customer_name,
  c.email AS customer_email,
  c.country AS customer_country,
  t._ingested_at
FROM ${medallion_catalog}.${bronze_schema}.transactions t
LEFT JOIN ${medallion_catalog}.${silver_schema}.franchises f
  ON CAST(t.franchiseID AS STRING) = f.franchise_id
LEFT JOIN ${medallion_catalog}.${silver_schema}.customers c
  ON CAST(t.customerID AS STRING) = c.customer_id
WHERE t.transactionID IS NOT NULL
  AND t.dateTime IS NOT NULL
  AND CAST(t.quantity AS INT) > 0
  AND CAST(t.unitPrice AS DECIMAL(18,2)) >= 0
  AND t.totalPrice IS NOT NULL;
