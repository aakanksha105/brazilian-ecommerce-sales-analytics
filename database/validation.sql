-- ============================================================
-- Phase 5 Database Validation
-- ============================================================

-- 1. Row counts
SELECT 'category_translation' AS table_name, COUNT(*) AS row_count
FROM ecommerce.category_translation

UNION ALL
SELECT 'customers', COUNT(*) FROM ecommerce.customers

UNION ALL
SELECT 'geolocation', COUNT(*) FROM ecommerce.geolocation

UNION ALL
SELECT 'order_items', COUNT(*) FROM ecommerce.order_items

UNION ALL
SELECT 'orders', COUNT(*) FROM ecommerce.orders

UNION ALL
SELECT 'payments', COUNT(*) FROM ecommerce.payments

UNION ALL
SELECT 'products', COUNT(*) FROM ecommerce.products

UNION ALL
SELECT 'reviews', COUNT(*) FROM ecommerce.reviews

UNION ALL
SELECT 'sellers', COUNT(*) FROM ecommerce.sellers

ORDER BY table_name;


-- 2. Primary-key uniqueness checks
SELECT
    COUNT(*) AS customer_rows,
    COUNT(DISTINCT customer_id) AS unique_customer_ids
FROM ecommerce.customers;

SELECT
    COUNT(*) AS order_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids
FROM ecommerce.orders;

SELECT
    COUNT(*) AS product_rows,
    COUNT(DISTINCT product_id) AS unique_product_ids
FROM ecommerce.products;

SELECT
    COUNT(*) AS seller_rows,
    COUNT(DISTINCT seller_id) AS unique_seller_ids
FROM ecommerce.sellers;


-- 3. Foreign-key validation
SELECT COUNT(*) AS orders_without_customer
FROM ecommerce.orders o
LEFT JOIN ecommerce.customers c
    ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS items_without_order
FROM ecommerce.order_items oi
LEFT JOIN ecommerce.orders o
    ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS items_without_product
FROM ecommerce.order_items oi
LEFT JOIN ecommerce.products p
    ON oi.product_id = p.product_id
WHERE p.product_id IS NULL;

SELECT COUNT(*) AS items_without_seller
FROM ecommerce.order_items oi
LEFT JOIN ecommerce.sellers s
    ON oi.seller_id = s.seller_id
WHERE s.seller_id IS NULL;

SELECT COUNT(*) AS payments_without_order
FROM ecommerce.payments p
LEFT JOIN ecommerce.orders o
    ON p.order_id = o.order_id
WHERE o.order_id IS NULL;

SELECT COUNT(*) AS reviews_without_order
FROM ecommerce.reviews r
LEFT JOIN ecommerce.orders o
    ON r.order_id = o.order_id
WHERE o.order_id IS NULL;


-- 4. Basic business checks
SELECT
    order_status,
    COUNT(*) AS orders
FROM ecommerce.orders
GROUP BY order_status
ORDER BY orders DESC;

SELECT
    MIN(order_purchase_timestamp) AS first_order,
    MAX(order_purchase_timestamp) AS last_order
FROM ecommerce.orders;

SELECT
    ROUND(SUM(price), 2) AS product_revenue,
    ROUND(SUM(freight_value), 2) AS freight_revenue
FROM ecommerce.order_items;

SELECT
    ROUND(AVG(review_score), 2) AS average_review_score
FROM ecommerce.reviews;


-- 5. Sample joined records
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    COUNT(oi.order_item_id) AS item_count,
    ROUND(SUM(oi.price), 2) AS product_revenue,
    ROUND(SUM(oi.freight_value), 2) AS freight_value
FROM ecommerce.orders o
JOIN ecommerce.customers c
    ON o.customer_id = c.customer_id
LEFT JOIN ecommerce.order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state
ORDER BY o.order_purchase_timestamp
LIMIT 10;
