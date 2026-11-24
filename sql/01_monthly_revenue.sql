
-- Task 1: Monthly revenue and month-over-month growth
-- Business question: Is the business growing, and which months stand out?
-- Tables: fact_order_items, dim_date
-- Decisions: revenue = SUM(price), freight excluded. Canceled and unavailable orders excluded.
--            First and last months need checking, because they may be partial.

WITH monthly AS (
    SELECT
    
        d.year_month,
        COUNT(DISTINCT f.order_id) AS orders,
        ROUND(SUM(f.price), 2)     AS revenue
    FROM fact_order_items f
    JOIN dim_date d ON f.purchase_date_key = d.date_key
    WHERE f.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY d.year_month
)
SELECT
    year_month,
    orders,
    revenue,
    LAG(revenue) OVER (ORDER BY year_month) AS prev_revenue,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY year_month))
          / LAG(revenue) OVER (ORDER BY year_month), 1) AS mom_growth_pct
FROM monthly
ORDER BY year_month
    