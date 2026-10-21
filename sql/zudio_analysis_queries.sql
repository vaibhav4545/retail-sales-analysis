/* =====================================================================
   ZUDIO-STYLE RETAIL SALES ANALYSIS 2022  -  ALL MYSQL QUERIES
   Database : zudio_analysis      Table : sales_clean (2,534,161 rows)
   Source   : Kaggle clothes retail dataset, data_2022.csv, cleaned in Python

   HOW TO USE
   - Run this in MySQL Workbench section by section (not all at once).
   - Each analysis query has an "Expected" line so you can check yourself.
   - In Workbench, set Edit > Preferences > SQL Editor > "DBMS connection
     read timeout" to 600 seconds, then restart Workbench. Heavy queries
     (COUNT DISTINCT over 2.5M rows) take 30-90 seconds.

   KEY DEFINITIONS (agreed before analysis)
   - One row = one ITEM on one bill (not one order).
   - Orders    = COUNT(DISTINCT bill_id)         (never COUNT(*))
   - Revenue   = SUM(line_item_amount)           (already after discount)
   - Discount  = SUM(discount_once)              (NEVER SUM(bill_discount):
                 bill_discount repeats on every item of a bill)
   - Real merchandise = WHERE is_non_merch = 0   (excludes bags, trims,
                 loyalty lines: EB, COTHERS, DEFAULT, EARN, CTRIMS, CBG, BCP)
   - Flag columns (nothing was deleted): is_tiny, is_non_merch,
     is_repeat_row, is_bulk_bill (top 1% of bills, bill_total > 33,184)
   ===================================================================== */


/* =====================================================================
   SECTION 0 : SETUP  (database, table, load, verify)
   ===================================================================== */

CREATE DATABASE IF NOT EXISTS zudio_analysis;
USE zudio_analysis;

CREATE TABLE sales_clean (
    row_id             INT AUTO_INCREMENT PRIMARY KEY,
    user_id            BIGINT,
    bill_id            BIGINT,
    line_item_amount   DECIMAL(12,4),
    bill_discount      DECIMAL(12,4),
    transaction_date   DATE,
    description        VARCHAR(100),
    inventory_category VARCHAR(100),
    colour             VARCHAR(30),
    size               VARCHAR(30),
    zone_name          VARCHAR(20),
    store_name         VARCHAR(30),
    sale_year          INT,
    sale_month         INT,
    type_code          VARCHAR(20),
    is_tiny            TINYINT,
    is_non_merch       TINYINT,
    is_repeat_row      TINYINT,
    bill_total         DECIMAL(14,4),
    is_bulk_bill       TINYINT,
    discount_once      DECIMAL(12,4)
);

-- Find the folder MySQL is allowed to read from, copy the CSV parts there:
SHOW VARIABLES LIKE 'secure_file_priv';

-- Load the data in 5 parts (sales_part1.csv ... sales_part5.csv).
-- Change ONLY the file name for each part and run each part ONCE.
-- Windows paths need forward slashes.
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/sales_part1.csv'
INTO TABLE sales_clean
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES
(user_id, bill_id, line_item_amount, bill_discount, transaction_date,
 @description, @inventory_category, @colour, @size, zone_name, store_name,
 sale_year, sale_month, @type_code, is_tiny, is_non_merch, is_repeat_row,
 bill_total, is_bulk_bill, discount_once)
SET description        = NULLIF(@description, ''),
    inventory_category = NULLIF(@inventory_category, ''),
    colour             = NULLIF(@colour, ''),
    size               = NULLIF(@size, ''),
    type_code          = NULLIF(@type_code, '');
-- Repeat for sales_part2.csv ... sales_part5.csv.
-- Running count after each part: 520,000 / 1,040,000 / 1,560,000 / 2,080,000 / 2,534,161
-- If a load went wrong or ran twice, empty the table and start again:
-- TRUNCATE TABLE sales_clean;

-- ----- Verify the load (Section 1) -----------------------------------
SELECT COUNT(*) FROM sales_clean;                       -- Expected: 2,534,161
SELECT SUM(line_item_amount) FROM sales_clean;          -- Expected: about 3,399,087,247
SELECT COUNT(DISTINCT bill_id),
       COUNT(DISTINCT user_id),
       COUNT(DISTINCT store_name) FROM sales_clean;     -- Expected: 541,692 / 338,883 / 258
SELECT COUNT(*) FROM sales_clean WHERE colour IS NULL;  -- Expected: 2,122,057


/* =====================================================================
   SECTION 2 : ZONE ANALYSIS
   ===================================================================== */

-- Q1. Revenue by zone
-- Expected: South 2,283,729,399 | West 397,699,214 | North 341,017,460 |
--           East 258,858,178 | ROOT 100,050,434 | Central 17,732,561
SELECT zone_name, SUM(line_item_amount) AS revenue
FROM sales_clean
GROUP BY zone_name
ORDER BY revenue DESC;

-- Q2. Bills per zone (the 6 numbers add up to 541,692)
SELECT zone_name, COUNT(DISTINCT bill_id) AS bills
FROM sales_clean
GROUP BY zone_name;

-- Q3. Stores per zone (adds up to 258)
-- Expected: Central 1, East 35, North 47, ROOT 1, South 139, West 35
SELECT zone_name, COUNT(DISTINCT store_name) AS stores
FROM sales_clean
GROUP BY zone_name;

-- Q4. Revenue per store by zone
-- Expected: ROOT 100,050,434 | Central 17,732,561 | South 16,429,708 |
--           West 11,362,835 | East 7,395,948 | North 7,255,691
SELECT zone_name,
       SUM(line_item_amount) AS revenue,
       COUNT(DISTINCT store_name) AS stores,
       ROUND(SUM(line_item_amount) / COUNT(DISTINCT store_name), 0) AS revenue_per_store
FROM sales_clean
GROUP BY zone_name
ORDER BY revenue_per_store DESC;

-- Q5. Revenue and bills per zone together
SELECT zone_name,
       SUM(line_item_amount) AS revenue,
       COUNT(DISTINCT bill_id) AS bills
FROM sales_clean
GROUP BY zone_name
ORDER BY revenue DESC;

-- Q6. Average bill value by zone (all bills)
-- Expected: South 6,889 | West 6,664 | Central 6,320 | North 5,788 |
--           East 5,262 | ROOT 2,527
SELECT zone_name,
       ROUND(SUM(line_item_amount) / COUNT(DISTINCT bill_id), 0) AS avg_bill_value
FROM sales_clean
GROUP BY zone_name
ORDER BY avg_bill_value DESC;

-- Q7. Average bill value by zone, WITHOUT bulk bills
-- Expected: South 6,317 | West 6,086 | Central 5,781 | North 5,463 |
--           East 5,064 | ROOT 2,518
SELECT zone_name,
       ROUND(SUM(line_item_amount) / COUNT(DISTINCT bill_id), 0) AS avg_bill_value
FROM sales_clean
WHERE is_bulk_bill = 0
GROUP BY zone_name
ORDER BY avg_bill_value DESC;


/* =====================================================================
   SECTION 3 : TIME ANALYSIS
   ===================================================================== */

-- Q8. Revenue by month  (October about 484,760,440; February about 152,146,598)
SELECT sale_month, SUM(line_item_amount) AS revenue
FROM sales_clean
GROUP BY sale_month
ORDER BY sale_month;

-- Q9. Bills per month (adds up to 541,692; Oct 68,086; Feb 31,204)
SELECT sale_month, COUNT(DISTINCT bill_id) AS bills
FROM sales_clean
GROUP BY sale_month
ORDER BY sale_month;

-- Q10. Revenue, bills and average bill value by month
-- Expected avg_bill_value: Jan 6,274 | Feb 4,876 | Oct 7,120 | Dec 6,690
SELECT sale_month,
       SUM(line_item_amount) AS revenue,
       COUNT(DISTINCT bill_id) AS bills,
       ROUND(SUM(line_item_amount) / COUNT(DISTINCT bill_id), 0) AS avg_bill_value
FROM sales_clean
GROUP BY sale_month
ORDER BY sale_month;


/* =====================================================================
   SECTION 4 : PRODUCTS AND STORES
   ===================================================================== */

-- Q11. Top 10 product types by revenue (real merchandise only)
-- Expected: MSH about 1,563M | MTR 698M | MDE 333M | MTS 235M | SHIRTS 88M ...
SELECT type_code, SUM(line_item_amount) AS revenue
FROM sales_clean
WHERE is_non_merch = 0
GROUP BY type_code
ORDER BY revenue DESC
LIMIT 10;

-- Q12. Top 10 stores by revenue
-- Expected: ROOT_ecomstore 100,050,434 | South_7001 65,178,200 | ...
SELECT store_name, SUM(line_item_amount) AS revenue
FROM sales_clean
GROUP BY store_name
ORDER BY revenue DESC
LIMIT 10;


/* =====================================================================
   SECTION 5 : DISCOUNTS  (always use discount_once)
   ===================================================================== */

-- Q13. Discount by zone  (discount sums to 81,760,185)
-- Expected discount_pct: ROOT 14.57 | East 2.84 | Central 2.49 |
--                        South 1.86 | West 1.80 | North 1.77
SELECT zone_name,
       SUM(line_item_amount) AS revenue,
       SUM(discount_once) AS discount,
       ROUND(SUM(discount_once) / (SUM(line_item_amount) + SUM(discount_once)) * 100, 2) AS discount_pct
FROM sales_clean
GROUP BY zone_name
ORDER BY discount_pct DESC;

-- Q14. Discount by month  (discount sums to 81,760,185)
-- Expected discount_pct: Dec 3.22 | Nov 3.21 | Mar 2.90 | ... | Jul 1.38 (lowest)
SELECT sale_month,
       SUM(line_item_amount) AS revenue,
       SUM(discount_once) AS discount,
       ROUND(SUM(discount_once) / (SUM(line_item_amount) + SUM(discount_once)) * 100, 2) AS discount_pct
FROM sales_clean
GROUP BY sale_month
ORDER BY sale_month;


/* =====================================================================
   SECTION 6 : BASKET ANALYSIS (items per bill, price per item)
   ===================================================================== */

-- Q15. By month (real merchandise only)
-- Expected: Jul 4.59 items / 1,407 | Feb 2.96 items / 1,649
SELECT sale_month,
       ROUND(COUNT(*) / COUNT(DISTINCT bill_id), 2) AS items_per_bill,
       ROUND(SUM(line_item_amount) / COUNT(*), 0) AS avg_item_price
FROM sales_clean
WHERE is_non_merch = 0
GROUP BY sale_month
ORDER BY sale_month;

-- Q16. By zone (real merchandise only)
-- Expected: South 4.32 / 1,595 | West 3.86 | Central 3.78 | North 3.48 |
--           East 3.00 | ROOT 2.10 / 1,201
SELECT zone_name,
       ROUND(COUNT(*) / COUNT(DISTINCT bill_id), 2) AS items_per_bill,
       ROUND(SUM(line_item_amount) / COUNT(*), 0) AS avg_item_price
FROM sales_clean
WHERE is_non_merch = 0
GROUP BY zone_name
ORDER BY items_per_bill DESC;


/* =====================================================================
   SECTION 7 : CASE WHEN AND SUBQUERIES
   ===================================================================== */

-- Q17. Bulk vs normal bills
-- Expected: Bulk 288,222,762 / 5,417 bills | Normal 3,110,864,485 / 536,275 bills
SELECT CASE WHEN is_bulk_bill = 1 THEN 'Bulk' ELSE 'Normal' END AS bill_type,
       SUM(line_item_amount) AS revenue,
       COUNT(DISTINCT bill_id) AS bills
FROM sales_clean
GROUP BY bill_type;

-- Q18. Price bands (real merchandise only)
-- Expected: Low 456,391 | Mid 1,607,934 | High 43,585 items
SELECT CASE
           WHEN line_item_amount < 1000 THEN 'Low'
           WHEN line_item_amount < 3000 THEN 'Mid'
           ELSE 'High'
       END AS price_band,
       COUNT(*) AS items,
       SUM(line_item_amount) AS revenue
FROM sales_clean
WHERE is_non_merch = 0
GROUP BY price_band;

-- Q19. Bills per customer: top 5 customers (top has 159 bills)
SELECT user_id, COUNT(DISTINCT bill_id) AS bills
FROM sales_clean
GROUP BY user_id
ORDER BY bills DESC
LIMIT 5;

-- Q20. One-time vs repeat customers (subquery)
-- Expected: One-time 245,875 | Repeat 93,008 (adds up to 338,883)
SELECT CASE WHEN bills = 1 THEN 'One-time' ELSE 'Repeat' END AS customer_type,
       COUNT(*) AS customers
FROM (
    SELECT user_id, COUNT(DISTINCT bill_id) AS bills
    FROM sales_clean
    GROUP BY user_id
) AS c
GROUP BY customer_type;

-- Q21. Three customer groups
-- Expected: 1 bill 245,875 | 2-4 bills 80,329 | 5+ bills 12,679
SELECT CASE
           WHEN bills = 1 THEN '1 bill'
           WHEN bills <= 4 THEN '2-4 bills'
           ELSE '5+ bills'
       END AS customer_group,
       COUNT(*) AS customers
FROM (
    SELECT user_id, COUNT(DISTINCT bill_id) AS bills
    FROM sales_clean
    GROUP BY user_id
) AS c
GROUP BY customer_group
ORDER BY customers DESC;


/* =====================================================================
   SECTION 8 : EXPORT QUERIES FOR POWER BI
   Run each, then: result grid > "Export recordset to an external file"
   > CSV > save into the powerbi_data folder with the file name shown.
   ===================================================================== */

-- kpi_summary.csv
-- Expected: 3399087247 | 541692 | 338883 | 258 | 6275 | 81760185
SELECT ROUND(SUM(line_item_amount), 0) AS revenue,
       COUNT(DISTINCT bill_id) AS bills,
       COUNT(DISTINCT user_id) AS customers,
       COUNT(DISTINCT store_name) AS stores,
       ROUND(SUM(line_item_amount) / COUNT(DISTINCT bill_id), 0) AS avg_bill_value,
       ROUND(SUM(discount_once), 0) AS discount
FROM sales_clean;

-- monthly_summary.csv
SELECT sale_month,
       ROUND(SUM(line_item_amount), 0) AS revenue,
       COUNT(DISTINCT bill_id) AS bills,
       ROUND(SUM(line_item_amount) / COUNT(DISTINCT bill_id), 0) AS avg_bill_value,
       ROUND(SUM(discount_once), 0) AS discount,
       ROUND(SUM(discount_once) / (SUM(line_item_amount) + SUM(discount_once)) * 100, 2) AS discount_pct
FROM sales_clean
GROUP BY sale_month
ORDER BY sale_month;

-- zone_summary.csv  (the 3-COUNT-DISTINCT version times out in Workbench;
-- this lighter version plus zone_bills.csv works)
SELECT zone_name,
       ROUND(SUM(line_item_amount), 0) AS revenue,
       COUNT(DISTINCT store_name) AS stores,
       ROUND(SUM(line_item_amount) / COUNT(DISTINCT store_name), 0) AS revenue_per_store,
       ROUND(SUM(discount_once) / (SUM(line_item_amount) + SUM(discount_once)) * 100, 2) AS discount_pct
FROM sales_clean
GROUP BY zone_name
ORDER BY revenue DESC;

-- zone_bills.csv
SELECT zone_name, COUNT(DISTINCT bill_id) AS bills
FROM sales_clean
GROUP BY zone_name;

-- top_product_types.csv
SELECT type_code,
       ROUND(SUM(line_item_amount), 0) AS revenue
FROM sales_clean
WHERE is_non_merch = 0
GROUP BY type_code
ORDER BY revenue DESC
LIMIT 10;

-- top_stores.csv
SELECT store_name,
       ROUND(SUM(line_item_amount), 0) AS revenue
FROM sales_clean
GROUP BY store_name
ORDER BY revenue DESC
LIMIT 10;

-- bulk_vs_normal.csv
SELECT CASE WHEN is_bulk_bill = 1 THEN 'Bulk' ELSE 'Normal' END AS bill_type,
       ROUND(SUM(line_item_amount), 0) AS revenue,
       COUNT(DISTINCT bill_id) AS bills
FROM sales_clean
GROUP BY bill_type;

-- price_bands.csv
SELECT CASE
           WHEN line_item_amount < 1000 THEN 'Low'
           WHEN line_item_amount < 3000 THEN 'Mid'
           ELSE 'High'
       END AS price_band,
       COUNT(*) AS items,
       ROUND(SUM(line_item_amount), 0) AS revenue
FROM sales_clean
WHERE is_non_merch = 0
GROUP BY price_band;

-- customer_groups.csv
SELECT CASE
           WHEN bills = 1 THEN '1 bill'
           WHEN bills <= 4 THEN '2-4 bills'
           ELSE '5+ bills'
       END AS customer_group,
       COUNT(*) AS customers
FROM (
    SELECT user_id, COUNT(DISTINCT bill_id) AS bills
    FROM sales_clean
    GROUP BY user_id
) AS c
GROUP BY customer_group;
