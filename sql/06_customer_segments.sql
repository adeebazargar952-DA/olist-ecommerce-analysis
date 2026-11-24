-- Task 6: Customer segments (RFM-style)
-- Business question: Who are our customers, and how much revenue sits with repeat buyers versus one-time buyers?
-- Tables: fact_order_items, dim_date
-- Decisions: same revenue definition and 2017-01 to 2018-08 window as Tasks 1 to 3, so the totals reconcile.
--            Recency is measured to 2018-09-01. Customers are customer_unique_id, not customer_id.
--            Frequency is a rule (1 order or 2+), because about 97% of customers ordered once and
--            NTILE would split those ties arbitrarily. Recency and spend use NTILE(3), with a
--            customer_unique_id tie-break so results are reproducible.

WITH cust AS (
    SELECT
        f.customer_unique_id,
        COUNT(DISTINCT f.order_id) AS orders,
        ROUND(SUM(f.price), 2)     AS monetary,
        CAST(julianday('2018-09-01') - julianday(MAX(d.date)) AS INTEGER) AS recency_days
    FROM fact_order_items f
    JOIN dim_date d ON f.purchase_date_key = d.date_key
    WHERE f.order_status NOT IN ('canceled', 'unavailable')
      AND d.year_month BETWEEN '2017-01' AND '2018-08'
    GROUP BY f.customer_unique_id
),
scored AS (
    SELECT *,
        NTILE(3) OVER (ORDER BY recency_days DESC, customer_unique_id) AS r_tier,
        NTILE(3) OVER (ORDER BY monetary, customer_unique_id)          AS m_tier
    FROM cust
),
labelled AS (
    SELECT *,
        CASE WHEN orders >= 2            THEN 'repeat customer'
             WHEN r_tier = 3 AND m_tier = 3 THEN 'recent big spender'
             WHEN r_tier = 1 AND m_tier = 3 THEN 'lapsed big spender'
             WHEN r_tier = 3             THEN 'recent'
             WHEN r_tier = 1             THEN 'lapsed'
             ELSE 'middle' END AS segment
    FROM scored
)
SELECT
    segment,
    COUNT(*)                                                   AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1)         AS pct_customers,
    ROUND(SUM(monetary), 2)                                    AS revenue,
    ROUND(100.0 * SUM(monetary) / SUM(SUM(monetary)) OVER (), 1) AS pct_revenue,
    ROUND(AVG(recency_days), 0)                                AS avg_recency_days,
    ROUND(AVG(monetary), 2)                                    AS avg_spend
FROM labelled
GROUP BY segment
ORDER BY revenue DESC;