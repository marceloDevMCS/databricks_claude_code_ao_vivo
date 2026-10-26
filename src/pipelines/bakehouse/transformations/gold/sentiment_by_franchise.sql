CREATE OR REFRESH MATERIALIZED VIEW ${medallion_catalog}.${gold_schema}.sentiment_by_franchise AS
SELECT franchise_id, franchise_name, city, country, sentiment,
       COUNT(*) AS review_count
FROM ${medallion_catalog}.${silver_schema}.reviews_sentiment
GROUP BY franchise_id, franchise_name, city, country, sentiment;
