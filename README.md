# Retail Sales & Store Intelligence Dashboard (2022)

An end-to-end data analyst project: **Python (cleaning) -> MySQL (analysis) -> Power BI (interactive dashboard)**, built on 2.5 million retail transactions.

> **Note:** This is a *Zudio-style scenario* built on a public Kaggle clothes-retail dataset. It is **not** Zudio's internal data, and no company branding is used.

## Dashboard

*(Add your screenshots here, for example `![Final dashboard](screenshots/final_dashboard.png)`)*

The main page has a **zone slicer and a month slicer** that filter the KPI cards, monthly trend, product chart and a **weekday x month sales-intensity heatmap**.

## Business questions

1. When does the business earn most, and when is it weakest?
2. Which zones and stores drive revenue, and how productive is each store?
3. Which product types and price bands matter most?
4. How large are bills, and do discounts differ by zone and month?
5. How many customers come back, and how much do bulk bills distort the averages?

## Data

- **Source:** Kaggle clothes retail dataset (author: nishchay331), yearly CSV files for 2018 to 2022. This project uses the **2022 file**: **2,534,161 rows**, 12 columns.
- **One row = one item on one bill** (not one order): about **541,692 bills**, **338,883 customers**, **258 stores** in 6 zones.
- The raw data is not included (large file). Download it from Kaggle and place it in `data/`.

## Tools and what each was used for

| Tool | Purpose |
|---|---|
| **Python (pandas)** | Understand and clean the data, create flag columns, export |
| **MySQL** | Load 2.5M rows and answer the business questions with repeatable SQL |
| **Power BI** | Star-schema model, DAX measures, slicers, 5-page dashboard |
| **GitHub** | Version control and documentation |

## Process

1. **Understand** (`head`, `shape`, `info`, `isnull`, `duplicated`, `value_counts`, `describe`)
2. **Clean and flag** (nothing deleted: shape stays 2,534,161 rows). See [`docs/cleaning_log.md`](docs/cleaning_log.md)
3. **Load into MySQL** (table `sales_clean`, loaded in 5 parts)
4. **Analyse in SQL** (21 queries: `GROUP BY`, `CASE WHEN`, subqueries). See [`sql/zudio_analysis_queries.sql`](sql/zudio_analysis_queries.sql)
5. **Verify**: monthly revenue, totals and group sums were cross-checked between Python and SQL
6. **Model for slicers:** summary tables by month x zone (and product type, store, weekday) exported from SQL. See [`sql/dashboard_v2_queries.sql`](sql/dashboard_v2_queries.sql)
7. **Visualise** in Power BI

## Power BI data model

A **star schema**: four small fact tables (`fact_month_zone`, `fact_type_zone_month`, `fact_store_month`, `fact_weekday_month_zone`) each connected many-to-one to two dimension tables (`dim_zone`, `dim_month`). Slicers on the dimensions filter every fact table.

**DAX measures:** Total Revenue (Cr), Total Bills, Avg Bill, Discount Rate, Bulk Share, Store Count, Revenue per Day (Lakh).

Revenue, bills, discount and bulk revenue can be added across months and zones. **Customers and store counts cannot**, so they are shown as fixed full-year numbers.

## Key findings

| # | Finding | Evidence |
|---|---|---|
| 1 | **October is the peak month**, February the weakest | Oct: ₹48.48 crore (about 14% of the year), 68,086 bills, highest average bill (₹7,120). Feb: ₹15.21 crore |
| 2 | **Weekends earn about 1.7 times more per day than weekdays** | Average ₹131 lakh per weekend day vs ₹78 lakh per weekday. Busiest cell: Sunday in October (about ₹250 lakh per day) |
| 3 | **South brings about 67% of revenue** | ₹228 crore from 139 of 258 stores. Revenue per store: South about ₹1.64 crore vs North about ₹0.73 crore |
| 4 | **A few products and price bands carry the business** | Shirts (`MSH`) are about 46% of merchandise revenue. The Mid price band (₹1,000 to 2,999) brings about 87% |
| 5 | **Online has small bills and heavy discounts** | Average bill ₹2,527 vs ₹6,889 in South. Discount rate 14.57% vs 1.8 to 2.8% in store zones |
| 6 | **Few customers repeat; bulk bills distort averages** | About 27% of customers shop more than once. The top 1% of bills (above ₹33,184) bring 8.5% of revenue (about 14% in October, about 0.4% online) |

Headline numbers: revenue **₹339.9 crore**, **541,692** bills, **338,883** customers, average bill **₹6,275**, discount given **₹8.18 crore**.

## Data-quality decisions

- **Hidden missing values:** about 2.1M rows in `colour` and `size` contained the text `NOT-CAPTURED`, so `isnull()` missed them. Converted to real missing values.
- **Duplicates were not deleted.** There is no quantity column, and the 558,725 identical rows are spread evenly across zones, months and stores, so they are treated as likely repeat purchases and **flagged** (`is_repeat_row`).
- **Bags, trims and loyalty lines** are 17% of rows but about 0.015% of revenue, so they are flagged (`is_non_merch`).
- **`bill_discount` repeats on every item of a bill.** Summing it gives about ₹33.5 crore; the correct total is about ₹8.2 crore (4 times lower). A `discount_once` column counts each bill once.
- **Bulk bills** (top 1% by bill value) are flagged (`is_bulk_bill`) so averages can be read with and without them.

## Limitations

- No cost or profit data, so **margins are not analysed**.
- Only the **2022** file was analysed (no year-on-year comparison).
- Store names are codes (for example `South_7001`) without city names.
- Product types come from a code in the description (for example `MSH`); meanings are partly inferred.
- Some explanations are hypotheses, not proven: for example why January and July baskets hold more items at lower prices, and why online discounts are high.

## Repository structure

```
retail-sales-analysis/
├── README.md
├── docs/               cleaning_log.md, data_dictionary.md, key_insights.md
├── notebooks/          Python cleaning notebook
├── sql/                zudio_analysis_queries.sql, dashboard_v2_queries.sql
├── powerbi_data/       9 summary CSVs
│   └── dashboard_v2/   6 model tables for the slicer-based dashboard
├── powerbi/            the .pbix dashboard file
├── screenshots/        dashboard screenshots
└── data/               (raw data goes here; not committed)
```

## How to reproduce

1. Download `data_2022.csv` from the Kaggle dataset into `data/`.
2. Run the Python notebook to clean the data and export the cleaned CSV (split into parts for loading).
3. Run Section 0 of the SQL file to create the table and load the data, then the other sections for the analysis.
4. Run `dashboard_v2_queries.sql` and export the tables (or use the ones in `powerbi_data/dashboard_v2/`).
5. Open the Power BI file and refresh the sources.

## About

Built by **Vaibhav**, aspiring Data Analyst based in Pune. Skills shown: Python (pandas), MySQL, Power BI (DAX, data modelling), data cleaning, business analysis.
