-- ============================================================
-- Analytical Views
-- ============================================================

DROP VIEW IF EXISTS analytics.order_summary CASCADE;
DROP VIEW IF EXISTS analytics.customer_summary CASCADE;


CREATE VIEW analytics.order_summary AS
WITH item_summary AS (
    SELECT
        order_id,
        SUM(price) AS product_revenue,
        SUM(freight_value) AS freight_value,
        SUM(item_total_value) AS total_item_value,
        COUNT(*) AS item_count,
        COUNT(DISTINCT product_id) AS distinct_products,
        COUNT(DISTINCT seller_id) AS distinct_sellers
    FROM ecommerce.order_items
    GROUP BY order_id
),
payment_summary AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment,
        COUNT(*) AS payment_records,
        COUNT(DISTINCT payment_type) AS payment_methods,
        MAX(payment_installments) AS max_installments
    FROM ecommerce.payments
    GROUP BY order_id
),
review_summary AS (
    SELECT
        order_id,
        AVG(review_score) AS average_review_score,
        COUNT(*) AS review_count
    FROM ecommerce.reviews
    GROUP BY order_id
)
SELECT
    o.order_id,
    o.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    o.purchase_date,
    o.purchase_year,
    o.purchase_month,
    o.purchase_quarter,
    o.purchase_year_month,
    o.purchase_day_name,
    o.purchase_hour,
    o.approval_hours,
    o.delivery_days,
    o.estimated_delivery_days,
    o.delivery_difference_days,
    o.late_delivery,
    i.product_revenue,
    i.freight_value,
    i.total_item_value,
    i.item_count,
    i.distinct_products,
    i.distinct_sellers,
    p.total_payment,
    p.payment_records,
    p.payment_methods,
    p.max_installments,
    r.average_review_score,
    r.review_count
FROM ecommerce.orders o
LEFT JOIN ecommerce.customers c
    ON o.customer_id = c.customer_id
LEFT JOIN item_summary i
    ON o.order_id = i.order_id
LEFT JOIN payment_summary p
    ON o.order_id = p.order_id
LEFT JOIN review_summary r
    ON o.order_id = r.order_id;


CREATE VIEW analytics.customer_summary AS
SELECT
    customer_unique_id,
    MIN(order_purchase_timestamp) AS first_purchase,
    MAX(order_purchase_timestamp) AS last_purchase,
    COUNT(DISTINCT order_id) AS total_orders,
    SUM(product_revenue) AS total_revenue,
    SUM(total_payment) AS total_payment,
    SUM(item_count) AS total_items,
    AVG(average_review_score) AS average_review_score,
    SUM(
        CASE
            WHEN late_delivery = TRUE THEN 1
            ELSE 0
        END
    ) AS late_orders,
    ROUND(
        SUM(product_revenue)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS average_order_value,
    MAX(order_purchase_timestamp)
        - MIN(order_purchase_timestamp)
        AS customer_lifespan,
    CASE
        WHEN COUNT(DISTINCT order_id) >= 2
        THEN TRUE
        ELSE FALSE
    END AS repeat_customer
FROM analytics.order_summary
WHERE order_status = 'delivered'
GROUP BY customer_unique_id;