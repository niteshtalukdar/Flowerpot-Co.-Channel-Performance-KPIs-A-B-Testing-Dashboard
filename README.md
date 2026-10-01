# Flowerpot & Co. – Channel KPI & A/B Test Dashboard

A two-page Power BI dashboard for Flowerpot & Co., a fictional online store selling homeware, clothing, beauty, electronics and outdoor products in five countries.

## What the dashboard shows

- **Page 1 – Channel KPI scorecard:** website KPIs (sessions, conversion rate, revenue per session) and email KPIs (sends, open rate, click rate, conversion rate, revenue per send, unsubscribe rate), trended month over month.
- **Page 2 – A/B test readout:** three email tests, each comparing a variant with the control, showing lift %, a 95% confidence interval and a plain "significant / not yet significant" flag.

## Tools

| Tool | What it is used for |
|---|---|
| SQLite (DB Browser for SQLite) | Storing the raw data, finding data problems with SQL, preparing tables for Power BI |
| Power Query | Cleaning messy text, dates and currencies; converting money to USD |
| Power BI + DAX | Data model, KPI measures, month-over-month change, A/B test statistics |

## About the data

This is synthetic data. It was generated with a seeded Python script to mimic CRM, web analytics and order data for an online store. No real customers or companies are included. The raw files include deliberate data quality problems for cleaning practice.


## Part 1: SQLite – checking and preparing the data

I imported the 11 CSV files into SQLite and used SQL to find data problems and prepare clean tables for Power BI. The files are in the [SQL Queries](SQL%20Queries/) folder.

- **`data_profiling.sql`**: finds the problems, such as duplicate rows, 20 internal test accounts, 4,215 staging-site visits, and event types written 13 different ways.
- **`views.sql`**: creates six views that fix those problems. Removing the test accounts, staging visits and duplicates takes email sends from 965,024 to 958,618 rows, sessions from 606,384 to 601,804, and orders from 18,571 to 18,486.
- **`validation.sql`**: checks the views against the expected numbers, such as a 27.11% email open rate and the A/B test group sizes.

Problems that SQL doesn't handle well, such as spellings, currencies and dates, are fixed later in Power Query.




- Period: January 2021 – December 2023
- 11 tables, about 3.5 million rows in total
- Source: [Kaggle – Marketing & E-Commerce Analytics Dataset](https://www.kaggle.com/datasets/geethasagarbonthu/marketing-and-e-commerce-analytics-dataset)
- Data descriptions and business rules: [data_dictionary.md](data_dictionary.md)

