-- Task 4: Late delivery rate by customer state
-- Business question: Where do customers get their orders late, and by how much?
-- Tables: fact_order_items, dim_customer, dim_date
-- Decisions: only delivered orders with a delivery date can be late or on time.
--            Same 2017-01 to 2018-08 window. Counted per order, not per item.
--            Small states are filtered later in pandas, so totals reconcile.

WITH delivered AS (
    SELECT
        f.order_id,
        c.state,
        MAX(f.is_late)       AS is_late,
        MAX(f.delay_days)    AS delay_days,
        MAX(f.delivery_days) AS delivery_days
    FROM fact_order_items f
    JOIN dim_customer c ON f.customer_unique_id = c.customer_unique_id
    JOIN dim_date     d ON f.purchase_date_key = d.date_key
    WHERE f.order_status = 'delivered'
      AND f.is_late IS NOT NULL
      AND d.year_month BETWEEN '2017-01' AND '2018-08'
    GROUP BY f.order_id, c.state
)
SELECT
    state,
    COUNT(*)                          AS delivered_orders,
    ROUND(100.0 * AVG(is_late), 1)    AS late_pct,
    ROUND(AVG(delivery_days), 1)      AS avg_delivery_days,
    ROUND(AVG(delay_days), 1)         AS avg_delay_days
FROM delivered
GROUP BY state
ORDER BY late_pct DESC;