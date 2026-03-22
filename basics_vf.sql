-- Answer all the questions below with basics SQL queries
-- don't forget to add a screenshot of the result from BigQuery directly in the basics/ folder

--1. What are the possible values of an order status?
SELECT
    DISTINCT order_status
FROM olist_orders_dataset

--2. Who are the 5 last customers that purchased a DELIVERED order (order with status DELIVERED)? 
print their customer_id, their unique_id, and city

SELECT
    c.customer_id, 
    c.customer_unique_id, 
    c.customer_city,
    DATE(o.order_delivered_customer_date) AS delivery_date
FROM olist_customers_dataset AS c
LEFT JOIN olist_orders_dataset AS o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered' -- keep only delivered orders
ORDER BY delivery_date DESC -- most recent first
LIMIT 5 -- top 5 only
;

--3. Add a column is_sp which returns 1 if the customer is from São Paulo and O otherwise

SELECT
    c.customer_id, 
    c.customer_unique_id, 
    c.customer_city,
    CASE
        WHEN c.customer_city LIKE 'sao paulo' THEN 1 -- São Paulo stored without accent in DB
    ELSE 0  
    END AS is_sp
FROM olist_customers_dataset As c
;
--4. add a new column: what's the product category associated to the order?

SELECT
    c.customer_id, 
    c.customer_unique_id, 
    c.customer_city,
    CASE
        WHEN c.customer_city LIKE 'sao paulo' THEN 1
        ELSE 0  
        END AS is_sp,
    p.product_category_name
FROM olist_customers_dataset AS c
LEFT JOIN olist_orders_dataset AS o
    ON c.customer_id = o.customer_id -- link customer to their orders
LEFT JOIN olist_order_items_dataset AS oi
    ON o.order_id = oi.order_id -- link order to its items
LEFT JOIN olist_products_dataset AS P
    ON oi.product_id = p.product_id -- link item to its product category
