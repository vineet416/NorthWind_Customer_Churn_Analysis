# Northwind Customer Churn Analysis

A MySQL analysis of the Northwind sample database that looks at customer purchase behaviour and churn risk.
One SQL script answers 14 business questions on purchase frequency, order value, product mix, geography and loyalty tiers.
It shows how plain SQL can turn order data into retention insights and recommendations.

## Project Files

| File | Description |
|---|---|
| `Datasets/northwind.sql` | Drops and recreates the `northwind` schema with its 20 tables |
| `Datasets/northwind-data.sql` | 511 `INSERT` statements that load the sample data |
| `Northwind Customer Churn Soution Query.sql` | 14 questions, each with MySQL queries and a short commentary |
| `README.md` | Project documentation |

## Dataset

Northwind sample data (MS Access 2010 version converted to MySQL). Orders run from 2006-01-15 to 2006-06-23. The queries use 5 of the 20 tables; the other 15 (employees, suppliers, invoices, inventory, purchase orders, etc.) are loaded but unused.

| Table | Rows | Key fields |
|---|---|---|
| `customers` | 29 | `id`, `company`, `city`, `state_province`, `country_region` – who the customer is and where (all USA) |
| `orders` | 48 | `customer_id`, `order_date`, `shipped_date`, `status_id`, `shipping_fee`, `taxes` – one row per order |
| `order_details` | 58 | `order_id`, `product_id`, `quantity`, `unit_price`, `discount` – order line items |
| `products` | 45 | `product_name`, `category`, `discontinued` – product catalogue |
| `orders_status` | 4 | `status_name` – New, Invoiced, Shipped, Closed |

## Approach

1. **Understand the data** – review the schema and pick the core tables (customers, orders, order_details, products).
2. **Prepare** – load schema and data into MySQL. There is no separate cleaning script; `LEFT JOIN`, `COALESCE` and `CASE` handle missing orders and segments inside the queries.
3. **Analyse** – use `LAG`/`DATEDIFF` for purchase gaps, CTEs for churn flags, and `CASE` rules for frequency, order-value and loyalty-tier segments.
4. **Report** – each query is followed by a commentary block; Q11–Q14 form the executive summary and recommendations.

## Key Insights

All figures were recomputed from the data files.

| Area | Finding |
|---|---|
| Customers | 29 customers; 15 placed orders, 14 (48.28%) never ordered (Q11) |
| Revenue | 68,137 across 40 orders with line items (about 1,703 per order) |
| Purchase gaps | Average gap between orders is 36.6 days (33 gaps) |
| Frequency segments (Q2) | Frequent (≤30 days): 5 customers, 24.0 days. Regular (≤90): 9, 52.7 days. Infrequent: 1, 97.0 days |
| Concentration | Top 3 customers (IDs 28, 7, 6) bring 37,240 = 54.7% of revenue |
| Order value (Q4) | High (≥5,000): 3 customers. Medium (1,000–4,999): 11. Low: 15, of which 14 have no orders |
| Product mix (Q5) | Among the 12 customers with a Closed order, Beverages (9 lines) and Dried Fruit & Nuts (8) lead |
| Geography (Q7) | Memphis (15,433), Boise (13,800) and Milwaukee (8,008) lead revenue. Chicago has the most orders (6) but the lowest revenue (2,273) |
| Loyalty tiers (Q9, Q13) | 3 Gold (customers 4, 6, 8) and 26 Silver |
| Regional "churn" (Q6) | 12 of 29 customers (41.38%) flagged; Chicago and Las Vegas 2 of 2, eight cities 50%, six cities 0% (see Data Notes) |

## Tech Stack

- MySQL 8.0+ (window functions are required for `LAG`)
- SQL: CTEs, window functions, joins, `CASE`, aggregates, `DATEDIFF`
- MySQL Workbench or any MySQL client

## How to Use

1. Clone or download this repository.
2. Run `Datasets/northwind.sql` (this drops any existing `northwind` schema), then `Datasets/northwind-data.sql`.
3. Open `Northwind Customer Churn Soution Query.sql`, run `USE northwind;`, then execute the queries one question at a time.
