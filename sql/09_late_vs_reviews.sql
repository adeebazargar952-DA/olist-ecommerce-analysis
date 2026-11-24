-- Task 9: Late delivery and review scores
-- Business question: How much do late deliveries hurt customer ratings?
-- Tables: fact_order_items, fact_reviews, dim_date
-- Decisions: delivered orders with a delivery date, same 2017-01 to 2018-08 window as Task 4.
--            Orders without a review are dropped (inner join). One review per order: the latest.
--            delay_days compares calendar days: 0 = delivered on the estimated day, not late.
--            This task describes the pattern; Phase 4 tests whether it is statistically real.

WITH delivered AS (
    SELECT f.order_id, MAX(f.delay_days) AS delay_days
    FROM fact_order_items f
    JOIN dim_date d ON f.purchase_date_key = d.date_key
    WHERE f.order_status = 'delivered'
      AND f.is_late IS NOT NULL
      AND d.year_month BETWEEN '2017-01' AND '2018-08'
    GROUP BY f.order_id
)
SELECT
    CASE WHEN dl.delay_days <= -8 THEN '1. 8+ days early'
         WHEN dl.delay_days <= -1 THEN '2. 1-7 days early'
         WHEN dl.delay_days = 0   THEN '3. on the estimated day'
         WHEN dl.delay_days <= 3  THEN '4. 1-3 days late'
         WHEN dl.delay_days <= 7  THEN '5. 4-7 days late'
         ELSE '6. 8+ days late' END AS delivery_band,
    COUNT(*)                                                                AS orders,
    ROUND(AVG(r.review_score), 2)                                           AS avg_score,
    ROUND(100.0 * AVG(CASE WHEN r.review_score <= 2 THEN 1 ELSE 0 END), 1)  AS pct_1_2_star,
    ROUND(100.0 * AVG(CASE WHEN r.review_score = 5 THEN 1 ELSE 0 END), 1)   AS pct_5_star
FROM delivered dl
JOIN fact_reviews r ON dl.order_id = r.order_id
GROUP BY delivery_band
ORDER BY delivery_band;