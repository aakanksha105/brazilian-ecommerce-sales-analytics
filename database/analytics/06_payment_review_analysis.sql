-- ============================================================
-- Phase 6: SQL Business Analytics
-- File: 06_payment_review_analysis.sql
-- Purpose: Payment behavior, installments, reviews, satisfaction
-- ============================================================


-- 1. Payment-method usage

SELECT
    payment_type,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(SUM(payment_value), 2) AS total_payment_value,
    ROUND(AVG(payment_value), 2) AS average_payment_value
FROM ecommerce.payments
GROUP BY payment_type
ORDER BY total_payment_value DESC;


-- 2. Payment-method share

WITH payment_method_summary AS (
    SELECT
        payment_type,
        COUNT(DISTINCT order_id) AS orders,
        SUM(payment_value) AS payment_value
    FROM ecommerce.payments
    GROUP BY payment_type
)

SELECT
    payment_type,
    orders,
    ROUND(payment_value, 2) AS payment_value,

    ROUND(
        100.0 * orders
        / NULLIF(SUM(orders) OVER (), 0),
        2
    ) AS order_share_pct,

    ROUND(
        100.0 * payment_value
        / NULLIF(SUM(payment_value) OVER (), 0),
        2
    ) AS payment_value_share_pct

FROM payment_method_summary
ORDER BY payment_value DESC;


-- 3. Installment distribution

SELECT
    payment_installments,
    COUNT(*) AS payment_records,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(AVG(payment_value), 2) AS average_payment_value,
    ROUND(SUM(payment_value), 2) AS total_payment_value
FROM ecommerce.payments
WHERE payment_installments IS NOT NULL
GROUP BY payment_installments
ORDER BY payment_installments;


-- 4. Single-payment versus installment purchases

SELECT
    CASE
        WHEN payment_installments <= 1
            THEN 'Single payment'
        ELSE 'Installments'
    END AS installment_group,

    COUNT(DISTINCT order_id) AS orders,
    ROUND(AVG(payment_value), 2) AS average_payment_value,
    ROUND(SUM(payment_value), 2) AS total_payment_value

FROM ecommerce.payments
WHERE payment_installments IS NOT NULL
GROUP BY installment_group
ORDER BY total_payment_value DESC;


-- 5. Payment value by installment range

SELECT
    CASE
        WHEN payment_installments <= 1
            THEN '1 installment'
        WHEN payment_installments BETWEEN 2 AND 3
            THEN '2–3 installments'
        WHEN payment_installments BETWEEN 4 AND 6
            THEN '4–6 installments'
        WHEN payment_installments BETWEEN 7 AND 10
            THEN '7–10 installments'
        ELSE '11+ installments'
    END AS installment_range,

    COUNT(*) AS payment_records,
    ROUND(AVG(payment_value), 2) AS average_payment_value,
    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY payment_value)::NUMERIC,
        2
    ) AS median_payment_value,
    ROUND(MAX(payment_value), 2) AS maximum_payment_value

FROM ecommerce.payments
WHERE payment_installments IS NOT NULL
GROUP BY installment_range
ORDER BY MIN(payment_installments);


-- 6. Orders using multiple payment records

WITH order_payment_summary AS (
    SELECT
        order_id,
        COUNT(*) AS payment_records,
        COUNT(DISTINCT payment_type) AS payment_methods,
        SUM(payment_value) AS total_payment_value
    FROM ecommerce.payments
    GROUP BY order_id
)

SELECT
    payment_records,
    COUNT(*) AS orders,
    ROUND(AVG(total_payment_value), 2) AS average_order_payment
FROM order_payment_summary
GROUP BY payment_records
ORDER BY payment_records;


-- 7. Orders using multiple payment methods

WITH order_payment_summary AS (
    SELECT
        order_id,
        COUNT(DISTINCT payment_type) AS payment_methods,
        SUM(payment_value) AS total_payment_value
    FROM ecommerce.payments
    GROUP BY order_id
)

SELECT
    payment_methods,
    COUNT(*) AS orders,
    ROUND(AVG(total_payment_value), 2) AS average_order_payment
FROM order_payment_summary
GROUP BY payment_methods
ORDER BY payment_methods;


-- 8. Monthly payment trend by payment type

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS purchase_month_date,

    p.payment_type,

    COUNT(DISTINCT p.order_id) AS orders,

    ROUND(
        SUM(p.payment_value),
        2
    ) AS total_payment_value

FROM ecommerce.payments p

JOIN ecommerce.orders o
    ON p.order_id = o.order_id

GROUP BY
    1,
    p.payment_type

ORDER BY
    1,
    total_payment_value DESC;

-- 9. Review-score distribution

SELECT
    review_score,
    COUNT(*) AS review_records,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(
            SUM(COUNT(*)) OVER (),
            0
        ),
        2
    ) AS review_share_pct

FROM ecommerce.reviews

GROUP BY review_score

ORDER BY review_score;


-- 10. Positive and negative review rates

SELECT
    COUNT(*) AS total_reviews,

    COUNT(*) FILTER (
        WHERE review_score >= 4
    ) AS positive_reviews,

    COUNT(*) FILTER (
        WHERE review_score <= 2
    ) AS negative_reviews,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE review_score >= 4
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS positive_review_rate_pct,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE review_score <= 2
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS negative_review_rate_pct

FROM ecommerce.reviews;


-- 11. Written-review participation

SELECT
    COUNT(*) AS review_records,

    COUNT(*) FILTER (
        WHERE review_comment_title IS NOT NULL
          AND review_comment_title <> ''
    ) AS reviews_with_title,

    COUNT(*) FILTER (
        WHERE review_comment_message IS NOT NULL
          AND review_comment_message <> ''
    ) AS reviews_with_message,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE review_comment_message IS NOT NULL
              AND review_comment_message <> ''
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS written_message_rate_pct

FROM ecommerce.reviews;


-- 12. Review scores by order status

SELECT
    o.order_status,
    COUNT(*) AS review_records,
    ROUND(AVG(r.review_score), 2) AS average_review_score
FROM ecommerce.reviews r
JOIN ecommerce.orders o
    ON r.order_id = o.order_id
GROUP BY o.order_status
ORDER BY review_records DESC;


-- 13. Review scores by payment type

SELECT
    p.payment_type,
    COUNT(DISTINCT p.order_id) AS reviewed_orders,
    ROUND(AVG(r.review_score), 2) AS average_review_score,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE r.review_score >= 4
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS positive_review_rate_pct

FROM ecommerce.payments p

JOIN ecommerce.reviews r
    ON p.order_id = r.order_id

GROUP BY p.payment_type

ORDER BY average_review_score DESC;


-- 14. Review scores by installment range

SELECT
    CASE
        WHEN p.payment_installments <= 1
            THEN '1 installment'
        WHEN p.payment_installments BETWEEN 2 AND 3
            THEN '2–3 installments'
        WHEN p.payment_installments BETWEEN 4 AND 6
            THEN '4–6 installments'
        WHEN p.payment_installments BETWEEN 7 AND 10
            THEN '7–10 installments'
        ELSE '11+ installments'
    END AS installment_range,

    COUNT(DISTINCT p.order_id) AS reviewed_orders,

    ROUND(
        AVG(r.review_score),
        2
    ) AS average_review_score

FROM ecommerce.payments p

JOIN ecommerce.reviews r
    ON p.order_id = r.order_id

WHERE p.payment_installments IS NOT NULL

GROUP BY installment_range

ORDER BY MIN(p.payment_installments);


-- 15. Payment value and customer satisfaction

WITH order_payment AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value
    FROM ecommerce.payments
    GROUP BY order_id
),

payment_quartiles AS (
    SELECT
        order_id,
        total_payment_value,

        NTILE(4) OVER (
            ORDER BY total_payment_value
        ) AS payment_quartile

    FROM order_payment
)

SELECT
    pq.payment_quartile,

    COUNT(*) AS reviewed_orders,

    ROUND(
        MIN(pq.total_payment_value),
        2
    ) AS minimum_payment_value,

    ROUND(
        MAX(pq.total_payment_value),
        2
    ) AS maximum_payment_value,

    ROUND(
        AVG(r.review_score),
        2
    ) AS average_review_score

FROM payment_quartiles pq

JOIN ecommerce.reviews r
    ON pq.order_id = r.order_id

GROUP BY pq.payment_quartile

ORDER BY pq.payment_quartile;


-- 16. Monthly review-score trend

SELECT
    DATE_TRUNC(
        'month',
        o.order_purchase_timestamp
    )::DATE AS purchase_month_date,

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
    ) AS positive_review_rate_pct

FROM ecommerce.reviews r

JOIN ecommerce.orders o
    ON r.order_id = o.order_id

GROUP BY 1

ORDER BY 1;

-- 17. Review-response time

SELECT
    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    review_answer_timestamp
                    - review_creation_date
                )
            ) / 3600
        )::NUMERIC,
        2
    ) AS average_response_hours,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (
            ORDER BY
                EXTRACT(
                    EPOCH FROM (
                        review_answer_timestamp
                        - review_creation_date
                    )
                ) / 3600
        )::NUMERIC,
        2
    ) AS median_response_hours

FROM ecommerce.reviews

WHERE review_creation_date IS NOT NULL
  AND review_answer_timestamp IS NOT NULL;


-- 18. Review-response time by review score

SELECT
    review_score,

    COUNT(*) AS reviews,

    ROUND(
        AVG(
            EXTRACT(
                EPOCH FROM (
                    review_answer_timestamp
                    - review_creation_date
                )
            ) / 3600
        )::NUMERIC,
        2
    ) AS average_response_hours

FROM ecommerce.reviews

WHERE review_creation_date IS NOT NULL
  AND review_answer_timestamp IS NOT NULL

GROUP BY review_score

ORDER BY review_score;