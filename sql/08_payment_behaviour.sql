-- Task 8: Payment behaviour
-- Business question: How do customers pay, and how many installments do they use?
-- Tables: fact_order_items, fact_payments, dim_date
-- Decisions: same status filter and 2017-01 to 2018-08 window as earlier tasks.
--            One row per order: each order is labelled by its largest payment (ties go to the first
--            payment). Counting payment rows would count multi-payment orders more than once.
--            Installments come from that largest payment. Two credit-card payments with 0
--            installments (found in Phase 1) fall in the "1 (full payment)" band.
--            paid = total of ALL payments for the order, which includes freight.

WITH ord AS (
    SELECT DISTINCT f.order_id
    FROM fact_order_items f
    JOIN dim_date d ON f.purchase_date_key = d.date_key
    WHERE f.order_status NOT IN ('canceled', 'unavailable')
      AND d.year_month BETWEEN '2017-01' AND '2018-08'
),
pay AS (
    SELECT
        p.order_id,
        p.payment_type,
        p.payment_installments,
        ROW_NUMBER() OVER (PARTITION BY p.order_id
                           ORDER BY p.payment_value DESC, p.payment_sequential) AS rn,
        COUNT(*)           OVER (PARTITION BY p.order_id) AS n_payments,
        SUM(p.payment_value) OVER (PARTITION BY p.order_id) AS order_paid
    FROM fact_payments p
    JOIN ord o ON p.order_id = o.order_id
)
SELECT
    payment_type AS main_type,
    CASE WHEN payment_installments <= 1  THEN '1 (full payment)'
         WHEN payment_installments <= 3  THEN '2-3'
         WHEN payment_installments <= 6  THEN '4-6'
         WHEN payment_installments <= 10 THEN '7-10'
         ELSE '11+' END AS installment_band,
    COUNT(*)                                            AS orders,
    SUM(CASE WHEN n_payments > 1 THEN 1 ELSE 0 END)     AS multi_payment_orders,
    ROUND(SUM(order_paid), 2)                           AS paid
FROM pay
WHERE rn = 1
GROUP BY payment_type, installment_band
ORDER BY orders DESC;