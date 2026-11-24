-- Task 3: Revenue by product category
-- Business question: Which categories drive revenue, and how concentrated is it?
-- Tables: fact_order_items, dim_product, dim_date
-- Decisions: same revenue definition and 2017-01 to 2018-08 window as Tasks 1 and 2.
--            Products with no category are kept as "unknown".

WITH cat AS (
    SELECT
        p.category_english         AS category,
        COUNT(*)                   AS items_sold,
        COUNT(DISTINCT f.order_id) AS orders,
        ROUND(SUM(f.price), 2)     AS revenue
    FROM fact_order_items f
    JOIN dim_product p ON f.product_id = p.product_id
    JOIN dim_date    d ON f.purchase_date_key = d.date_key
    WHERE f.order_status NOT IN ('canceled', 'unavailable')
      AND d.year_month BETWEEN '2017-01' AND '2018-08'
    GROUP BY p.category_english
)
SELECT
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    category,
    items_sold,
    orders,
    revenue,
    ROUND(revenue / items_sold, 2) AS avg_item_price,
    ROUND(100.0 * revenue / SUM(revenue) OVER (), 1) AS pct_of_total,
    ROUND(100.0 * SUM(revenue) OVER (ORDER BY revenue DESC)
          / SUM(revenue) OVER (), 1) AS cumulative_pct
FROM cat
ORDER BY revenue_rank;