-- Task 5: Seller performance segments
-- Business question: Which sellers earn the most, and which of those deliver late?
-- Tables: fact_order_items, dim_seller, dim_date
-- Decisions: delivered orders only, 2017-01 to 2018-08 window, sellers with at least 30 orders.
--            Late rate is per order. Review ratings are not included yet (added after Task 9).
--            The 5% and 15% late-rate bands are starting points to tune once overall late rate is known.

WITH seller_orders AS (
    SELECT
        f.seller_id,
        f.order_id,
        MAX(f.is_late) AS is_late,
        SUM(f.price)   AS revenue
    FROM fact_order_items f
    JOIN dim_date d ON f.purchase_date_key = d.date_key
    WHERE f.order_status = 'delivered'
      AND f.is_late IS NOT NULL
      AND d.year_month BETWEEN '2017-01' AND '2018-08'
    GROUP BY f.seller_id, f.order_id
),
seller AS (
    SELECT
        seller_id,
        COUNT(*)                       AS orders,
        ROUND(SUM(revenue), 2)         AS revenue,
        ROUND(100.0 * AVG(is_late), 1) AS late_pct
    FROM seller_orders
    GROUP BY seller_id
    HAVING COUNT(*) >= 30
),
tiered AS (
    SELECT *, NTILE(3) OVER (ORDER BY revenue) AS revenue_tier
    FROM seller
)
SELECT
    t.seller_id,
    s.state,
    t.orders,
    t.revenue,
    t.late_pct,
    t.revenue_tier,
    CASE WHEN t.late_pct <= 5  THEN 'reliable'
         WHEN t.late_pct <= 15 THEN 'watch'
         ELSE 'unreliable' END AS reliability,
    CASE WHEN t.revenue_tier = 3 AND t.late_pct > 15  THEN 'intervene first'
         WHEN t.revenue_tier = 3 AND t.late_pct <= 5  THEN 'star'
         WHEN t.late_pct > 15                         THEN 'fix or drop'
         ELSE 'steady' END AS segment
FROM tiered t
JOIN dim_seller s ON t.seller_id = s.seller_id
ORDER BY t.revenue DESC;