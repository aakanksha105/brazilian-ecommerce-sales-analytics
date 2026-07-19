1) Customers

| Column                   | Data Type | Description                       | Business Use                          |
| ------------------------ | --------- | --------------------------------- | ------------------------------------- |
| customer_id              | String    | Unique customer record identifier | Links customers to orders             |
| customer_unique_id       | String    | Persistent customer identifier    | Customer segmentation, CLV, retention |
| customer_zip_code_prefix | Integer   | Customer ZIP prefix               | Geographic analysis                   |
| customer_city            | String    | Customer city                     | Regional sales                        |
| customer_state           | String    | Customer state                    | Geographic dashboard                  |


2) Orders

| Column                        | Data Type | Description            | Business Use         |
| ----------------------------- | --------- | ---------------------- | -------------------- |
| order_id                      | String    | Unique order ID        | Primary key          |
| customer_id                   | String    | Customer placing order | Foreign key          |
| order_status                  | String    | Order status           | Operations analysis  |
| order_purchase_timestamp      | Timestamp | Purchase date          | Revenue trends       |
| order_approved_at             | Timestamp | Payment approval       | Order processing     |
| order_delivered_carrier_date  | Timestamp | Carrier pickup         | Shipping analysis    |
| order_delivered_customer_date | Timestamp | Customer delivery      | Delivery performance |
| order_estimated_delivery_date | Timestamp | Estimated delivery     | Delay analysis       |


3) Order Items

| Column              | Data Type | Description       | Business Use     |
| ------------------- | --------- | ----------------- | ---------------- |
| order_id            | String    | Order identifier  | Join orders      |
| order_item_id       | Integer   | Item sequence     | Composite key    |
| product_id          | String    | Purchased product | Product analysis |
| seller_id           | String    | Seller            | Seller analysis  |
| shipping_limit_date | Timestamp | Shipping deadline | Logistics        |
| price               | Float     | Product price     | Revenue          |
| freight_value       | Float     | Shipping cost     | Logistics cost   |


4) Payments

| Column               | Data Type | Description                | Business Use              |
| -------------------- | --------- | -------------------------- | ------------------------- |
| order_id             | String    | Order identifier           | Join orders               |
| payment_sequential   | Integer   | Payment sequence           | Composite key             |
| payment_type         | String    | Credit card, voucher, etc. | Payment analysis          |
| payment_installments | Integer   | Number of installments     | Customer payment behavior |
| payment_value        | Float     | Payment amount             | Revenue                   |


5) Reviews

| Column                  | Data Type | Description       | Business Use             |
| ----------------------- | --------- | ----------------- | ------------------------ |
| review_id               | String    | Review identifier | Primary key              |
| order_id                | String    | Reviewed order    | Join orders              |
| review_score            | Integer   | Rating (1–5)      | Customer satisfaction    |
| review_comment_title    | String    | Review title      | Sentiment                |
| review_comment_message  | String    | Review text       | Text analysis (optional) |
| review_creation_date    | Timestamp | Review creation   | Timeline                 |
| review_answer_timestamp | Timestamp | Review submission | Customer engagement      |


6) Products

| Column                     | Data Type | Description        | Business Use      |
| -------------------------- | --------- | ------------------ | ----------------- |
| product_id                 | String    | Product identifier | Primary key       |
| product_category_name      | String    | Category           | Category analysis |
| product_name_lenght        | Integer   | Name length        | Data quality      |
| product_description_lenght | Integer   | Description length | Data quality      |
| product_photos_qty         | Integer   | Number of photos   | Product quality   |
| product_weight_g           | Float     | Weight             | Logistics         |
| product_length_cm          | Float     | Length             | Shipping          |
| product_height_cm          | Float     | Height             | Shipping          |
| product_width_cm           | Float     | Width              | Shipping          |


7) Sellers

| Column                 | Data Type | Description       | Business Use      |
| ---------------------- | --------- | ----------------- | ----------------- |
| seller_id              | String    | Seller identifier | Primary key       |
| seller_zip_code_prefix | Integer   | ZIP               | Geographic        |
| seller_city            | String    | City              | Seller analysis   |
| seller_state           | String    | State             | Regional analysis |


8) Geolocation

| Column                      | Data Type | Description | Business Use     |
| --------------------------- | --------- | ----------- | ---------------- |
| geolocation_zip_code_prefix | Integer   | ZIP prefix  | Geographic joins |
| geolocation_lat             | Float     | Latitude    | Maps             |
| geolocation_lng             | Float     | Longitude   | Maps             |
| geolocation_city            | String    | City        | Geographic       |
| geolocation_state           | String    | State       | Geographic       |


9) Translation Table

| Column                        | Description         |
| ----------------------------- | ------------------- |
| product_category_name         | Portuguese category |
| product_category_name_english | English translation |
