
-- Purpose: check that the views return what they should, before connecting Power BI.



-- 1. Row counts: raw table vs view

SELECT 'email_sends' AS table_name, (SELECT COUNT(*) FROM email_sends) AS raw_rows, (SELECT COUNT(*) FROM v_email_sends) AS view_rows
UNION ALL SELECT 'sessions',     (SELECT COUNT(*) FROM sessions),  (SELECT COUNT(*) FROM v_sessions)
UNION ALL SELECT 'orders',       (SELECT COUNT(*) FROM orders),    (SELECT COUNT(*) FROM v_orders)
UNION ALL SELECT 'fx_rates',     (SELECT COUNT(*) FROM fx_rates),  (SELECT COUNT(*) FROM v_fx_rates)
UNION ALL SELECT 'campaigns',    (SELECT COUNT(*) FROM campaigns), (SELECT COUNT(*) FROM v_campaigns)
UNION ALL SELECT 'qa_customers', NULL,                             (SELECT COUNT(*) FROM v_qa_customers);

-- email_sends 958,618 | sessions 601,804 | orders 18,486 | fx_rates 180 | campaigns 102 | qa_customers 20



-- 2. Each email appears once in v_email_sends

SELECT COUNT(*) - COUNT(DISTINCT send_id) AS duplicate_send_ids
FROM v_email_sends;

--duplicate_send_ids = 0



-- 3. No QA or staging data left

SELECT 'qa sends'    AS check_name, COUNT(*) AS rows_left FROM v_email_sends WHERE customer_id IN (SELECT customer_id FROM v_qa_customers)
UNION ALL SELECT 'qa visits',    COUNT(*) FROM v_sessions WHERE customer_id IN (SELECT customer_id FROM v_qa_customers)
UNION ALL SELECT 'qa orders',    COUNT(*) FROM v_orders   WHERE customer_id IN (SELECT customer_id FROM v_qa_customers)
UNION ALL SELECT 'staging visits', COUNT(*) FROM v_sessions WHERE landing_page LIKE '%staging.shopexample.com%';

-- 0 in every row


-- ---------------------------------------------------------------------
-- 4. Email KPIs for all years

SELECT COUNT(*) AS sent,
       SUM(LOWER(delivery_status) = 'delivered') AS delivered,
       ROUND(100.0 * SUM(opened * (LOWER(delivery_status) = 'delivered'))
             / SUM(LOWER(delivery_status) = 'delivered'), 2) AS open_rate_pct,
       ROUND(100.0 * SUM(clicked * (LOWER(delivery_status) = 'delivered'))
             / SUM(LOWER(delivery_status) = 'delivered'), 2) AS click_rate_pct,
       ROUND(100.0 * SUM(unsubscribed * (LOWER(delivery_status) = 'delivered'))
             / SUM(LOWER(delivery_status) = 'delivered'), 3) AS unsub_rate_pct
FROM v_email_sends;

--  sent 958,618 | delivered 948,913 | open rate 27.11% | click rate 2.73% | unsubscribe rate 0.198%


-- 5. Check A/B test results: delivered and opened counts for each test group.
-- We group the variants into 'A' and 'B' here just to check the numbers.

SELECT c.test_id,
       CASE WHEN LOWER(TRIM(s.variant)) IN ('a','variant a','control') THEN 'A'
            WHEN LOWER(TRIM(s.variant)) IN ('b','variant b','test')    THEN 'B'
       END AS variant_group,
       COUNT(*)      AS delivered,
       SUM(s.opened) AS opened,
       ROUND(100.0 * SUM(s.opened) / COUNT(*), 3) AS open_rate_pct
FROM v_email_sends s
JOIN v_campaigns c ON c.campaign_code = UPPER(TRIM(s.campaign_code))
WHERE c.test_id IS NOT NULL
  AND LOWER(s.delivery_status) = 'delivered'
GROUP BY c.test_id, variant_group
ORDER BY c.test_id, variant_group;


-- T01: Group A (39,722 delivered | 10,382 opened) vs. Group B (40,418 delivered | 11,790 opened)
-- T02: Group A (44,706 delivered | 11,488 opened) vs. Group B (44,996 delivered | 11,785 opened)
-- T03: Group A (51,809 delivered | 13,385 opened) vs. Group B (52,465 delivered | 13,732 opened)

