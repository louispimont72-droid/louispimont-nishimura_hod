-- Answer all the questions below with advanced SQL queries (partitioning, CASE WHENs)
-- don't forget to add a screenshot of the result from BigQuery directly in the basics/ folder

-- 1. Where are located the clients that ordered more than the average?

WITH customer_spend AS (
    SELECT
        c.customer_id,
        c.customer_city,
        c.customer_state,
        ROUND(SUM(oi.price), 2) AS total_spent
    FROM olist_customers_dataset AS c
    LEFT JOIN olist_orders_dataset AS o
        ON c.customer_id = o.customer_id
    LEFT JOIN olist_order_items_dataset AS oi
        ON o.order_id = oi.order_id
    GROUP BY c.customer_id, c.customer_city, c.customer_state
)

-- keep only customers who spent more than the global average
SELECT
    customer_id,
    customer_city,
    customer_state,
    total_spent
FROM customer_spend
WHERE total_spent > (SELECT AVG(total_spent) FROM customer_spend)
ORDER BY total_spent DESC
;

-- 2. Segment clients in categories based on the amount spent (use CASE WHEN)

SELECT
    c.customer_id,
    c.customer_city,
    ROUND(SUM(oi.price), 2) AS total_spent,
    CASE
        WHEN SUM(oi.price) >= 1000 THEN 'High Spender'   -- top tier
        WHEN SUM(oi.price) >= 300  THEN 'Medium Spender' -- mid tier
        WHEN SUM(oi.price) >= 0    THEN 'Low Spender' -- low tier (includes near-zero)
        ELSE 'No Purchase' -- NULL case: no items linked to orders
    END AS spending_segment
FROM olist_customers_dataset AS c
LEFT JOIN olist_orders_dataset AS o
    ON c.customer_id = o.customer_id
LEFT JOIN olist_order_items_dataset AS oi
    ON o.order_id = oi.order_id
GROUP BY c.customer_id, c.customer_city
ORDER BY total_spent DESC
;

-- 3. Compute the difference in days between the first and last order of a client. Compute then the average (use PARTITION BY)

WITH customer_orders AS (
    SELECT
        c.customer_id,
        DATE(o.order_purchase_timestamp)                            AS order_date,
        MIN(DATE(o.order_purchase_timestamp)) OVER (PARTITION BY c.customer_id) AS first_order,
        MAX(DATE(o.order_purchase_timestamp)) OVER (PARTITION BY c.customer_id) AS last_order
    FROM olist_customers_dataset AS c
    LEFT JOIN olist_orders_dataset AS o
        ON c.customer_id = o.customer_id
),
customer_span AS (

   -- one row per customer → compute span in days
    SELECT
        customer_id,
        first_order,
        last_order,
        DATE_DIFF(last_order, first_order, DAY) AS days_between
    FROM customer_orders
    GROUP BY customer_id, first_order, last_order -- GROUP BY deduplicates rows per customer
)
SELECT
    customer_id,
    first_order,
    last_order,
    days_between,
    ROUND(AVG(days_between) OVER (), 2) AS avg_days_all_customers -- OVER() with no clause = entire result set
FROM customer_span
ORDER BY days_between DESC
;

-- 4. Add a column to the query in basics question 2.: what was their first product category purchased?
--For this question, I used CTE (requête temporaire pour palier au pb d'imbrication des subqueries)

WITH first_category AS (
    SELECT
        o.customer_id,
        p.product_category_name,
        DATE(o.order_purchase_timestamp) AS order_date,
        ROW_NUMBER() OVER (
            PARTITION BY o.customer_id-- restart numbering for each customer
            ORDER BY o.order_purchase_timestamp ASC -- oldest first → rn=1 = first ever order
        ) AS rn
    FROM olist_orders_dataset AS o
    LEFT JOIN olist_order_items_dataset AS oi
        ON o.order_id = oi.order_id
    LEFT JOIN olist_products_dataset AS p
        ON oi.product_id = p.product_id
)
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    DATE(o.order_delivered_customer_date) AS delivery_date,
    fc.product_category_name              AS first_category_purchased -- from CTE, rn=1 only
FROM olist_customers_dataset AS c
LEFT JOIN olist_orders_dataset AS o
    ON c.customer_id = o.customer_id
LEFT JOIN first_category AS fc
    ON c.customer_id = fc.customer_id
    AND fc.rn = 1 -- only keep the first-ever order's category
WHERE o.order_status = 'delivered'
ORDER BY delivery_date DESC
LIMIT 5
;