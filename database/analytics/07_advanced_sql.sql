-- ============================================================
-- Phase 6: SQL Business Analytics
-- File: 07_advanced_sql.sql
-- Purpose: Advanced SQL using CTEs and window functions
-- ============================================================


-- 1. Monthly revenue with previous month and growth rate

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

revenue_comparison AS (
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
            revenue - previous_month_revenue
        )
        / NULLIF(
            previous_month_revenue,
            0
        ),
        2
    ) AS month_over_month_growth_pct

FROM revenue_comparison

ORDER BY revenue_month;


-- 2. Three-month rolling average revenue

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
        AVG(revenue) OVER (
            ORDER BY revenue_month
            ROWS BETWEEN 2 PRECEDING
            AND CURRENT ROW
        ),
        2
    ) AS three_month_rolling_average

FROM monthly_revenue

ORDER BY revenue_month;


-- 3. Running cumulative revenue

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


-- 4. Monthly revenue contribution to total revenue

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
    ) AS revenue,

    ROUND(
        100.0
        * revenue
        / NULLIF(
            SUM(revenue) OVER (),
            0
        ),
        2
    ) AS total_revenue_share_pct

FROM monthly_revenue

ORDER BY total_revenue_share_pct DESC;


-- 5. Rank customer states by revenue

WITH state_revenue AS (
    SELECT
        customer_state,

        SUM(product_revenue) AS revenue,

        COUNT(DISTINCT order_id) AS delivered_orders

    FROM analytics.order_summary

    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL

    GROUP BY customer_state
)

SELECT
    customer_state,
    delivered_orders,

    ROUND(
        revenue,
        2
    ) AS revenue,

    DENSE_RANK() OVER (
        ORDER BY revenue DESC
    ) AS revenue_rank,

    ROUND(
        100.0
        * revenue
        / NULLIF(
            SUM(revenue) OVER (),
            0
        ),
        2
    ) AS revenue_share_pct

FROM state_revenue

ORDER BY revenue_rank;


-- 6. Rank categories by revenue within each year

WITH yearly_category_revenue AS (
    SELECT
        o.purchase_year,

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

    GROUP BY
        o.purchase_year,
        product_category
),

ranked_categories AS (
    SELECT
        purchase_year,
        product_category,
        revenue,

        DENSE_RANK() OVER (
            PARTITION BY purchase_year
            ORDER BY revenue DESC
        ) AS category_rank

    FROM yearly_category_revenue
)

SELECT
    purchase_year,
    category_rank,
    product_category,

    ROUND(
        revenue,
        2
    ) AS revenue

FROM ranked_categories

WHERE category_rank <= 5

ORDER BY
    purchase_year,
    category_rank;


-- 7. Seller revenue rank within seller state

WITH seller_revenue AS (
    SELECT
        s.seller_state,
        oi.seller_id,

        SUM(oi.price) AS revenue,

        COUNT(
            DISTINCT oi.order_id
        ) AS delivered_orders

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
        delivered_orders,

        ROW_NUMBER() OVER (
            PARTITION BY seller_state
            ORDER BY revenue DESC
        ) AS seller_rank

    FROM seller_revenue
)

SELECT
    seller_state,
    seller_rank,
    seller_id,
    delivered_orders,

    ROUND(
        revenue,
        2
    ) AS revenue

FROM ranked_sellers

WHERE seller_rank <= 5

ORDER BY
    seller_state,
    seller_rank;


-- 8. Customer spending deciles

WITH customer_revenue AS (
    SELECT
        customer_unique_id,

        SUM(product_revenue) AS total_revenue,

        COUNT(
            DISTINCT order_id
        ) AS delivered_orders

    FROM analytics.order_summary

    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL

    GROUP BY customer_unique_id
),

customer_deciles AS (
    SELECT
        customer_unique_id,
        total_revenue,
        delivered_orders,

        NTILE(10) OVER (
            ORDER BY total_revenue DESC
        ) AS spending_decile

    FROM customer_revenue
)

SELECT
    spending_decile,

    COUNT(*) AS customers,

    ROUND(
        SUM(total_revenue),
        2
    ) AS decile_revenue,

    ROUND(
        AVG(total_revenue),
        2
    ) AS average_customer_revenue,

    ROUND(
        100.0
        * SUM(total_revenue)
        / NULLIF(
            SUM(
                SUM(total_revenue)
            ) OVER (),
            0
        ),
        2
    ) AS revenue_share_pct

FROM customer_deciles

GROUP BY spending_decile

ORDER BY spending_decile;


-- 9. Pareto-style customer revenue concentration

WITH customer_revenue AS (
    SELECT
        customer_unique_id,
        SUM(product_revenue) AS revenue

    FROM analytics.order_summary

    WHERE order_status = 'delivered'
      AND product_revenue IS NOT NULL

    GROUP BY customer_unique_id
),

ranked_customers AS (
    SELECT
        customer_unique_id,
        revenue,

        ROW_NUMBER() OVER (
            ORDER BY revenue DESC
        ) AS customer_rank,

        COUNT(*) OVER () AS total_customers,

        SUM(revenue) OVER (
            ORDER BY revenue DESC
            ROWS BETWEEN
                UNBOUNDED PRECEDING
                AND CURRENT ROW
        ) AS cumulative_revenue,

        SUM(revenue) OVER () AS total_revenue

    FROM customer_revenue
)

SELECT
    customer_rank,
    customer_unique_id,

    ROUND(
        revenue,
        2
    ) AS revenue,

    ROUND(
        100.0
        * customer_rank
        / NULLIF(total_customers, 0),
        2
    ) AS cumulative_customer_pct,

    ROUND(
        100.0
        * cumulative_revenue
        / NULLIF(total_revenue, 0),
        2
    ) AS cumulative_revenue_pct

FROM ranked_customers

WHERE customer_rank <= 100

ORDER BY customer_rank;


-- 10. Previous purchase date per customer using LAG

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_id,
        order_purchase_timestamp,

        LAG(
            order_purchase_timestamp
        ) OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS previous_purchase_timestamp

    FROM analytics.order_summary

    WHERE order_status = 'delivered'
)

SELECT
    customer_unique_id,
    order_id,
    order_purchase_timestamp,
    previous_purchase_timestamp,

    EXTRACT(
        DAY FROM (
            order_purchase_timestamp
            - previous_purchase_timestamp
        )
    ) AS days_since_previous_purchase

FROM customer_orders

WHERE previous_purchase_timestamp IS NOT NULL

ORDER BY
    customer_unique_id,
    order_purchase_timestamp

LIMIT 100;


-- 11. Average time between customer purchases

WITH customer_orders AS (
    SELECT
        customer_unique_id,
        order_purchase_timestamp,

        LAG(
            order_purchase_timestamp
        ) OVER (
            PARTITION BY customer_unique_id
            ORDER BY order_purchase_timestamp
        ) AS previous_purchase_timestamp

    FROM analytics.order_summary

    WHERE order_status = 'delivered'
),

purchase_intervals AS (
    SELECT
        customer_unique_id,

        EXTRACT(
            EPOCH FROM (
                order_purchase_timestamp
                - previous_purchase_timestamp
            )
        ) / 86400 AS days_between_orders

    FROM customer_orders

    WHERE previous_purchase_timestamp IS NOT NULL
)

SELECT
    COUNT(
        DISTINCT customer_unique_id
    ) AS repeat_customers,

    ROUND(
        AVG(days_between_orders)::NUMERIC,
        2
    ) AS average_days_between_orders,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY days_between_orders
        )::NUMERIC,
        2
    ) AS median_days_between_orders

FROM purchase_intervals;


-- 12. Monthly order status trend

WITH monthly_status AS (
    SELECT
        DATE_TRUNC(
            'month',
            order_purchase_timestamp
        )::DATE AS purchase_month_date,

        order_status,

        COUNT(*) AS orders

    FROM ecommerce.orders

    GROUP BY
        1,
        order_status
)

SELECT
    purchase_month_date,
    order_status,
    orders,

    ROUND(
        100.0
        * orders
        / NULLIF(
            SUM(orders) OVER (
                PARTITION BY purchase_month_date
            ),
            0
        ),
        2
    ) AS monthly_status_share_pct

FROM monthly_status

ORDER BY
    purchase_month_date,
    orders DESC;


-- 13. Monthly review-score rolling average

WITH monthly_reviews AS (
    SELECT
        DATE_TRUNC(
            'month',
            o.order_purchase_timestamp
        )::DATE AS purchase_month_date,

        AVG(r.review_score) AS average_review_score

    FROM ecommerce.reviews r

    JOIN ecommerce.orders o
        ON r.order_id = o.order_id

    GROUP BY 1
)

SELECT
    purchase_month_date,

    ROUND(
        average_review_score,
        2
    ) AS monthly_review_score,

    ROUND(
        AVG(average_review_score) OVER (
            ORDER BY purchase_month_date
            ROWS BETWEEN 2 PRECEDING
            AND CURRENT ROW
        ),
        2
    ) AS three_month_rolling_review_score

FROM monthly_reviews

ORDER BY purchase_month_date;


-- 14. Best and worst delivery-performing states

WITH state_delivery AS (
    SELECT
        c.customer_state,

        COUNT(*) AS delivered_orders,

        AVG(o.delivery_days)
            AS average_delivery_days,

        100.0
        * COUNT(*) FILTER (
            WHERE o.late_delivery = TRUE
        )
        / NULLIF(COUNT(*), 0)
            AS late_delivery_rate_pct

    FROM ecommerce.orders o

    JOIN ecommerce.customers c
        ON o.customer_id = c.customer_id

    WHERE o.order_status = 'delivered'
      AND o.delivery_days IS NOT NULL

    GROUP BY c.customer_state
),

ranked_states AS (
    SELECT
        *,

        DENSE_RANK() OVER (
            ORDER BY late_delivery_rate_pct ASC
        ) AS best_delivery_rank,

        DENSE_RANK() OVER (
            ORDER BY late_delivery_rate_pct DESC
        ) AS worst_delivery_rank

    FROM state_delivery
)

SELECT
    customer_state,
    delivered_orders,

    ROUND(
        average_delivery_days,
        2
    ) AS average_delivery_days,

    ROUND(
        late_delivery_rate_pct,
        2
    ) AS late_delivery_rate_pct,

    best_delivery_rank,
    worst_delivery_rank

FROM ranked_states

WHERE best_delivery_rank <= 5
   OR worst_delivery_rank <= 5

ORDER BY late_delivery_rate_pct;


-- 15. Category performance versus category average

WITH category_metrics AS (
    SELECT
        COALESCE(
            ct.product_category_name_english,
            p.product_category_name,
            'unknown'
        ) AS product_category,

        SUM(oi.price) AS revenue,

        AVG(r.review_score)
            AS average_review_score

    FROM ecommerce.order_items oi

    JOIN ecommerce.orders o
        ON oi.order_id = o.order_id

    JOIN ecommerce.products p
        ON oi.product_id = p.product_id

    LEFT JOIN ecommerce.category_translation ct
        ON p.product_category_name
           = ct.product_category_name

    LEFT JOIN ecommerce.reviews r
        ON oi.order_id = r.order_id

    WHERE o.order_status = 'delivered'

    GROUP BY product_category
)

SELECT
    product_category,

    ROUND(
        revenue,
        2
    ) AS revenue,

    ROUND(
        average_review_score,
        2
    ) AS average_review_score,

    ROUND(
        AVG(revenue) OVER (),
        2
    ) AS overall_average_category_revenue,

    ROUND(
        AVG(average_review_score) OVER (),
        2
    ) AS overall_average_category_review_score,

    CASE
        WHEN revenue >= AVG(revenue) OVER ()
         AND average_review_score
             >= AVG(average_review_score) OVER ()
            THEN 'High revenue / High satisfaction'

        WHEN revenue >= AVG(revenue) OVER ()
         AND average_review_score
             < AVG(average_review_score) OVER ()
            THEN 'High revenue / Low satisfaction'

        WHEN revenue < AVG(revenue) OVER ()
         AND average_review_score
             >= AVG(average_review_score) OVER ()
            THEN 'Low revenue / High satisfaction'

        ELSE 'Low revenue / Low satisfaction'
    END AS performance_segment

FROM category_metrics

ORDER BY revenue DESC;