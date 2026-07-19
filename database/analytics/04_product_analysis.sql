-- ============================================================
-- Phase 6: SQL Business Analytics
-- File: 04_product_analysis.sql
-- Purpose: Product, category, pricing, freight, and seller analysis
-- ============================================================


-- 1. Total products and categories

SELECT
    COUNT(DISTINCT product_id) AS total_products,
    COUNT(DISTINCT product_category_name) AS total_categories
FROM ecommerce.products;


-- 2. Products by translated category

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    COUNT(DISTINCT p.product_id) AS products

FROM ecommerce.products p

LEFT JOIN ecommerce.category_translation ct
    ON p.product_category_name
       = ct.product_category_name

GROUP BY product_category

ORDER BY products DESC;


-- 3. Best-selling categories by units sold

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT oi.order_id) AS orders

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

ORDER BY units_sold DESC

LIMIT 20;


-- 4. Highest-revenue categories

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    ROUND(
        SUM(oi.price),
        2
    ) AS product_revenue,

    COUNT(*) AS units_sold,

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


-- 5. Top 20 products by units sold

SELECT
    oi.product_id,

    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    COUNT(*) AS units_sold,

    COUNT(DISTINCT oi.order_id) AS orders,

    ROUND(
        SUM(oi.price),
        2
    ) AS product_revenue

FROM ecommerce.order_items oi

JOIN ecommerce.orders o
    ON oi.order_id = o.order_id

JOIN ecommerce.products p
    ON oi.product_id = p.product_id

LEFT JOIN ecommerce.category_translation ct
    ON p.product_category_name
       = ct.product_category_name

WHERE o.order_status = 'delivered'

GROUP BY
    oi.product_id,
    product_category

ORDER BY units_sold DESC

LIMIT 20;


-- 6. Top 20 products by revenue

SELECT
    oi.product_id,

    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    ROUND(
        SUM(oi.price),
        2
    ) AS product_revenue,

    COUNT(*) AS units_sold,

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

GROUP BY
    oi.product_id,
    product_category

ORDER BY product_revenue DESC

LIMIT 20;


-- 7. Category price statistics

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    COUNT(*) AS order_items,

    ROUND(
        MIN(oi.price),
        2
    ) AS minimum_price,

    ROUND(
        AVG(oi.price),
        2
    ) AS average_price,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY oi.price
        )::NUMERIC,
        2
    ) AS median_price,

    ROUND(
        MAX(oi.price),
        2
    ) AS maximum_price

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

HAVING COUNT(*) >= 20

ORDER BY average_price DESC;


-- 8. Freight cost by category

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

    ROUND(
        SUM(oi.freight_value),
        2
    ) AS total_freight_value,

    ROUND(
        AVG(oi.freight_value),
        2
    ) AS average_freight_value,

    ROUND(
        100.0
        * SUM(oi.freight_value)
        / NULLIF(
            SUM(oi.price),
            0
        ),
        2
    ) AS freight_to_revenue_pct

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

ORDER BY average_freight_value DESC;


-- 9. Heavy products compared with regular products

SELECT
    CASE
        WHEN p.heavy_product_flag = TRUE
            THEN 'Heavy product'
        ELSE 'Regular product'
    END AS product_weight_group,

    COUNT(*) AS order_items,

    ROUND(
        AVG(oi.price),
        2
    ) AS average_item_price,

    ROUND(
        AVG(oi.freight_value),
        2
    ) AS average_freight_value,

    ROUND(
        AVG(o.delivery_days),
        2
    ) AS average_delivery_days

FROM ecommerce.order_items oi

JOIN ecommerce.orders o
    ON oi.order_id = o.order_id

JOIN ecommerce.products p
    ON oi.product_id = p.product_id

WHERE o.order_status = 'delivered'

GROUP BY product_weight_group

ORDER BY product_weight_group;


-- 10. Product volume groups

WITH product_volume_groups AS (
    SELECT
        product_id,
        product_volume_cm3,

        NTILE(4) OVER (
            ORDER BY product_volume_cm3
        ) AS volume_quartile

    FROM ecommerce.products

    WHERE product_volume_cm3 IS NOT NULL
)

SELECT
    pvg.volume_quartile,

    COUNT(DISTINCT pvg.product_id) AS products,

    COUNT(*) AS items_sold,

    ROUND(
        AVG(oi.freight_value),
        2
    ) AS average_freight_value,

    ROUND(
        AVG(o.delivery_days),
        2
    ) AS average_delivery_days

FROM product_volume_groups pvg

JOIN ecommerce.order_items oi
    ON pvg.product_id = oi.product_id

JOIN ecommerce.orders o
    ON oi.order_id = o.order_id

WHERE o.order_status = 'delivered'

GROUP BY pvg.volume_quartile

ORDER BY pvg.volume_quartile;


-- 11. Product category revenue ranking

WITH category_metrics AS (
    SELECT
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS product_category,

        SUM(oi.price) AS revenue,

        COUNT(*) AS units_sold

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
)

SELECT
    product_category,

    ROUND(
        revenue,
        2
    ) AS revenue,

    units_sold,

    DENSE_RANK() OVER (
        ORDER BY revenue DESC
    ) AS revenue_rank,

    DENSE_RANK() OVER (
        ORDER BY units_sold DESC
    ) AS unit_sales_rank

FROM category_metrics

ORDER BY revenue_rank;


-- 12. Products with high prices and low sales

WITH product_metrics AS (
    SELECT
        oi.product_id,

        AVG(oi.price) AS average_price,

        COUNT(*) AS units_sold,

        SUM(oi.price) AS revenue

    FROM ecommerce.order_items oi

    JOIN ecommerce.orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.product_id
),

price_threshold AS (
    SELECT
        PERCENTILE_CONT(0.75)
        WITHIN GROUP (
            ORDER BY average_price
        ) AS high_price_threshold

    FROM product_metrics
)

SELECT
    pm.product_id,

    ROUND(
        pm.average_price,
        2
    ) AS average_price,

    pm.units_sold,

    ROUND(
        pm.revenue,
        2
    ) AS revenue

FROM product_metrics pm

CROSS JOIN price_threshold pt

WHERE pm.average_price
      >= pt.high_price_threshold
  AND pm.units_sold <= 2

ORDER BY pm.average_price DESC

LIMIT 50;


-- 13. Products with high sales but low revenue

WITH product_metrics AS (
    SELECT
        oi.product_id,

        COUNT(*) AS units_sold,

        SUM(oi.price) AS revenue,

        AVG(oi.price) AS average_price

    FROM ecommerce.order_items oi

    JOIN ecommerce.orders o
        ON oi.order_id = o.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY oi.product_id
),

ranked_products AS (
    SELECT
        *,

        NTILE(4) OVER (
            ORDER BY units_sold DESC
        ) AS sales_quartile,

        NTILE(4) OVER (
            ORDER BY revenue ASC
        ) AS low_revenue_quartile

    FROM product_metrics
)

SELECT
    product_id,
    units_sold,

    ROUND(
        revenue,
        2
    ) AS revenue,

    ROUND(
        average_price,
        2
    ) AS average_price

FROM ranked_products

WHERE sales_quartile = 1
  AND low_revenue_quartile = 1

ORDER BY units_sold DESC;


-- 14. Product category review performance

SELECT
    COALESCE(
        ct.product_category_name_english,
        p.product_category_name,
        'unknown'
    ) AS product_category,

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

FROM ecommerce.order_items oi

JOIN ecommerce.orders o
    ON oi.order_id = o.order_id

JOIN ecommerce.products p
    ON oi.product_id = p.product_id

LEFT JOIN ecommerce.category_translation ct
    ON p.product_category_name
       = ct.product_category_name

JOIN ecommerce.reviews r
    ON oi.order_id = r.order_id

WHERE o.order_status = 'delivered'

GROUP BY product_category

HAVING COUNT(*) >= 50

ORDER BY average_review_score DESC;