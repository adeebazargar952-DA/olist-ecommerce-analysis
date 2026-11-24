-- Task 2: Cumulative revenue and 3-month moving average
-- Business question: How fast is revenue accumulating, and what is the trend once monthly noise is smoothed out?
-- Tables: fact_order_items, dim_date
-- Decisions: same revenue definition as Task 1 (SUM(price), canceled and unavailable orders excluded).
--            The first two moving-average values use fewer than 3 months.

WITH monthly AS (
    SELECT
        d.year_month,
        ROUND(SUM(f.price), 2) AS revenue
    FROM fact_order_items f
    JOIN dim_date d ON f.purchase_date_key = d.date_key
    WHERE f.order_status NOT IN ('canceled', 'unavailable')
      AND d.year_month BETWEEN '2017-01' AND '2018-08'
    GROUP BY d.year_month
)
SELECT
    year_month,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY year_month), 2) AS cumulative_revenue,
    ROUND(AVG(revenue) OVER (ORDER BY year_month
                             ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2) AS moving_avg_3m,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 1) AS pct_of_total
FROM monthly
ORDER BY year_month;
