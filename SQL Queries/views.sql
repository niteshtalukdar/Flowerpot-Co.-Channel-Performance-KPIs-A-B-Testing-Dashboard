
-- Purpose: create the tables (not new table in the DB) using views that will be needed for Power BI.

-- Goal:
 
-- Removing the 20 QA test accounts and all their emails, visits and orders.
-- Removing the 4,215 visits from the staging site.
-- Removing the 5,756 duplicate rows in email sends and 56 in orders.
-- Handling the 13 spellings of email event types, and counts a click as an open.
-- Turning the email events table, which has many rows per email, into one row per email with simple 1/0 columns for opened, clicked and unsubscribed.
-- Keeping the 701,099 emails with no events, marked as not opened.
-- Picking only the columns the dashboard needs.



-- 1. v_qa_customers: the 20 internal QA test accounts.

DROP VIEW IF EXISTS v_qa_customers;
CREATE VIEW v_qa_customers AS
SELECT DISTINCT customer_id
FROM customers
WHERE LOWER(TRIM(email)) LIKE '%@shopexample-qa.test';

-- Used by the other views to filter out test data.



-- 2. v_email_sends: one row per email sent, with engagement flags.

DROP VIEW IF EXISTS v_email_sends;
CREATE VIEW v_email_sends AS
WITH sends AS (
    SELECT DISTINCT send_id, campaign_code, customer_id, variant, sent_at, delivery_status
    FROM email_sends
    WHERE customer_id NOT IN (SELECT customer_id 
	                            FROM v_qa_customers)
),
engagement AS (
    SELECT send_id,
        MAX(CASE WHEN LOWER(TRIM(event_type)) IN ('open','opened','click','clicked')     THEN 1 ELSE 0 END) AS opened,
        MAX(CASE WHEN LOWER(TRIM(event_type)) IN ('click','clicked')                     THEN 1 ELSE 0 END) AS clicked,
        MAX(CASE WHEN LOWER(TRIM(event_type)) IN ('unsub','unsubscribe','unsubscribed')  THEN 1 ELSE 0 END) AS unsubscribed,
        MAX(CASE WHEN LOWER(TRIM(event_type)) IN ('spam','spam_complaint','complaint')   THEN 1 ELSE 0 END) AS spam_complaint
    FROM email_events
    GROUP BY send_id
)
SELECT s.send_id,
       s.campaign_code,
       s.customer_id,
       s.variant,
       s.sent_at,
       s.delivery_status,
       COALESCE(e.opened, 0)         AS opened,
       COALESCE(e.clicked, 0)        AS clicked,
       COALESCE(e.unsubscribed, 0)   AS unsubscribed,
       COALESCE(e.spam_complaint, 0) AS spam_complaint
FROM sends s
LEFT JOIN engagement e 
ON e.send_id = s.send_id;

-- sends: removes exact duplicate rows and QA accounts.
-- engagement: groups all events per email. opened = 1 if there was
--             an open OR a click (a click proves the email was opened,
--             even when the open was not tracked).
-- LEFT JOIN keeps emails with no events; COALESCE turns them into 0.


SELECT COUNT(*) AS rows, COUNT(DISTINCT send_id) AS unique_emails
FROM v_email_sends;

-- Each 958,618 email rows appears once.




-- 3. v_sessions: website visits without staging or QA traffic.

DROP VIEW IF EXISTS v_sessions;
CREATE VIEW v_sessions AS
SELECT session_id,
       customer_id,
       session_start,
       device,
       landing_page,
       referrer
FROM sessions
WHERE landing_page NOT LIKE '%://staging.shopexample.com%'
  AND (customer_id IS NULL
       OR customer_id NOT IN (SELECT customer_id FROM v_qa_customers));

	   
-- Anonymous visits (customer_id NULL) are kept.

SELECT 'raw rows' AS step, COUNT(*) AS row_count
FROM sessions
UNION ALL
SELECT 'after removing staging visits', COUNT(*)
FROM sessions
WHERE landing_page NOT LIKE '%://staging.shopexample.com%'
UNION ALL
SELECT 'after also removing QA accounts', COUNT(*)
FROM sessions
WHERE landing_page NOT LIKE '%://staging.shopexample.com%'
  AND (customer_id IS NULL
       OR customer_id NOT IN (SELECT customer_id FROM v_qa_customers))
UNION ALL
SELECT 'v_sessions', COUNT(*)
FROM v_sessions;

-- 606,384 raw visits → 602,169 after removing 4,215 staging visits
-- → 601,804 after removing 365 QA visits. v_sessions matches (601,804).






-- 4. v_orders: orders without exact duplicates or QA orders.

DROP VIEW IF EXISTS v_orders;
CREATE VIEW v_orders AS
SELECT DISTINCT order_number,
       customer_id,
       session_id,
       order_date,
       currency,
       order_status,
       order_total,
       refund_amount
FROM orders
WHERE customer_id NOT IN (SELECT customer_id 
                            FROM v_qa_customers);
							
							
SELECT COUNT(*) AS rows, COUNT(DISTINCT order_number) AS unique_orders
FROM v_orders;
-- 18,486 rows with no duplicate orders.



-- 5. v_fx_rates: exchange rates from wide (one column per currency)

DROP VIEW IF EXISTS v_fx_rates;
CREATE VIEW v_fx_rates AS
SELECT month, 'GBP' AS currency, GBP AS usd_per_unit FROM fx_rates
UNION ALL SELECT month, 'EUR', EUR FROM fx_rates
UNION ALL SELECT month, 'CAD', CAD FROM fx_rates
UNION ALL SELECT month, 'AUD', AUD FROM fx_rates
UNION ALL SELECT month, 'USD', '1' FROM fx_rates;

-- Turns the rates table from one column per currency into one row per
-- month and currency, so each order can be matched to its rate by month
-- and currency. USD is added with rate 1 (a dollar is a dollar).
-- usd_per_unit = US dollars per 1 unit of the currency (1 GBP = 1.30 USD).

SELECT currency, COUNT(*) AS months
FROM v_fx_rates
GROUP BY currency;

-- 180 rows (36 months x 5 currencies).



-- 6. v_campaigns: proper column names and only real campaign rows.

DROP VIEW IF EXISTS v_campaigns;
CREATE VIEW v_campaigns AS
SELECT "ShopExample marketing - campaign export" AS campaign_code,
       field2  AS campaign_name,
       field3  AS channel,
       field4  AS campaign_type,
       field5  AS start_date,
       field6  AS end_date,
       field7  AS spend,
       field8  AS subject_line_a,
       field9  AS subject_line_b,
       field10 AS test_id
FROM campaigns
WHERE "ShopExample marketing - campaign export" LIKE 'CMP-%';

-- The campaigns file starts with a title, not column names. On import,
-- the title became the first column name, the other columns were called
-- field2-field10, and the real header, a blank line and a TOTAL line
-- were stored as rows. This view gives the columns their real names and
-- keeps only rows whose code starts with CMP-, the real campaigns.

SELECT COUNT(*) AS campaigns FROM v_campaigns;

-- 102 rows.

SELECT * 
FROM v_campaigns 
LIMIT 5;


