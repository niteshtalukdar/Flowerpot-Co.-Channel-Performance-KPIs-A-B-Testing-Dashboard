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


- Period: January 2021 – December 2023
- 11 tables, about 3.5 million rows in total
- Source: [Kaggle – Marketing & E-Commerce Analytics Dataset](https://www.kaggle.com/datasets/geethasagarbonthu/marketing-and-e-commerce-analytics-dataset)
- Data descriptions and business rules: [data_dictionary.md](data_dictionary.md)

