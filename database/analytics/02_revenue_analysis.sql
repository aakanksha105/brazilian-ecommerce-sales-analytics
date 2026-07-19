-- ============================================================
-- Phase 6: SQL Business Analytics
-- File: 02_revenue_analysis.sql
-- Purpose: Revenue trends, growth, geography, categories, sellers
-- ============================================================


-- 1. Monthly delivered product revenue

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::DATE AS revenue_month,

    ROUND(
        SUM(product_revenue),
        2
    ) AS product_revenue,

    COUNT(DISTINCT order_id) AS delivered_orders

FROM analytics.order_summary

WHERE order_status = 'delivered'
  AND product_revenue IS NOT NULL

GROUP BY revenue_month

ORDER BY revenue_month;


-- 2. Monthly average order value

SELECT
    DATE_TRUNC(
        'month',
        order_purchase_timestamp
    )::DATE AS revenue_month,

    ROUND(
        AVG(product_revenue),
        2
    ) AS average_order_value,

    COUNT(DISTINCT order_id) AS delivered_orders

FROM analytics.order_summary

WHERE order_status = 'delivered'
  AND product_revenue IS NOT NULL

GROUP BY revenue_month

ORDER BY revenue_month;


-- 3. Monthly revenue growth using LAG

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::DATE AS revenue_month,

        SUM(product_revenue) AS revenue

    FROM analytics.order_summary

    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL

    GROUP BY revenue_month
),

revenue_with_previous AS (
    SELECT
        revenue_month,
        revenue,

        LAG(revenue) OVER (
            ORDER BY revenue_month
        ) AS previous_month_revenue

    FROM monthly_revenue
)

SELECT
    revenue_month,

    ROUND(
        revenue,
        2
    ) AS revenue,

    ROUND(
        previous_month_revenue,
        2
    ) AS previous_month_revenue,

    ROUND(
        100.0
        * (
            revenue
            - previous_month_revenue
        )
        / NULLIF(
            previous_month_revenue,
            0
        ),
        2
    ) AS month_over_month_growth_pct

FROM revenue_with_previous

ORDER BY revenue_month;


-- 4. Cumulative revenue using a window function

WITH monthly_revenue AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::DATE AS revenue_month,

        SUM(product_revenue) AS revenue

    FROM analytics.order_summary

    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL

    GROUP BY revenue_month
)

SELECT
    revenue_month,

    ROUND(
        revenue,
        2
    ) AS monthly_revenue,

    ROUND(
        SUM(revenue) OVER (
            ORDER BY revenue_month
            ROWS BETWEEN
                UNBOUNDED PRECEDING
                AND CURRENT ROW
        ),
        2
    ) AS cumulative_revenue

FROM monthly_revenue

ORDER BY revenue_month;


-- 5. Revenue by customer state

SELECT
    customer_state,

    COUNT(DISTINCT order_id) AS delivered_orders,

    ROUND(
        SUM(product_revenue),
        2
    ) AS product_revenue,

    ROUND(
        AVG(product_revenue),
        2
    ) AS average_order_value

FROM analytics.order_summary

WHERE order_status = 'delivered'
  AND product_revenue IS NOT NULL

GROUP BY customer_state

ORDER BY product_revenue DESC;


-- 6. Top 15 customer cities by revenue

SELECT
    customer_city,
    customer_state,

    COUNT(DISTINCT order_id) AS delivered_orders,

    ROUND(
        SUM(product_revenue),
        2
    ) AS product_revenue

FROM analytics.order_summary

WHERE order_status = 'delivered'
  AND product_revenue IS NOT NULL

GROUP BY
    customer_city,
    customer_state

ORDER BY product_revenue DESC

LIMIT 15;


-- 7. Revenue by translated product category

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    COUNT(*) AS units_sold,

    COUNT(
        DISTINCT oi.order_id
    ) AS orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS product_revenue,

    ROUND(
        AVG(oi.price),
        2
    ) AS average_item_price

FROM ecommerce.order_items oi

JOIN ecommerce.orders o
    ON oi.order_id = o.order_id

JOIN ecommerce.products p
    ON oi.product_id = p.product_id

LEFT JOIN ecommerce.category_translation ct
    ON p.product_category_name
       = ct.product_category_name

WHERE o.order_status = 'delivered'

GROUP BY product_category

ORDER BY product_revenue DESC

LIMIT 20;


-- 8. Revenue concentration among product categories

WITH category_revenue AS (
    SELECT
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS product_category,

        SUM(oi.price) AS revenue

    FROM ecommerce.order_items oi

    JOIN ecommerce.orders o
        ON oi.order_id = o.order_id

    JOIN ecommerce.products p
        ON oi.product_id = p.product_id

    LEFT JOIN ecommerce.category_translation ct
        ON p.product_category_name
           = ct.product_category_name

    WHERE o.order_status = 'delivered'

    GROUP BY product_category
),

ranked_categories AS (
    SELECT
        product_category,
        revenue,

        DENSE_RANK() OVER (
            ORDER BY revenue DESC
        ) AS revenue_rank,

        SUM(revenue) OVER () AS total_revenue

    FROM category_revenue
)

SELECT
    product_category,
    revenue_rank,

    ROUND(
        revenue,
        2
    ) AS revenue,

    ROUND(
        100.0
        * revenue
        / NULLIF(total_revenue, 0),
        2
    ) AS revenue_share_pct

FROM ranked_categories

ORDER BY revenue_rank

LIMIT 20;


-- 9. Top 20 sellers by delivered revenue

SELECT
    oi.seller_id,
    s.seller_city,
    s.seller_state,

    COUNT(
        DISTINCT oi.order_id
    ) AS delivered_orders,

    COUNT(*) AS items_sold,

    ROUND(
        SUM(oi.price),
        2
    ) AS product_revenue,

    ROUND(
        AVG(oi.price),
        2
    ) AS average_item_price

FROM ecommerce.order_items oi

JOIN ecommerce.orders o
    ON oi.order_id = o.order_id

JOIN ecommerce.sellers s
    ON oi.seller_id = s.seller_id

WHERE o.order_status = 'delivered'

GROUP BY
    oi.seller_id,
    s.seller_city,
    s.seller_state

ORDER BY product_revenue DESC

LIMIT 20;


-- 10. Seller revenue ranking within each state

WITH seller_revenue AS (
    SELECT
        s.seller_state,
        oi.seller_id,

        SUM(oi.price) AS revenue

    FROM ecommerce.order_items oi

    JOIN ecommerce.orders o
        ON oi.order_id = o.order_id

    JOIN ecommerce.sellers s
        ON oi.seller_id = s.seller_id

    WHERE o.order_status = 'delivered'

    GROUP BY
        s.seller_state,
        oi.seller_id
),

ranked_sellers AS (
    SELECT
        seller_state,
        seller_id,
        revenue,

        DENSE_RANK() OVER (
            PARTITION BY seller_state
            ORDER BY revenue DESC
        ) AS seller_rank_in_state

    FROM seller_revenue
)

SELECT
    seller_state,
    seller_id,
    seller_rank_in_state,

    ROUND(
        revenue,
        2
    ) AS revenue

FROM ranked_sellers

WHERE seller_rank_in_state <= 3

ORDER BY
    seller_state,
    seller_rank_in_state;


-- 11. Revenue by year and quarter

SELECT
    purchase_year,
    purchase_quarter,

    COUNT(
        DISTINCT order_id
    ) AS delivered_orders,

    ROUND(
        SUM(product_revenue),
        2
    ) AS product_revenue,

    ROUND(
        AVG(product_revenue),
        2
    ) AS average_order_value

FROM analytics.order_summary

WHERE order_status = 'delivered'
  AND product_revenue IS NOT NULL

GROUP BY
    purchase_year,
    purchase_quarter

ORDER BY
    purchase_year,
    purchase_quarter;


-- 12. Freight as a share of item value

SELECT
    ROUND(
        SUM(freight_value),
        2
    ) AS total_freight_value,

    ROUND(
        SUM(price),
        2
    ) AS total_product_revenue,

    ROUND(
        100.0
        * SUM(freight_value)
        / NULLIF(
            SUM(price),
            0
        ),
        2
    ) AS freight_to_revenue_pct

FROM ecommerce.order_items;