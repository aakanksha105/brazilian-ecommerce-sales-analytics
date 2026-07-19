-- ============================================================
-- Phase 6: SQL Business Analytics
-- File: 05_delivery_analysis.sql
-- Purpose: Delivery speed, lateness, geography, and satisfaction
-- ============================================================


-- 1. Average delivery time for delivered orders

SELECT
    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days
FROM ecommerce.orders
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL;


-- 2. Median delivery time

SELECT
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY delivery_days
        )::NUMERIC,
        2
    ) AS median_delivery_days
FROM ecommerce.orders
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL;


-- 3. Delivery-time percentiles

SELECT
    ROUND(
        PERCENTILE_CONT(0.25)
        WITHIN GROUP (
            ORDER BY delivery_days
        )::NUMERIC,
        2
    ) AS p25_delivery_days,

    ROUND(
        PERCENTILE_CONT(0.50)
        WITHIN GROUP (
            ORDER BY delivery_days
        )::NUMERIC,
        2
    ) AS p50_delivery_days,

    ROUND(
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (
            ORDER BY delivery_days
        )::NUMERIC,
        2
    ) AS p75_delivery_days,

    ROUND(
        PERCENTILE_CONT(0.90)
        WITHIN GROUP (
            ORDER BY delivery_days
        )::NUMERIC,
        2
    ) AS p90_delivery_days,

    ROUND(
        PERCENTILE_CONT(0.95)
        WITHIN GROUP (
            ORDER BY delivery_days
        )::NUMERIC,
        2
    ) AS p95_delivery_days
FROM ecommerce.orders
WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL;


-- 4. Late-delivery rate

SELECT
    COUNT(*) FILTER (
        WHERE late_delivery = TRUE
    ) AS late_orders,

    COUNT(*) FILTER (
        WHERE delivery_difference_days IS NOT NULL
    ) AS delivered_orders_with_dates,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE late_delivery = TRUE
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE delivery_difference_days IS NOT NULL
            ),
            0
        ),
        2
    ) AS late_delivery_rate_pct

FROM ecommerce.orders;


-- 5. Average days early or late

SELECT
    ROUND(
        AVG(delivery_difference_days),
        2
    ) AS average_days_early_or_late,

    ROUND(
        AVG(delivery_difference_days)
        FILTER (
            WHERE late_delivery = TRUE
        ),
        2
    ) AS average_late_days,

    ROUND(
        AVG(delivery_difference_days)
        FILTER (
            WHERE late_delivery = FALSE
        ),
        2
    ) AS average_days_early

FROM ecommerce.orders
WHERE delivery_difference_days IS NOT NULL;


-- 6. Delivery performance by customer state

SELECT
    c.customer_state,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(o.delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE o.late_delivery = TRUE
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM ecommerce.orders o

JOIN ecommerce.customers c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'
  AND o.delivery_days IS NOT NULL

GROUP BY c.customer_state

ORDER BY average_delivery_days DESC;


-- 7. Delivery performance by customer city

SELECT
    c.customer_city,
    c.customer_state,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(o.delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE o.late_delivery = TRUE
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM ecommerce.orders o

JOIN ecommerce.customers c
    ON o.customer_id = c.customer_id

WHERE o.order_status = 'delivered'
  AND o.delivery_days IS NOT NULL

GROUP BY
    c.customer_city,
    c.customer_state

HAVING COUNT(*) >= 100

ORDER BY late_delivery_rate_pct DESC

LIMIT 25;


-- 8. Monthly delivery performance

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::DATE AS purchase_month_date,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE late_delivery = TRUE
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM ecommerce.orders

WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL

GROUP BY 1

ORDER BY 1;

-- 9. Delivery speed by weekday

SELECT
    purchase_day_name,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE late_delivery = TRUE
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM ecommerce.orders

WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL

GROUP BY purchase_day_name

ORDER BY average_delivery_days;


-- 10. Delivery speed by purchase hour

SELECT
    purchase_hour,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days

FROM ecommerce.orders

WHERE order_status = 'delivered'
  AND delivery_days IS NOT NULL

GROUP BY purchase_hour

ORDER BY purchase_hour;


-- 11. Delivery performance and review scores

SELECT
    CASE
        WHEN o.late_delivery = TRUE
            THEN 'Late'
        WHEN o.late_delivery = FALSE
            THEN 'On time or early'
        ELSE 'Unknown'
    END AS delivery_status,

    COUNT(*) AS review_records,

    ROUND(
        AVG(r.review_score),
        2
    ) AS average_review_score,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE r.review_score >= 4
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS positive_review_rate_pct,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE r.review_score <= 2
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS negative_review_rate_pct

FROM ecommerce.orders o

JOIN ecommerce.reviews r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.delivery_difference_days IS NOT NULL

GROUP BY delivery_status

ORDER BY delivery_status;


-- 12. Review score by delay bucket

SELECT
    CASE
        WHEN o.delivery_difference_days <= -10
            THEN '10+ days early'
        WHEN o.delivery_difference_days BETWEEN -9.99 AND -1
            THEN '1–9 days early'
        WHEN o.delivery_difference_days BETWEEN -0.99 AND 0
            THEN 'On estimated date'
        WHEN o.delivery_difference_days BETWEEN 0.01 AND 3
            THEN '1–3 days late'
        WHEN o.delivery_difference_days BETWEEN 3.01 AND 7
            THEN '4–7 days late'
        ELSE '8+ days late'
    END AS delivery_bucket,

    COUNT(*) AS review_records,

    ROUND(
        AVG(r.review_score),
        2
    ) AS average_review_score

FROM ecommerce.orders o

JOIN ecommerce.reviews r
    ON o.order_id = r.order_id

WHERE o.order_status = 'delivered'
  AND o.delivery_difference_days IS NOT NULL

GROUP BY delivery_bucket

ORDER BY
    MIN(o.delivery_difference_days);


-- 13. Approval time and delivery performance

WITH approval_groups AS (
    SELECT
        order_id,
        delivery_days,
        late_delivery,
        approval_hours,

        CASE
            WHEN approval_hours < 1
                THEN 'Under 1 hour'
            WHEN approval_hours < 6
                THEN '1–6 hours'
            WHEN approval_hours < 24
                THEN '6–24 hours'
            ELSE '24+ hours'
        END AS approval_group

    FROM ecommerce.orders

    WHERE order_status = 'delivered'
      AND approval_hours IS NOT NULL
      AND delivery_days IS NOT NULL
)

SELECT
    approval_group,

    COUNT(*) AS delivered_orders,

    ROUND(
        AVG(approval_hours),
        2
    ) AS average_approval_hours,

    ROUND(
        AVG(delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE late_delivery = TRUE
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM approval_groups

GROUP BY approval_group

ORDER BY MIN(approval_hours);


-- 14. Products with the longest delivery times

SELECT
    oi.product_id,

    COUNT(*) AS delivered_items,

    ROUND(
        AVG(o.delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE o.late_delivery = TRUE
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM ecommerce.order_items oi

JOIN ecommerce.orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'delivered'
  AND o.delivery_days IS NOT NULL

GROUP BY oi.product_id

HAVING COUNT(*) >= 20

ORDER BY average_delivery_days DESC

LIMIT 25;


-- 15. Seller delivery performance

SELECT
    oi.seller_id,
    s.seller_city,
    s.seller_state,

    COUNT(DISTINCT oi.order_id) AS delivered_orders,

    ROUND(
        AVG(o.delivery_days),
        2
    ) AS average_delivery_days,

    ROUND(
        100.0
        * COUNT(DISTINCT oi.order_id)
            FILTER (
                WHERE o.late_delivery = TRUE
            )
        / NULLIF(
            COUNT(DISTINCT oi.order_id),
            0
        ),
        2
    ) AS late_delivery_rate_pct

FROM ecommerce.order_items oi

JOIN ecommerce.orders o
    ON oi.order_id = o.order_id

JOIN ecommerce.sellers s
    ON oi.seller_id = s.seller_id

WHERE o.order_status = 'delivered'
  AND o.delivery_days IS NOT NULL

GROUP BY
    oi.seller_id,
    s.seller_city,
    s.seller_state

HAVING COUNT(DISTINCT oi.order_id) >= 30

ORDER BY late_delivery_rate_pct DESC

LIMIT 30;