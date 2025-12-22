Adhoc questions and SQL Queries for Newwave Team

1.What is the earliest and latest order timestamp?
  SELECT 
    MIN(purchase_ts) AS first_order,
    MAX(purchase_ts) AS most_recent_order
FROM core.orders;

2.What was the AOV for USD orders made in 2019?
  SELECT 
    SUM(usd_price) / NULLIF(COUNT(DISTINCT order_id), 0) AS aov_us_2019
FROM core.orders
WHERE currency = 'USD'
  AND YEAR(purchase_ts) = 2019;

3. Show customer account creation details for desktop & mobile accounts
   SELECT
    id AS customer_id,
    created_on AS account_created_at,
    CASE
        WHEN loyalty_program IN ('1','true','yes') THEN 'Loyalty Member'
        ELSE 'Non-Loyalty Member'
    END AS loyalty_status,
    account_creation_method
FROM core.customers
WHERE account_creation_method IN ('desktop', 'mobile')
ORDER BY created_on;

4. List distinct products sold in AUD through the mobile app
   SELECT DISTINCT product_name
FROM core.orders
WHERE currency = 'AUD'
  AND purchase_platform = 'mobile app'
ORDER BY product_name;


5. Return the first 10 NA-region countries (alphabetically)
   SELECT country_code
FROM core.geo_lookup
WHERE region = 'NA'
ORDER BY country_code ASC
LIMIT 10;

6. Return NA-region customers and their countries
   SELECT DISTINCT 
    c.country_code,
    g.region
FROM core.customers c
JOIN core.geo_lookup g 
      ON c.country_code = g.country_code
WHERE g.region = 'NA'
ORDER BY c.country_code
LIMIT 10;

7. How many orders shipped each month? Show newest first
  SELECT
    DATE_FORMAT(ship_ts, '%Y-%m-01') AS ship_month,
    COUNT(order_id) AS orders_shipped
FROM core.order_status
GROUP BY ship_month
ORDER BY ship_month DESC;

8. AOV by year
   SELECT
    YEAR(purchase_ts) AS purchase_year,
    SUM(usd_price) / NULLIF(COUNT(DISTINCT order_id),0) AS aov
FROM core.orders
GROUP BY purchase_year
ORDER BY purchase_year;

9. Show refund rows with a refund flag
   SELECT 
    *,
    CASE WHEN refund_ts IS NULL THEN 0 ELSE 1 END AS is_refunded
FROM core.order_status
LIMIT 20;

10. Compute days from purchase to ship
    SELECT
    os.*,
    TIMESTAMPDIFF(DAY, o.purchase_ts, os.ship_ts) AS days_to_ship
FROM core.order_status os
LEFT JOIN core.orders o 
       ON os.order_id = o.id;

11. Which region has highest avg delivery time? (website 2022 OR mobile app any year)
    SELECT
    g.region,
    AVG(TIMESTAMPDIFF(DAY, o.purchase_ts, os.delivery_ts)) AS avg_days_to_deliver
FROM core.orders o
LEFT JOIN core.order_status os ON o.id = os.order_id
LEFT JOIN core.customers c ON o.customer_id = c.id
LEFT JOIN core.geo_lookup g ON c.country_code = g.country_code
WHERE (
        (o.purchase_platform = 'website' AND YEAR(o.purchase_ts) = 2022)
        OR o.purchase_platform = 'mobile app'
      )
  AND os.delivery_ts IS NOT NULL
GROUP BY g.region
ORDER BY avg_days_to_deliver DESC;

12. Refund count & refund rate per product — overall
    SELECT
    product_name,
    SUM(CASE WHEN refunded = 1 THEN 1 ELSE 0 END) AS refunded_orders,
    COUNT(*) AS total_orders,
    ROUND(
        SUM(CASE WHEN refunded = 1 THEN 1 ELSE 0 END) 
        / NULLIF(COUNT(*),0), 
    4) AS refund_rate
FROM core.orders
GROUP BY product_name
ORDER BY refund_rate DESC;