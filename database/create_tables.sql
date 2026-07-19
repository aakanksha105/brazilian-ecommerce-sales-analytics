-- E-commerce Customer & Business Analytics Platform
-- PostgreSQL table creation script

DROP SCHEMA IF EXISTS analytics CASCADE;
DROP SCHEMA IF EXISTS ecommerce CASCADE;

CREATE SCHEMA ecommerce;
CREATE SCHEMA analytics;

CREATE TABLE ecommerce.customers (
    customer_id VARCHAR(32) PRIMARY KEY,
    customer_unique_id VARCHAR(32) NOT NULL,
    customer_zip_code_prefix INTEGER,
    customer_city TEXT,
    customer_state VARCHAR(2)
);

CREATE TABLE ecommerce.orders (
    order_id VARCHAR(32) PRIMARY KEY,
    customer_id VARCHAR(32) NOT NULL,
    order_status VARCHAR(20),

    order_purchase_timestamp TIMESTAMP,
    order_approved_at TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,

    missing_approval_date_flag BOOLEAN,
    missing_carrier_date_flag BOOLEAN,
    missing_delivery_date_flag BOOLEAN,

    purchase_date DATE,
    purchase_year INTEGER,
    purchase_month INTEGER,
    purchase_quarter INTEGER,
    purchase_year_month VARCHAR(7),
    purchase_day_name VARCHAR(10),
    purchase_hour INTEGER,

    approval_hours NUMERIC,
    delivery_days NUMERIC,
    estimated_delivery_days NUMERIC,
    delivery_difference_days NUMERIC,
    late_delivery BOOLEAN,

    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES ecommerce.customers(customer_id)
);

CREATE TABLE ecommerce.products (
    product_id VARCHAR(32) PRIMARY KEY,
    product_category_name TEXT,

    product_name_length NUMERIC,
    product_description_length NUMERIC,
    product_photos_qty NUMERIC,

    product_weight_g NUMERIC,
    product_length_cm NUMERIC,
    product_height_cm NUMERIC,
    product_width_cm NUMERIC,

    missing_product_category_flag BOOLEAN,
    missing_weight_flag BOOLEAN,
    missing_dimensions_flag BOOLEAN,

    weight_outlier_flag BOOLEAN,
    length_outlier_flag BOOLEAN,
    height_outlier_flag BOOLEAN,
    width_outlier_flag BOOLEAN,

    product_volume_cm3 NUMERIC,
    heavy_product_flag BOOLEAN
);

CREATE TABLE ecommerce.sellers (
    seller_id VARCHAR(32) PRIMARY KEY,
    seller_zip_code_prefix INTEGER,
    seller_city TEXT,
    seller_state VARCHAR(2)
);

CREATE TABLE ecommerce.order_items (
    order_id VARCHAR(32) NOT NULL,
    order_item_id INTEGER NOT NULL,
    product_id VARCHAR(32) NOT NULL,
    seller_id VARCHAR(32) NOT NULL,

    shipping_limit_date TIMESTAMP,
    price NUMERIC(14, 2),
    freight_value NUMERIC(14, 2),

    price_outlier_flag BOOLEAN,
    freight_outlier_flag BOOLEAN,

    item_total_value NUMERIC(14, 2),
    freight_percentage NUMERIC,

    PRIMARY KEY (order_id, order_item_id),

    CONSTRAINT fk_items_order
        FOREIGN KEY (order_id)
        REFERENCES ecommerce.orders(order_id),

    CONSTRAINT fk_items_product
        FOREIGN KEY (product_id)
        REFERENCES ecommerce.products(product_id),

    CONSTRAINT fk_items_seller
        FOREIGN KEY (seller_id)
        REFERENCES ecommerce.sellers(seller_id)
);

CREATE TABLE ecommerce.payments (
    order_id VARCHAR(32) NOT NULL,
    payment_sequential INTEGER NOT NULL,
    payment_type VARCHAR(30),
    payment_installments INTEGER,
    payment_value NUMERIC(14, 2),

    payment_outlier_flag BOOLEAN,
    multiple_installments BOOLEAN,
    high_value_payment BOOLEAN,

    PRIMARY KEY (order_id, payment_sequential),

    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES ecommerce.orders(order_id)
);

CREATE TABLE ecommerce.reviews (
    review_row_id BIGSERIAL PRIMARY KEY,

    review_id VARCHAR(32),
    order_id VARCHAR(32) NOT NULL,
    review_score INTEGER,

    review_comment_title TEXT,
    review_comment_message TEXT,

    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,

    missing_review_title_flag BOOLEAN,
    missing_review_message_flag BOOLEAN,
    positive_review BOOLEAN,
    negative_review BOOLEAN,

    CONSTRAINT chk_review_score
        CHECK (
            review_score BETWEEN 1 AND 5
            OR review_score IS NULL
        ),

    CONSTRAINT fk_reviews_order
        FOREIGN KEY (order_id)
        REFERENCES ecommerce.orders(order_id)
);

CREATE TABLE ecommerce.geolocation (
    geolocation_row_id BIGSERIAL PRIMARY KEY,

    geolocation_zip_code_prefix INTEGER,
    geolocation_lat NUMERIC,
    geolocation_lng NUMERIC,
    geolocation_city TEXT,
    geolocation_state VARCHAR(2)
);

CREATE TABLE ecommerce.category_translation (
    product_category_name TEXT PRIMARY KEY,
    product_category_name_english TEXT
);

CREATE VIEW analytics.order_summary AS
SELECT
    o.*,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state
FROM ecommerce.orders o
LEFT JOIN ecommerce.customers c
    ON o.customer_id = c.customer_id;

