| Table Name           | File Name                             | Primary Key                    | Approx. Granularity             | Purpose                                                                                    |
| -------------------- | ------------------------------------- | ------------------------------ | ------------------------------- | ------------------------------------------------------------------------------------------ |
| Customers            | olist_customers_dataset.csv           | customer_id                    | One row per customer record     | Stores customer location and unique customer identifiers.                                  |
| Orders               | olist_orders_dataset.csv              | order_id                       | One row per order               | Stores purchase lifecycle including purchase, approval, shipping, and delivery timestamps. |
| Order Items          | olist_order_items_dataset.csv         | (order_id, order_item_id)      | One row per item purchased      | Stores products sold in each order, seller, freight cost, and product price.               |
| Payments             | olist_order_payments_dataset.csv      | (order_id, payment_sequential) | One row per payment transaction | Stores payment method, installments, and payment amount.                                   |
| Reviews              | olist_order_reviews_dataset.csv       | review_id                      | One row per review              | Stores customer satisfaction ratings and review timestamps.                                |
| Products             | olist_products_dataset.csv            | product_id                     | One row per product             | Stores product category and physical attributes.                                           |
| Sellers              | olist_sellers_dataset.csv             | seller_id                      | One row per seller              | Stores seller location information.                                                        |
| Geolocation          | olist_geolocation_dataset.csv         | None                           | One row per zip code coordinate | Stores latitude and longitude for postal codes.                                            |
| Category Translation | product_category_name_translation.csv | product_category_name          | One row per category            | Maps Portuguese product categories to English.                                             |



Dataset Relationships

| Parent Table | Child Table | Relationship                                 |
| ------------ | ----------- | -------------------------------------------- |
| Customers    | Orders      | One customer can place many orders.          |
| Orders       | Order Items | One order can contain multiple products.     |
| Products     | Order Items | One product can appear in many orders.       |
| Sellers      | Order Items | One seller can sell many products.           |
| Orders       | Payments    | One order can have multiple payment records. |
| Orders       | Reviews     | One order can receive one review.            |


