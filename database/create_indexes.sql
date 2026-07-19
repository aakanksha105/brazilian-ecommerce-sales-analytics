-- ============================================================
-- PostgreSQL Indexes
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_customers_unique_id
    ON ecommerce.customers(customer_unique_id);

CREATE INDEX IF NOT EXISTS idx_customers_state
    ON ecommerce.customers(customer_state);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id
    ON ecommerce.orders(customer_id);

CREATE INDEX IF NOT EXISTS idx_orders_purchase_timestamp
    ON ecommerce.orders(order_purchase_timestamp);

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON ecommerce.orders(order_status);

CREATE INDEX IF NOT EXISTS idx_orders_year_month
    ON ecommerce.orders(purchase_year_month);

CREATE INDEX IF NOT EXISTS idx_orders_late_delivery
    ON ecommerce.orders(late_delivery);

CREATE INDEX IF NOT EXISTS idx_order_items_product_id
    ON ecommerce.order_items(product_id);

CREATE INDEX IF NOT EXISTS idx_order_items_seller_id
    ON ecommerce.order_items(seller_id);

CREATE INDEX IF NOT EXISTS idx_payments_type
    ON ecommerce.payments(payment_type);

CREATE INDEX IF NOT EXISTS idx_products_category
    ON ecommerce.products(product_category_name);

CREATE INDEX IF NOT EXISTS idx_reviews_order_id
    ON ecommerce.reviews(order_id);

CREATE INDEX IF NOT EXISTS idx_reviews_score
    ON ecommerce.reviews(review_score);

CREATE INDEX IF NOT EXISTS idx_geolocation_zip
    ON ecommerce.geolocation(
        geolocation_zip_code_prefix
    );

ANALYZE;