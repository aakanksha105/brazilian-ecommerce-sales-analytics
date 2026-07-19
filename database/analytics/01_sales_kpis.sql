-- ============================================================
-- Phase 6: SQL Business Analytics
-- File: 01_sales_kpis.sql
-- Purpose: Core executive sales and order KPIs
-- ============================================================


-- 1. Total number of orders

SELECT
    COUNT(*) AS total_orders
FROM ecommerce.orders;


-- 2. Delivered orders

SELECT
    COUNT(*) AS delivered_orders
FROM ecommerce.orders
WHERE order_status = 'delivered';


-- 3. Delivery rate

SELECT
    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS delivery_rate_pct
FROM ecommerce.orders;


-- 4. Total product revenue

SELECT
    ROUND(
        SUM(price),
        2
    ) AS total_product_revenue
FROM ecommerce.order_items;


-- 5. Total freight value

SELECT
    ROUND(
        SUM(freight_value),
        2
    ) AS total_freight_value
FROM ecommerce.order_items;


-- 6. Total customer payment value

SELECT
    ROUND(
        SUM(payment_value),
        2
    ) AS total_payment_value
FROM ecommerce.payments;


-- 7. Average order value

WITH order_revenue AS (
    SELECT
        order_id,
        SUM(price) AS product_revenue
    FROM ecommerce.order_items
    GROUP BY order_id
)

SELECT
    ROUND(
        AVG(product_revenue),
        2
    ) AS average_order_value
FROM order_revenue;


-- 8. Average items per order

SELECT
    ROUND(
        COUNT(*)::NUMERIC
        / NULLIF(
            COUNT(DISTINCT order_id),
            0
        ),
        2
    ) AS average_items_per_order
FROM ecommerce.order_items;


-- 9. Unique customers

SELECT
    COUNT(
        DISTINCT customer_unique_id
    ) AS unique_customers
FROM ecommerce.customers;


-- 10. Repeat customer rate

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM analytics.order_summary
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
)

SELECT
    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE order_count >= 2
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_rate_pct
FROM customer_orders;


-- 11. Average review score

SELECT
    ROUND(
        AVG(review_score),
        2
    ) AS average_review_score
FROM ecommerce.reviews;


-- 12. Average delivery time for delivered orders

SELECT
    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days
FROM ecommerce.orders
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL;


-- 13. Late delivery rate

SELECT
    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE late_delivery = TRUE
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE delivery_difference_days
                IS NOT NULL
            ),
            0
        ),
        2
    ) AS late_delivery_rate_pct
FROM ecommerce.orders;


-- 14. Overall KPI summary in one row

WITH order_metrics AS (
    SELECT
        COUNT(*) AS total_orders,
        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) AS delivered_orders,
        COUNT(DISTINCT customer_unique_id)
            AS unique_customers,
        AVG(delivery_days) FILTER (
            WHERE order_status = 'delivered'
              AND delivery_days IS NOT NULL
        ) AS avg_delivery_days,
        COUNT(*) FILTER (
            WHERE late_delivery = TRUE
        ) AS late_orders,
        COUNT(*) FILTER (
            WHERE delivery_difference_days
            IS NOT NULL
        ) AS completed_delivery_records
    FROM analytics.order_summary
),

revenue_metrics AS (
    SELECT
        SUM(product_revenue) AS total_revenue,
        AVG(product_revenue) AS average_order_value
    FROM analytics.order_summary
    WHERE product_revenue IS NOT NULL
),

review_metrics AS (
    SELECT
        AVG(review_score) AS average_review_score
    FROM ecommerce.reviews
)

SELECT
    om.total_orders,
    om.delivered_orders,

    ROUND(
        100.0
        * om.delivered_orders
        / NULLIF(om.total_orders, 0),
        2
    ) AS delivery_rate_pct,

    om.unique_customers,

    ROUND(
        rm.total_revenue,
        2
    ) AS total_product_revenue,

    ROUND(
        rm.average_order_value,
        2
    ) AS average_order_value,

    ROUND(
        om.avg_delivery_days,
        2
    ) AS average_delivery_days,

    ROUND(
        100.0
        * om.late_orders
        / NULLIF(
            om.completed_delivery_records,
            0
        ),
        2
    ) AS late_delivery_rate_pct,

    ROUND(
        rv.average_review_score,
        2
    ) AS average_review_score

FROM order_metrics om
CROSS JOIN revenue_metrics rm
CROSS JOIN review_metrics rv;