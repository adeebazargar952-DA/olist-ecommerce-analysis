\# Data Quality Notes — Phase 1 Exploration



\## 1. Orders

\- `order\_delivered\_carrier\_date` (1.8% missing) and `order\_delivered\_customer\_date` (3.0% missing) — 97.3% of missing values are fully explained by order status (cancelled, unavailable, still in transit).

\- 9 orders marked "delivered" have inconsistent/missing delivery timestamps — flagged as a logging gap, not excluded from delivery-time analysis.



\## 2. Order Items

\- `freight\_value` is $0 for 383 rows (0.34%). 96% of these trace back to just 4 sellers (out of 3,095 total) — suggests seller-specific shipping arrangements, not a data defect.

\- `order\_item\_id` is a per-order item counter (1 to 21), not a unique row ID.



\## 3. Products

\- 610 products (1.9%) are missing `product\_category\_name`, `product\_name\_lenght`, `product\_description\_lenght`, and `product\_photos\_qty` together, while retaining physical shipping attributes (weight, dimensions). Indicates incomplete seller-submitted listings, not corrupted records.
\-13 hand-translated categories, 610 labelled “unknown”



\## 4. Order Reviews

\- `review\_score` (core field) has zero missing values across all 99,224 reviews. Distribution is skewed positive: 77% are 4-5 stars.

\- `review\_comment\_title` (88.3%) and `review\_comment\_message` (58.7%) missingness is expected — optional free-text fields, doesn't affect core rating analysis.



\## 5. Geolocation

\- 1,000,163 rows map to only 19,015 unique zip codes (\~53 coordinate samples per zip) — will be aggregated to one row per zip code before joining to customers/sellers.

\- 42 rows (0.004%) have lat/lng coordinates falling outside Brazil's geographic bounds (matching Portugal, Argentina, Italy, etc.) despite correct city/state/zip — likely geocoding errors. To be replaced with the zip code's average valid coordinate.

\- Minor city name spelling/accent inconsistencies found for the same zip code (e.g., "santa maria" vs accented variants) — doesn't affect zip-based joins.



\## 6. Customers

\- Two ID columns: `customer\_id` (unique per order — 99,441 total) and `customer\_unique\_id` (unique per actual person — 96,096 total). Difference (3,345) = repeat customers.

\- \*\*Important:\*\* all customer-level aggregations (repeat purchase rate, CLV) must use `customer\_unique\_id`, not `customer\_id`, to avoid double-counting returning customers.
\- 250 people have more than one zip, and the first is kept



\## 7. Sellers

\- Heavily concentrated geographically: SP alone = 59.7% of all 3,095 sellers. Top 3 states (SP, PR, MG) = \~79%. Several states have only 1 seller.

\- State-level seller comparisons must use rates/medians, not raw counts, given this imbalance.



\## 8. Order Payments

\- 103,886 payment records map to 99,440 unique orders — 4,446 orders used multiple payment methods (e.g., split between voucher and credit card). Order-level totals must be aggregated via SUM(payment\_value) by order\_id, not row counts.

\- `payment\_type` includes 3 rows with an undefined category (`not\_defined`).

\- `payment\_installments` has 2 rows with a value of 0 despite being `credit\_card` payments — anomalous, negligible in scale (<0.01%).

