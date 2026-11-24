-- Task 7: Cohort retention
-- Business question: Of the customers acquired in each month, what share orders again, and when?
-- Tables: fact_order_items, dim_date
-- Decisions: cohort = month of the customer's first order in the window (customer_unique_id).
--            Retention = share of the cohort with at least one order in month N after the first.
--            Same revenue-status filter and 2017-01 to 2018-08 window as earlier tasks.
--            Later cohorts have fewer observable months, because the data ends in 2018-08.
--      --            Customers whose first order was in 2016 (about 300 orders in total) count as new in 2017 if they order again; this is negligible.     

WITH orders_c AS (
    SELECT DISTINCT f.customer_unique_id, f.order_id, d.year_month
    FROM fact_order_items f
    JOIN dim_date d ON f.purchase_date_key = d.date_key
    WHERE f.order_status NOT IN ('canceled', 'unavailable')
      AND d.year_month BETWEEN '2017-01' AND '2018-08'
),
first_order AS (
    SELECT customer_unique_id, MIN(year_month) AS cohort
    FROM orders_c
    GROUP BY customer_unique_id
),
activity AS (
    SELECT
        fo.cohort,
        (CAST(substr(o.year_month, 1, 4) AS INTEGER) * 12 + CAST(substr(o.year_month, 6, 2) AS INTEGER))
      - (CAST(substr(fo.cohort, 1, 4) AS INTEGER) * 12 + CAST(substr(fo.cohort, 6, 2) AS INTEGER)) AS months_since,
        COUNT(DISTINCT o.customer_unique_id) AS active
    FROM orders_c o
    JOIN first_order fo ON o.customer_unique_id = fo.customer_unique_id
    GROUP BY fo.cohort, months_since
)
SELECT
    cohort,
    months_since,
    active,
    ROUND(100.0 * active / FIRST_VALUE(active) OVER (PARTITION BY cohort ORDER BY months_since), 2) AS retention_pct
FROM activity
ORDER BY cohort, months_since;