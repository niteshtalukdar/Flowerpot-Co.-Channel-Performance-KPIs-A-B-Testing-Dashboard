# Data dictionary



## Files and columns

### customers.csv
| Column | Description |
|---|---|
| customer_id | Customer key (whole number). |
| full_name | Written as `Last, First`. |
| email | Email address. |
| signup_date | Account creation date. **Format depends on `signup_source`** (see business rules). |
| signup_source | `web`, `app` or `store_import` (customers imported from the old in-store system). |
| location | `City, Country`. The country is written several ways, and sometimes missing. |
| age | Age in years at signup. |
| gender | Female, Male, Non-binary, Prefer not to say (written several ways). |
| email_opt_in | Whether the customer agreed to marketing email. |
| acquisition_channel | How the customer first found the store. |

### products.csv
| Column | Description |
|---|---|
| sku | Product code, `SKU-00042`. The number part is the product ID. |
| product_name | Product name. |
| category_path | `Category > Subcategory > Product type`. Some products have only two levels. |
| list_price | Price in **USD**. |
| launch_date | Date the product went on sale. |
| status | Whether the product is still sold. |

### campaigns.csv
An export from the marketing tool. It has **three lines above the header** and a **total line at the bottom**.

| Column | Description |
|---|---|
| campaign_code | Campaign key, `CMP-0001`. The number part can be used as `campaign_id`. |
| campaign_name | Name. |
| channel | Email, Paid Search, Paid Social, Display or Affiliate (written several ways). |
| campaign_type | Newsletter, Promotion, A/B Test, Always-on or Seasonal. |
| start_date, end_date | Campaign dates. For emails, the start date is the send date; the end date is the end of the offer, or 6 days after the send for newsletters and tests. |
| spend | Actual spend in USD. Blank for email (not tracked). |
| subject_line_a, subject_line_b | Email subject lines. `subject_line_b` is filled only for A/B test sends. |
| test_id | Links A/B test sends to `ab_tests`. |

### ab_tests.csv
Already tidy: test_id, test_name, hypothesis, primary_metric, variant_a, variant_b, start_date, planned_end_date, status.

### fx_rates_raw.csv
One row per month, one column per currency (GBP, EUR, CAD, AUD). Values are **USD per 1 unit** of that currency. USD is not in the file; its rate is always 1.

### email_sends.csv
| Column | Description |
|---|---|
| send_id | Key for one email sent to one customer. |
| campaign_code | Which send (campaign) it belongs to. |
| customer_id | Recipient. |
| variant | A or B for A/B test sends, blank or `N/A` otherwise (written several ways). |
| sent_at | Send time (UTC, ISO with `Z`). |
| delivery_status | delivered, hard bounce or soft bounce (written several ways). |

### email_events.csv
One row per engagement event, in long format. A send can have several opens and clicks.

| Column | Description |
|---|---|
| event_id | Row key. |
| send_id | Links to `email_sends`. |
| event_type | open, click, unsubscribe or spam complaint (written several ways). |
| event_time | Time of the event (UTC, ISO with `Z`). |

### sessions.csv
| Column | Description |
|---|---|
| session_id | Visit key. |
| customer_id | Logged-in or identified customer. Anonymous visits are blank, `NULL` or `0`. |
| session_start | Start time. |
| device | Device or operating system as reported by the tracker (iPhone, Windows, iPad, …). |
| landing_page | Full URL of the first page, including tracking parameters (`utm_source`, `utm_medium`, `utm_campaign`, `utm_content`, `eid`, `gclid`, `fbclid`). |
| referrer | Full URL of the site the visitor came from. Blank means none. |
| session_duration | Length of the visit as `hh:mm:ss`. |

### events.csv
| Column | Description |
|---|---|
| event_id | Row key. |
| session_id | Links to `sessions`. |
| event_time | Time of the action. |
| event_name | page_view, product_view, add_to_cart, begin_checkout or purchase (written several ways). |
| product_ref | Product code for product views and add-to-cart events (written several ways). |

### orders.csv
| Column | Description |
|---|---|
| order_number | Order key, `SE-100001`. |
| customer_id | Buyer. |
| session_id | The visit the order was placed in. |
| order_date | Order time. |
| currency | Currency charged. |
| order_status | Completed, Refunded, Partially Refunded or Cancelled (written several ways). |
| discount_code | Code used, if any. |
| shipping_fee | Shipping charged, in the order currency. |
| order_total | Amount charged in the order currency, **as text with a currency symbol**. |
| refund_amount | Amount refunded, same format. Blank means no refund. |
| refund_date | Date of the refund. |

### order_items.csv
| Column | Description |
|---|---|
| order_number | Links to `orders`. |
| line_no | Line number within the order. |
| product_ref | Product code (written several ways). |
| quantity | Units. |
| unit_price | Price per unit in the **order currency**, before discount. Sometimes blank. |
| discount | Discount on the line, as `15%` or `0.15`. Blank means none. |

---

## Business rules

**Signup date formats.** `web` rows use `YYYY-MM-DD`. `app` rows use an ISO timestamp (`2022-05-01T14:03:11Z`); keep the date part. `store_import` rows use **day/month/year** (`04/03/2020` is 4 March 2020).

**Currency.** Each country pays in one currency: United States USD, United Kingdom GBP, Canada CAD, Germany EUR, Australia AUD.

**Pricing rule.** The unit price charged is the USD list price converted at that month's rate: `unit_price = ROUND(list_price_usd / usd_per_unit, 2)`. Use this to fill blank `unit_price` values.

**Line and order totals.** `line_total = ROUND(unit_price × quantity × (1 − discount), 2)`. `order_total = sum of line totals + shipping_fee`.

**Converting to USD.** Multiply by the `usd_per_unit` rate for the order's month and currency, then round to 2 decimals. Refunds use the rate for the **order** month.

**Revenue.**
- Gross revenue (USD) = `order_total_usd` for orders that are not Cancelled.
- Net revenue (USD) = 0 for Cancelled orders, otherwise `order_total_usd − refund_usd`.
- **Orders** in KPIs = orders that are not Cancelled. Refunded orders still count as orders.

**Channel grouping for sessions.** Apply in this order and stop at the first match:
1. `utm_medium` is email or e-mail → **Email**
2. `utm_medium` is cpc or ppc → **Paid Search**
3. `utm_medium` is paid_social, paidsocial or paid-social → **Paid Social**
4. `utm_medium` is display or banner → **Display**
5. `utm_medium` is affiliate → **Affiliate**
6. referrer is google.com, bing.com or duckduckgo.com (but **not** mail.google.com) → **Organic Search**
7. referrer is facebook.com, instagram.com, pinterest.com or t.co → **Organic Social**
8. any other referrer → **Referral**
9. no referrer → **Direct**

The medium is not case-sensitive (`CPC` = `cpc`). `utm_campaign` holds the campaign code in lower case (`cmp-0058` → `CMP-0058`). `eid` is the `send_id` of the email that was clicked.

**Device grouping.** iPad or anything containing "Tablet" → tablet (check this first, because "Android Tablet" contains "Android"). iPhone, Android or Mobile → mobile. Windows, Mac or Desktop → desktop.

**Attribution.** An order is credited to the session it was placed in, and that session's channel and campaign. **Email orders** are orders placed in a session that has an `eid`; they are credited to that send and variant.

**Internal and test data (remove it).**
- Accounts with an email ending in `@shopexample-qa.test` are QA test accounts. Remove the customers **and** their email sends, sessions and orders.
- Sessions whose landing page host is `staging.shopexample.com` are internal testing. Remove them and their events.

**Email metric definitions.**
- Sent = all email_sends rows. Delivered = `delivery_status` is delivered. Bounce rate = 1 − delivered ÷ sent.
- **Opened = has an open event OR a click event.** Some email apps block the tracking image, so a click can arrive with no open recorded. A click proves the email was opened.
- Open rate = opened ÷ delivered. Click rate (CTR) = clicked ÷ delivered. Click-to-open rate = clicked ÷ opened.
- Unsubscribe rate = unsubscribed ÷ delivered.
- Email conversion rate = email orders ÷ delivered. Revenue per delivered email = email net revenue ÷ delivered.

**Website metric definitions.**
- Bounce = a session with only one event.
- Conversion rate = orders ÷ sessions. Revenue per session = net revenue ÷ sessions.
- ROAS (return on ad spend) = revenue from a campaign's sessions ÷ campaign spend.

**A/B tests.**
- Customers were split 50/50 at random when each test started, and stayed in the same group for every send in that test.
- Unit of analysis: one delivered email. Compare variant B with variant A (A is the control).
- Lift = (rate B − rate A) ÷ rate A.
- 95% confidence interval for the difference in rates: `(pB − pA) ± 1.96 × √(pA(1−pA)/nA + pB(1−pB)/nB)`.
- Significance: two-proportion z-test using the pooled rate, `z = (pB − pA) ÷ √(p(1−p)(1/nA + 1/nB))`. Mark **Significant** when |z| ≥ 1.96 (p < 0.05). Otherwise mark **Not yet significant** if the test is still running, and **Not significant** if it has finished.
