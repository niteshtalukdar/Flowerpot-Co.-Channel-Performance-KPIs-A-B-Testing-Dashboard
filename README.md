# Flowerpot & Co. – Channel KPI & A/B Test Dashboard

A two-page Power BI dashboard for Flowerpot & Co., a fictional online store selling homeware, clothing, beauty, electronics and outdoor products in five countries. Page 1 tracks how each marketing channel performs month by month. Page 2 reads out three email A/B tests and says whether each result is significant yet.

![Page 1 – Channel KPI Scorecard](Screenshots/page_1_channel_kpi_scorecard.png)

## What the dashboard shows

- **Page 1 – Channel KPI scorecard:** website KPIs (sessions, conversion rate, revenue per session, net revenue) and email KPIs (sends, open rate, click rate, conversion rate, revenue per send, unsubscribe rate). A month picker shows any month from Jan 2021 to Dec 2023, compared with the month before. A headline sentence updates with the month, a channel table ranks all nine channels, and trend charts show every month.
- **Page 2 – A/B test readout:** three email tests, each comparing a variant (B) with the control (A). For each test it shows the hypothesis, the size of each group, the lift, a 95% confidence interval, the p-value and a plain verdict: *Significant*, *Not significant* or *Not yet significant*.

![Page 2 – A/B Test Readout (T01)](Screenshots/page_2_ab_test_t01.png)

<details>
<summary>Page 2 for the other two tests (click to expand)</summary>

**T02 – Lifestyle vs product-grid email layout**

![Page 2 – T02](Screenshots/page_2_ab_test_t02.png)

**T03 – Free shipping vs 15% off offer (still running)**

![Page 2 – T03](Screenshots/page_2_ab_test_t03.png)

</details>

## Key findings

**Channels (Jan 2021 – Dec 2023)**

- Email visits convert best: **6.20%**, about twice the site average of **3.03%**. They also earn the most per visit: **$4.70** against an average of **$2.39**.
- Four channels bring in most of the revenue: Organic Search, Direct, Paid Search and Email. Together they make up about **85%** of net revenue across the three years, and **87%** in December 2023.
- Display (**0.59%**), Organic Social (**0.85%**) and Paid Social (**1.02%**) convert the least.
- November and December are the busiest months every year.

**December 2023 compared with November**

- Sessions fell **3.6%**, and conversion fell **0.24 points** to **3.47%**. Net revenue fell **2.1%** to **$89,529**.
- Email sends rose **157%** (51,149 to 131,599) for the holiday campaigns, while the open rate fell **2.51 points** to **26.65%**.

**A/B tests**

| Test | What changed (B vs A) | Primary metric | Result |
|---|---|---|---|
| T01 | First name in the subject line | Open rate | **26.14% → 29.17% (+11.6%)**. 95% range +2.41 to +3.65 points. **Significant.** Click rate also rose (+10.5%, p = 0.02). |
| T02 | Lifestyle photos instead of a product grid | Click rate | **2.60% → 3.25% (+25.0%)**. 95% range +0.43 to +0.87 points. **Significant.** No clear effect on opens or orders. |
| T03 | 15% off instead of free shipping | Conversion rate | **0.14% → 0.18% (+28.1%)**, but the 95% range is -0.01 to +0.09 points (p = 0.11). **Not yet significant.** The test was still running when the data ends. |

**What this suggests:** use personalised subject lines and the lifestyle layout, and keep T03 running until it reaches its planned end before choosing an offer.

## Tools

| Tool | What it is used for |
|---|---|
| SQLite (DB Browser for SQLite) | Storing the raw data, finding data problems with SQL, preparing tables for Power BI |
| Power Query | Cleaning messy text, dates and currencies; converting money to USD; working out each visit's channel |
| Power BI + DAX | Data model, KPI measures, month-over-month change, A/B test statistics, dynamic headlines |

## About the data

This is synthetic data. It was generated with a seeded Python script to mimic CRM, web analytics and order data for an online store. No real customers or companies are included. The raw files include deliberate data quality problems for cleaning practice. The dataset's original store name is ShopExample, so you will still see "shopexample" in some values, such as test account emails and the staging site address.

- Period: January 2021 – December 2023
- 11 tables, about 3.5 million rows in total
- Source: [Kaggle – Marketing & E-Commerce Analytics Dataset](https://www.kaggle.com/datasets/geethasagarbonthu/marketing-and-e-commerce-analytics-dataset)
- Data descriptions and business rules: [data_dictionary.md](data_dictionary.md)

## How it was built

### Part 1: SQLite – checking and preparing the data

I imported the 11 CSV files into SQLite and used SQL to find data problems and prepare clean tables for Power BI. The files are in the [SQL Queries](SQL%20Queries/) folder.

- **`data_profiling.sql`** finds the problems, such as duplicate rows, 20 internal test accounts, 4,215 staging-site visits, and event types written 13 different ways.
- **`views.sql`** creates six views that fix those problems. Removing the test accounts, staging visits and duplicates takes email sends from 965,024 to 958,618 rows, sessions from 606,384 to 601,804, and orders from 18,571 to 18,486.
- **`validation.sql`** checks the views against the expected numbers, such as a 27.11% email open rate and the A/B test group sizes.

The views were exported to CSV and loaded into Power BI.

### Part 2: Power Query – cleaning

- Mapped values written many ways to one spelling each: email variant (10 ways), delivery status (9), order status (11), currency (11), campaign channel (12) and device (11).
- Read order amounts written in five formats, including the German euro format (`1.204,10 €`), and converted them to USD using monthly exchange rates.
- Worked out each visit's channel from the tracking tags in the web address, then from the referring site. Tags are checked first, so email clicks from Gmail aren't counted as Organic Search.
- Attached each order to its visit, and credited email orders to the email whose click started the visit.

### Part 3: Data model

Two fact tables (`sessions` and `email_sends`) share a `Date` table and a `campaigns` table. A/B test details link through `campaigns`. A small separate table (`AB Metric`) gives the results table one row per metric.

![Data model](Screenshots/data_model.png)

### Part 4: DAX

- **KPIs:** conversion rate, revenue per session, open rate, click rate and others. Email rates use delivered emails.
- **Month-over-month:** % change for counts and money, and change in percentage points for rates.
- **Trend smoothing:** a 3-month average for revenue per session, because small channels swing a lot from month to month.
- **Headlines:** text measures that write a one-sentence summary for the selected month or test.
- **A/B statistics:** lift, a 95% confidence interval for the difference, and a two-proportion z-test with its p-value. The verdict is "Significant" at 95% confidence, and "Not yet significant" if the test is still running.

## Checks

The dashboard's numbers were checked against the dataset's documented expected results, for example 601,804 sessions, a 3.03% conversion rate, $1,440,175 net revenue, a 27.11% email open rate, and the A/B group sizes for all three tests.

## Limits of this analysis

- The data is synthetic, so the findings show the method, not real customer behaviour.
- In the A/B tests, the unit is one delivered email. The same customers received several emails in each test, so the confidence intervals are slightly narrower than they should be.
- Each test checks four metrics. With that many checks, one "significant" result can appear by chance, so the primary metric is the main verdict.
- T03 was still running when the data ends, so its result is interim.
- Email gets credit only for orders placed in a visit that started from a click on that email.
- Some ad spend values in the source are rounded (for example `1.7k`), so total spend is about $38 above the documented figure.
- Revenue is dated by the visit, so a few orders placed just after midnight on a month end count in the previous month.

## Files in this repository

| File or folder | What it is |
|---|---|
| `Channel_performance_and_AB_Testing.pbix` | The Power BI report (open with Power BI Desktop, free for Windows) |
| `flowerpot_dashboard.pdf` | A PDF of both pages |
| `SQL Queries/` | Profiling, view and validation SQL |
| `screenshots/` | Images of both pages and the data model |
| `data_dictionary.md` | Column descriptions and business rules |

## How to rebuild

1. Download the dataset from the source link above.
2. Import each CSV into a new SQLite database with DB Browser for SQLite, naming each table after its file without `_raw`.
3. Run `views.sql`, then `validation.sql`, and check the results match the comments.
4. Export each view to CSV, and point the Power BI queries at your CSV files (Home → Transform data → Data source settings).
