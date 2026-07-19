# Exploratory Data Analysis Summary

This report summarizes the major findings from the exploratory analysis of the Olist E-commerce dataset.

## Dataset Overview

- Orders: 99,441
- Unique Customers: 96,096
- Sellers: 3,095
- Products: 32,951

## Key Findings

- Approximately 97% of orders were successfully delivered.
- Order volume and revenue increased steadily through 2017.
- November 2017 recorded the highest sales activity.
- Customers primarily purchased during weekdays and daytime hours.
- São Paulo represented the largest customer and seller market.
- Credit cards were the dominant payment method.
- Most deliveries occurred within 5–15 days.
- Late deliveries were associated with significantly lower review scores.
- Product prices and freight values were heavily right-skewed.
- Several product and freight outliers appear to be legitimate business observations.
- Delivery reliability appears to be one of the strongest drivers of customer satisfaction.

## Generated Tables

- order_status_summary.csv
- monthly_orders.csv
- monthly_revenue.csv
- state_comparison.csv
- review_by_delivery_status.csv
- installment_payment_summary.csv
- category_revenue.csv

## Generated Figures

Charts for orders, customers, products, payments, reviews, logistics, sellers, geography, and correlations are available under reports/figures/.

## Next Phase

The next phase performs data cleaning, feature engineering, and validation before loading the cleaned datasets into PostgreSQL.
