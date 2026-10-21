# Data Dictionary

**Grain:** one row = one item on one bill. Table: `sales_clean` (2,534,161 rows).

## Original columns

| Column | Meaning | Type | Notes |
|---|---|---|---|
| user_id | Customer ID | BIGINT | 338,883 distinct |
| bill_id | Bill (order) ID | BIGINT | 541,692 distinct; use `COUNT(DISTINCT bill_id)` for orders |
| line_item_amount | Amount for the item | DECIMAL | Likely already after discount |
| bill_discount | Discount on the whole bill | DECIMAL | Repeated on every row of the bill; do not sum |
| transaction_date | Date of sale | DATE | All of 2022 |
| description | Product code and details | VARCHAR | First word is the product-type code |
| inventory_category | Product category | VARCHAR | About 39,000 values (mostly copies of description); not used |
| colour | Product colour | VARCHAR | About 2.1M missing (`NOT-CAPTURED`) |
| size | Product size | VARCHAR | About 2.1M missing |
| zone_name | Sales zone | VARCHAR | South, West, North, East, Central, ROOT (online/main store) |
| store_name | Store | VARCHAR | 258 stores |
| year | Year | INT | Always 2022 (stored as `sale_year`) |

## Columns added during cleaning

| Column | Meaning |
|---|---|
| sale_month (month) | Month number from `transaction_date` |
| type_code | First word of `description`, upper case (94 codes, for example MSH, MTR) |
| is_tiny | 1 if `line_item_amount` is under ₹10 |
| is_non_merch | 1 for EB, COTHERS, DEFAULT, EARN, CTRIMS, CBG, BCP (bags, trims, loyalty lines) |
| is_repeat_row | 1 for the 2nd and later copies of an identical row |
| bill_total | Total `line_item_amount` of the whole bill |
| is_bulk_bill | 1 if `bill_total` is in the top 1% (above ₹33,184) |
| discount_once | `bill_discount` on the first row of each bill, 0 on the others |
