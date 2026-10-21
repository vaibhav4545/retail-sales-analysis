# Cleaning Log

Rule: **never delete, flag instead.** Row count stayed at **2,534,161** throughout.

| # | Problem | Evidence | Decision | Reason | Rows affected |
|---|---|---|---|---|---|
| 1 | `transaction_date` stored as text | `info()` showed `object` | Converted to datetime; added `month` | Needed for monthly analysis | 0 deleted |
| 2 | `NOT-CAPTURED` hiding as text in `colour` and `size` | About 2.1M rows; `isnull()` showed only 15,313 | Converted to real missing values | So all tools count them as missing | 0 deleted |
| 3 | `inventory_category` had about 39,000 messy values | Mostly repeated the product description | Built `type_code` from the first word of `description` (94 codes) | Clean grouping | 0 deleted |
| 4 | Near-zero amounts (under ₹10) | 428,429 rows; bags, trims, loyalty lines | Flag `is_tiny` | Keep for transparency | 0 deleted |
| 5 | Non-merchandise codes (EB, COTHERS, DEFAULT, EARN, CTRIMS, CBG, BCP) | 426,251 rows (17%) but about ₹5 lakh of revenue | Flag `is_non_merch` | Otherwise "top product by rows" is a carry bag | 0 deleted |
| 6 | Duplicate rows | 558,725 rows; spread evenly across zones (15 to 25%), months and stores; no quantity column | Flag `is_repeat_row`; do **not** delete | Likely repeat purchases; deleting would remove about 21% of merchandise revenue | 0 deleted |
| 7 | Bulk buyers and extreme bills | Top 1% of bills (above ₹33,184) bring 8.5% of revenue; largest bill has 580 rows | Added `bill_total`; flag `is_bulk_bill` | Report averages with and without bulk bills | 0 deleted |
| 8 | `bill_discount` repeated on every row of a bill | Naive sum about ₹33.5 crore vs about ₹8.2 crore per bill | Added `discount_once` (discount on the first row of each bill only) | Avoid counting a discount once per item | 0 deleted |

## Checks run after cleaning

- Flag totals: `is_tiny` 428,429 / `is_non_merch` 426,251 / `is_repeat_row` 558,725 / `is_bulk_bill` 171,573
- Duplicate count rose from 558,608 to 558,725 after step 2 (117 rows differed only by blank vs `NOT-CAPTURED`)
- `line_item_amount` is **likely already net of discount** (single-item bills: amount + discount is close to the usual price), so discount is not subtracted again
- SQL and Python results matched (monthly revenue, total revenue 3,399,087,247, 541,692 bills)
