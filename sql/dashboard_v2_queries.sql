/* Dashboard v2: tables for slicers (month x zone). Run in MySQL Workbench,
   then export each result as CSV with the file name shown.
   Needs read timeout 600 s (Edit > Preferences > SQL Editor > MySQL Session). */
USE zudio_analysis;

-- fact_month_zone.csv   (72 rows: 12 months x 6 zones)
-- Check: revenue adds up to 3,399,087,247 | bills 541,692 | discount 81,760,185
--        bulk_revenue 288,222,762 | bulk_bills 5,417
SELECT sale_month, zone_name,
       ROUND(SUM(line_item_amount), 2) AS revenue,
       COUNT(DISTINCT bill_id) AS bills,
       ROUND(SUM(discount_once), 2) AS discount,
       ROUND(SUM(CASE WHEN is_bulk_bill = 1 THEN line_item_amount ELSE 0 END), 2) AS bulk_revenue,
       COUNT(DISTINCT CASE WHEN is_bulk_bill = 1 THEN bill_id END) AS bulk_bills
FROM sales_clean
GROUP BY sale_month, zone_name
ORDER BY sale_month, zone_name;

-- fact_type_zone_month.csv   (real merchandise only; revenue adds up to about 3,398,582,841)
SELECT sale_month, zone_name,
       COALESCE(type_code, 'UNKNOWN') AS type_code,
       ROUND(SUM(line_item_amount), 2) AS revenue
FROM sales_clean
WHERE is_non_merch = 0
GROUP BY sale_month, zone_name, COALESCE(type_code, 'UNKNOWN')
ORDER BY sale_month, zone_name, type_code;

-- fact_store_month.csv   (revenue adds up to 3,399,087,247)
SELECT sale_month, store_name, zone_name,
       ROUND(SUM(line_item_amount), 2) AS revenue
FROM sales_clean
GROUP BY sale_month, store_name, zone_name
ORDER BY sale_month, store_name;

-- dim_zone.csv   (6 rows; stores add up to 258)
SELECT zone_name, COUNT(DISTINCT store_name) AS stores
FROM sales_clean
GROUP BY zone_name;

-- dim_month.csv: created by hand (month_num 1-12, month_name, month_short);
-- a ready-made copy is included.

-- fact_weekday_month_zone.csv   (504 rows: 12 months x 7 weekdays x 6 zones)
-- For the "Sales intensity" heatmap. weekday_num: 1 = Monday ... 7 = Sunday.
-- days = how many dates of that weekday exist in that month (4 or 5), used to
-- compute revenue PER DAY so months with five Sundays are not unfairly "busier".
-- Check: revenue adds up to 3,399,087,247 | bills 541,692
-- NOTE: this one was generated in Python; run it in MySQL and compare the totals.
SELECT f.sale_month, f.weekday_num, f.weekday_name, f.zone_name,
       f.revenue, f.bills, d.days
FROM (
    SELECT sale_month,
           WEEKDAY(transaction_date) + 1 AS weekday_num,
           DAYNAME(transaction_date) AS weekday_name,
           zone_name,
           ROUND(SUM(line_item_amount), 2) AS revenue,
           COUNT(DISTINCT bill_id) AS bills
    FROM sales_clean
    GROUP BY sale_month, WEEKDAY(transaction_date) + 1, DAYNAME(transaction_date), zone_name
) AS f
JOIN (
    SELECT sale_month,
           WEEKDAY(transaction_date) + 1 AS weekday_num,
           COUNT(DISTINCT transaction_date) AS days
    FROM sales_clean
    GROUP BY sale_month, WEEKDAY(transaction_date) + 1
) AS d
  ON d.sale_month = f.sale_month AND d.weekday_num = f.weekday_num
ORDER BY f.sale_month, f.weekday_num, f.zone_name;
