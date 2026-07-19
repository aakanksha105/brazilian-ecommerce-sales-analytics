## Primary keys

| Table       | Primary Key                    |
| ----------- | ------------------------------ |
| Customers   | customer_id                    |
| Orders      | order_id                       |
| Products    | product_id                     |
| Sellers     | seller_id                      |
| Reviews     | review_id                      |
| Payments    | (order_id, payment_sequential) |
| Order Items | (order_id, order_item_id)      |
| Translation | product_category_name          |
| Geolocation | None                           |


## Foreign keys

| Parent      | Child       | Foreign Key           |
| ----------- | ----------- | --------------------- |
| Customers   | Orders      | customer_id           |
| Orders      | Order Items | order_id              |
| Orders      | Payments    | order_id              |
| Orders      | Reviews     | order_id              |
| Products    | Order Items | product_id            |
| Sellers     | Order Items | seller_id             |
| Translation | Products    | product_category_name |
