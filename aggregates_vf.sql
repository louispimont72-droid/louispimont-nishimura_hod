-- Answer all the questions below with aggegate SQL queries
-- don't forget to add a screenshot of the result from BigQuery directly in the basics/ folder

--1. What was the total revenue and order count for 2018?

SELECT
    COUNT(DISTINCT oi.order_id) AS nb_orders,
    SUM(oi.price) AS total_revenue,
    DATE(o.order_delivered_customer_date) AS year_ref
FROM olist_orders_dataset as o
LEFT JOIN olist_order_items_dataset AS oi
    ON o.order_id = oi.order_id
WHERE year_ref = '2018-01-01'

--2. What is the total sales, average_order_sales, and first_order date by customer?
--Round the values to 2 decimal places & order by total_sales descending
--limit to 1000 results"

SELECT
    --c.customer_id,
    COUNT(DISTINCT o.order_id) AS nb_orders,
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(SUM (oi.price) /NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_sales, -- NULLIF avoids division by zero
    MIN(DATE(o.order_purchase_timestamp)) AS first_order_date -- earliest order = first purchase
FROM olist_customers_dataset AS c
LEFT JOIN olist_orders_dataset AS o
    ON c.customer_id = o.customer_id
LEFT JOIN olist_order_items_dataset AS oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_id -- one row per customer
ORDER BY total_sales DESC
LIMIT 1000 
;

--3. Who are the top 10 most successful sellers?

SELECT
    s.seller_id,
    COUNT(DISTINCT oi.order_id) AS nb_orders, -- orders handled by this seller
    ROUND(SUM(oi.price), 2) AS total_sales,
    ROUND(SUM(oi.price) /NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS average_order_sales -- fixed: was o.order_id, aligned to oi
FROM olist_orders_dataset AS O
LEFT JOIN olist_order_items_dataset AS oi
    ON o.order_id = oi.order_id
LEFT JOIN olist_sellers_dataset AS s
    ON oi.seller_id = s.seller_id
GROUP BY s.seller_id
ORDER BY total_sales DESC
LIMIT 10
;

--4. What's the preferred payment method by product category?
WITH pay_x_cat AS (
    --count orders for each (category, payment_type) pair
    SELECT
    p.product_category_name, 
    pay.payment_type,
    COUNT(DISTINCT o.order_id) AS nb_orders
FROM olist_orders_dataset AS o
JOIN olist_order_items_dataset AS oi
    ON o.order_id = oi.order_id
JOIN olist_products_dataset AS p
    ON oi.product_id = p.product_id
JOIN olist_order_payments_dataset AS pay
    ON o.order_id = pay.order_id
GROUP BY
    p.product_category_name, 
    pay.payment_type
), 

--rank payment types within each category (most used = rank 1)
rank_x_cat AS ( 

SELECT
    product_category_name, 
    payment_type, 
    nb_orders,  
    ROW_NUMBER() OVER (PARTITION BY product_category_name ORDER BY nb_orders DESC) AS rn
FROM pay_x_cat
),
-- keep only the top-ranked payment type per category
SELECT
product_category_name,
payment_type AS preferred_payment_type, 
nb_orders
FROM rank_x_cat
WHERE rn = 1
ORDER BY nb_orders DESC

