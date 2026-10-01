-- Purpose: Find data quality problems.
-- Some of this issues will be addressed with other SQL files and some will be later in Power Query.


-- 1. CUSTOMERS
-- ==============

-- Q: How many emails have capitals or extra spaces?

SELECT COUNT(*) AS messy_emails
FROM customers
WHERE email <> LOWER(TRIM(email));

-- 1,539 emails have capitals or extra spaces.


-- Q: Which internal QA test accounts exist?

SELECT customer_id, email
FROM customers
WHERE LOWER(TRIM(email)) LIKE '%@shopexample-qa.test';

-- 20 accounts ending in @shopexample-qa.test.
-- In the views file, I will create v_qa_customers with these 20 accounts, 
-- and the other views will use it to leave out their rows.



-- 2. EMAIL SENDS AND EMAIL EVENTS
-- =================================

-- Q: Are there exact duplicate rows in email_sends?

SELECT (SELECT COUNT(*) FROM email_sends)
     - (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM email_sends)) AS duplicate_rows;

-- 5,756 duplicate rows.
-- Later we will SELECT DISTINCT in v_email_sends .


-- Q: Are campaign codes written consistently?

SELECT COUNT(*) AS lower_case_codes
FROM email_sends
WHERE campaign_code <> UPPER(campaign_code);

-- 47,638 codes are lower case.


-- Q: How many ways are variant and delivery status written?

SELECT variant, COUNT(*) 
FROM email_sends 
GROUP BY variant 
ORDER BY 2 DESC;

SELECT delivery_status, COUNT(*) 
FROM email_sends 
GROUP BY delivery_status 
ORDER BY 2 DESC;

-- Variant 10 ways and delivery_status 9 ways.


-- Q: How many ways is the email event type written?

SELECT event_type, COUNT(*) AS events
FROM email_events
GROUP BY event_type
ORDER BY events DESC;

-- 13 ways.
-- We have to use LOWER + IN lists in v_email_sends when creating email view.


-- Q: Are there clicks with no open recorded?

SELECT SUM(has_click)                          AS clicked_emails,
       SUM(has_click = 1 AND has_open = 0)     AS clicked_without_open,
       ROUND(100.0 * SUM(has_click = 1 AND has_open = 0)
             / SUM(has_click), 1)              AS pct_without_open
FROM (
    SELECT send_id,
           MAX(LOWER(event_type) IN ('click','clicked')) AS has_click,
           MAX(LOWER(event_type) IN ('open','opened'))   AS has_open
    FROM email_events
    GROUP BY send_id
);

-- 2,076 of 25,995 clicked emails (8%) have no open recorded,
-- because some email apps block open tracking.
-- When creating email view (v_email_sends),
-- an email will count as opened if it was opened or clicked, 
-- since a click means the email was opened.


-- Q: How many sent emails have no events at all?

SELECT COUNT(DISTINCT s.send_id) AS sends_without_events
FROM email_sends s
LEFT JOIN email_events e 
ON e.send_id = s.send_id
WHERE e.send_id IS NULL;

-- 701,099 emails were never opened. They must stay in the data
-- as "not opened", or open rates would be far too high.
-- When creating email view (v_email_sends), a LEFT JOIN
-- will keep these emails and mark them as not opened, not clicked and not unsubscribed.





-- 3. SESSIONS (website visits)
-- =============================

-- Q: How many visits came from the internal staging site?

SELECT COUNT(*) AS staging_visits
FROM sessions
WHERE landing_page LIKE '%://staging.shopexample.com%';

-- 4,215 staging visits.
-- When creating v_sessions, i will fillter out these sites.



-- Q: How many visits have a mail.google.com referrer?

SELECT COUNT(*) AS gmail_referrals
FROM sessions
WHERE referrer LIKE '%mail.google.com%';

-- 5,197. These are email clicks. From our business rule if the referrer rule ran before
-- the UTM rule, they would wrongly count as Organic Search.
-- Channel rules check UTM tags first in power query.




-- 4. ORDERS
-- =========

-- Q: Are there exact duplicate orders?

SELECT (SELECT COUNT(*) 
        FROM orders)
     - (SELECT COUNT(*) 
	    FROM (SELECT DISTINCT * FROM orders)) AS duplicate_rows;

-- 56 duplicate orders.
-- When creating v_orders table SELECT DISTINCT.


-- Q: How many ways are order status and currency written?

SELECT order_status, COUNT(*) 
FROM orders 
GROUP BY order_status 
ORDER BY 2 DESC;

SELECT currency, COUNT(*) 
FROM orders 
GROUP BY currency 
ORDER BY 2 DESC;

-- order_status 11 ways;
-- currency 11 ways.
-- In Power Query will fix by mapping to 4 statuses and 5 currency codes.




-- 5. ACROSS TABLES
-- =================

-- Q: How much data belongs to the 20 QA test accounts?

SELECT 'email_sends' AS table_name, COUNT(*) AS qa_rows
FROM email_sends
WHERE customer_id IN (SELECT customer_id FROM customers
                      WHERE LOWER(TRIM(email)) LIKE '%@shopexample-qa.test')
UNION ALL
SELECT 'sessions', COUNT(*)
FROM sessions
WHERE customer_id IN (SELECT customer_id FROM customers
                      WHERE LOWER(TRIM(email)) LIKE '%@shopexample-qa.test')
UNION ALL
SELECT 'orders', COUNT(*)
FROM orders
WHERE customer_id IN (SELECT customer_id FROM customers
                      WHERE LOWER(TRIM(email)) LIKE '%@shopexample-qa.test');

-- 656 email sends, 365 visits, 29 orders.
-- When creating tables, every view leaves out v_qa_customers.



-- Q: Do all child rows have a parent? (orphan check with LEFT JOIN)

SELECT 'orders -> sessions' AS link, COUNT(*) AS orphans
FROM orders o LEFT JOIN sessions s ON s.session_id = o.session_id
WHERE s.session_id IS NULL
UNION ALL
SELECT 'email_events -> email_sends', COUNT(*)
FROM email_events e LEFT JOIN email_sends s ON s.send_id = e.send_id
WHERE s.send_id IS NULL;

-- 0 orders without a visit, 0 email events without a send.
-- The tables link up correctly.



-- Q: What period does the data cover?

SELECT 'sessions' AS table_name, MIN(session_start) AS first, MAX(session_start) AS last
FROM sessions
UNION ALL SELECT 'orders',      MIN(order_date), MAX(order_date) 
FROM orders
UNION ALL SELECT 'email_sends', MIN(sent_at),    MAX(sent_at)    
FROM email_sends;

-- Visits and orders 1 Jan 2021 - 31 Dec 2023; emails 12 Jan 2021 - 27 Dec 2023.


-- Q: How many visits per month? (checks for gaps and seasonality)


SELECT SUBSTR(session_start, 1, 7) AS month, COUNT(*) AS visits
FROM sessions
GROUP BY month
ORDER BY month;

-- All 36 months present; November and December are the
-- busiest months every year.
