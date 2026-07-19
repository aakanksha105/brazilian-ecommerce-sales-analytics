-- ============================================================
-- Phase 6: SQL Business Analytics
-- File: 03_customer_analysis.sql
-- Purpose: Customer behavior, repeat purchases, value, geography
-- ============================================================


-- 1. Unique customers with delivered orders

SELECT
    COUNT(DISTINCT customer_unique_id) AS delivered_customers
FROM analytics.order_summary
WHERE order_status = 'delivered';


-- 2. Customer order-frequency distribution

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM analytics.order_summary
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
)

SELECT
    order_count,
    COUNT(*) AS customers
FROM customer_orders
GROUP BY order_count
ORDER BY order_count;


-- 3. Repeat-customer rate

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM analytics.order_summary
    WHERE order_status = 'delivered'
    GROUP BY customer_unique_id
)

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE order_count >= 2
    ) AS repeat_customers,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE order_count >= 2
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS repeat_customer_rate_pct

FROM customer_orders;


-- 4. Top 20 customers by delivered revenue

SELECT
    customer_unique_id,

    COUNT(DISTINCT order_id) AS delivered_orders,

    ROUND(
        SUM(product_revenue),
        2
    ) AS total_revenue,

    ROUND(
        AVG(product_revenue),
        2
    ) AS average_order_value,

    SUM(item_count) AS total_items

FROM analytics.order_summary

WHERE order_status = 'delivered'
  AND product_revenue IS NOT NULL

GROUP BY customer_unique_id

ORDER BY total_revenue DESC

LIMIT 20;


-- 5. Customer value ranking using DENSE_RANK

WITH customer_value AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS delivered_orders,
        SUM(product_revenue) AS total_revenue
    FROM analytics.order_summary
    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL
    GROUP BY customer_unique_id
)

SELECT
    customer_unique_id,
    delivered_orders,

    ROUND(
        total_revenue,
        2
    ) AS total_revenue,

    DENSE_RANK() OVER (
        ORDER BY total_revenue DESC
    ) AS customer_revenue_rank

FROM customer_value

ORDER BY customer_revenue_rank

LIMIT 50;


-- 6. Customer spending quartiles using NTILE

WITH customer_value AS (
    SELECT
        customer_unique_id,
        SUM(product_revenue) AS total_revenue
    FROM analytics.order_summary
    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL
    GROUP BY customer_unique_id
),

customer_quartiles AS (
    SELECT
        customer_unique_id,
        total_revenue,

        NTILE(4) OVER (
            ORDER BY total_revenue DESC
        ) AS spending_quartile

    FROM customer_value
)

SELECT
    spending_quartile,
    COUNT(*) AS customers,

    ROUND(
        MIN(total_revenue),
        2
    ) AS minimum_revenue,

    ROUND(
        MAX(total_revenue),
        2
    ) AS maximum_revenue,

    ROUND(
        AVG(total_revenue),
        2
    ) AS average_revenue

FROM customer_quartiles

GROUP BY spending_quartile

ORDER BY spending_quartile;


-- 7. Customer revenue contribution by quartile

WITH customer_value AS (
    SELECT
        customer_unique_id,
        SUM(product_revenue) AS total_revenue
    FROM analytics.order_summary
    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL
    GROUP BY customer_unique_id
),

customer_quartiles AS (
    SELECT
        customer_unique_id,
        total_revenue,

        NTILE(4) OVER (
            ORDER BY total_revenue DESC
        ) AS spending_quartile

    FROM customer_value
),

quartile_summary AS (
    SELECT
        spending_quartile,
        COUNT(*) AS customers,
        SUM(total_revenue) AS quartile_revenue
    FROM customer_quartiles
    GROUP BY spending_quartile
)

SELECT
    spending_quartile,
    customers,

    ROUND(
        quartile_revenue,
        2
    ) AS quartile_revenue,

    ROUND(
        100.0
        * quartile_revenue
        / SUM(quartile_revenue) OVER (),
        2
    ) AS revenue_share_pct

FROM quartile_summary

ORDER BY spending_quartile;


-- 8. Customer acquisition by month

WITH first_purchase AS (
    SELECT
        customer_unique_id,

        MIN(
            order_purchase_timestamp
        ) AS first_purchase_timestamp

    FROM analytics.order_summary

    WHERE order_status = 'delivered'

    GROUP BY customer_unique_id
)

SELECT
    DATE_TRUNC(
        'month',
        first_purchase_timestamp
    )::DATE AS acquisition_month,

    COUNT(*) AS new_customers

FROM first_purchase

GROUP BY acquisition_month

ORDER BY acquisition_month;

-- 9. Customer acquisition by state

WITH first_customer_location AS (
    SELECT DISTINCT ON (customer_unique_id)
        customer_unique_id,
        customer_state,
        order_purchase_timestamp

    FROM analytics.order_summary

    WHERE order_status = 'delivered'

    ORDER BY
        customer_unique_id,
        order_purchase_timestamp
)

SELECT
    customer_state,
    COUNT(*) AS customers

FROM first_customer_location

GROUP BY customer_state

ORDER BY customers DESC;


-- 10. Average customer value by state

WITH customer_state_value AS (
    SELECT
        customer_unique_id,
        customer_state,

        COUNT(DISTINCT order_id) AS delivered_orders,

        SUM(product_revenue) AS total_revenue

    FROM analytics.order_summary

    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL

    GROUP BY
        customer_unique_id,
        customer_state
)

SELECT
    customer_state,

    COUNT(DISTINCT customer_unique_id)
        AS customers,

    ROUND(
        AVG(total_revenue),
        2
    ) AS average_customer_revenue,

    ROUND(
        AVG(delivered_orders),
        2
    ) AS average_orders_per_customer

FROM customer_state_value

GROUP BY customer_state

ORDER BY average_customer_revenue DESC;


-- 11. Customer lifespan and repeat behavior

SELECT
    repeat_customer,

    COUNT(*) AS customers,

    ROUND(
        AVG(total_orders),
        2
    ) AS average_orders,

    ROUND(
        AVG(total_revenue),
        2
    ) AS average_revenue,

    ROUND(
        AVG(
            EXTRACT(
                DAY FROM customer_lifespan
            )
        ),
        2
    ) AS average_lifespan_days

FROM analytics.customer_summary

GROUP BY repeat_customer

ORDER BY repeat_customer DESC;


-- 12. Customers with the longest observed lifespan

SELECT
    customer_unique_id,
    first_purchase,
    last_purchase,
    total_orders,

    EXTRACT(
        DAY FROM customer_lifespan
    ) AS customer_lifespan_days,

    ROUND(
        total_revenue,
        2
    ) AS total_revenue

FROM analytics.customer_summary

ORDER BY customer_lifespan DESC

LIMIT 20;


-- 13. Customer satisfaction by order frequency

WITH customer_metrics AS (
    SELECT
        customer_unique_id,

        COUNT(DISTINCT order_id)
            AS delivered_orders,

        AVG(average_review_score)
            AS customer_review_score

    FROM analytics.order_summary

    WHERE order_status = 'delivered'

    GROUP BY customer_unique_id
),

frequency_groups AS (
    SELECT
        customer_unique_id,
        delivered_orders,
        customer_review_score,

        CASE
            WHEN delivered_orders = 1
                THEN 'One-time customer'
            WHEN delivered_orders BETWEEN 2 AND 3
                THEN '2–3 orders'
            WHEN delivered_orders BETWEEN 4 AND 5
                THEN '4–5 orders'
            ELSE '6+ orders'
        END AS frequency_group

    FROM customer_metrics
)

SELECT
    frequency_group,

    COUNT(*) AS customers,

    ROUND(
        AVG(customer_review_score),
        2
    ) AS average_review_score

FROM frequency_groups

GROUP BY frequency_group

ORDER BY
    MIN(delivered_orders);


-- 14. Customer value segmentation

WITH customer_value AS (
    SELECT
        customer_unique_id,

        COUNT(DISTINCT order_id)
            AS delivered_orders,

        SUM(product_revenue)
            AS total_revenue

    FROM analytics.order_summary

    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL

    GROUP BY customer_unique_id
),

segmented_customers AS (
    SELECT
        customer_unique_id,
        delivered_orders,
        total_revenue,

        CASE
            WHEN delivered_orders >= 2
                 AND total_revenue >= 500
                THEN 'High-value repeat'

            WHEN delivered_orders >= 2
                THEN 'Repeat customer'

            WHEN total_revenue >= 500
                THEN 'High-value one-time'

            ELSE 'Standard one-time'
        END AS customer_segment

    FROM customer_value
)

SELECT
    customer_segment,

    COUNT(*) AS customers,

    ROUND(
        SUM(total_revenue),
        2
    ) AS segment_revenue,

    ROUND(
        AVG(total_revenue),
        2
    ) AS average_customer_revenue

FROM segmented_customers

GROUP BY customer_segment

ORDER BY segment_revenue DESC;