# Retail Profit Leakage Analysis

**SQL + Power BI project uncovering where an e-commerce business was losing profit despite growing revenue.**

## The Problem

This retailer was growing revenue, but was it growing profit? Standard sales reporting only shows reported profit (revenue minus cost of goods), which ignores refunds, ad spend, and inventory costs. This project builds a "true profit" view of the business and traces exactly where money was being made and where it was quietly leaking out.

## Tools Used
- **SQL** (Microsoft SQL Server) for data cleaning, joins, aggregation
- **Power BI** — dashboard and visualization

## Key Findings
- True profit margin runs **14–16 percentage points below** reported profit margin, and the gap widened every year from 2022 to 2024.
- **Promotions cut margin by 12+ points without increasing units sold** — discounts aren't paying for themselves.
- **Paid Search is the least efficient ad channel** (ROAS of 6.3) despite getting the largest budget, while Direct and Organic Search deliver far higher returns for a fraction of the cost.
- **Three preventable return reasons** (not as described, defective, wrong item) account for ~$2.56M in refunds, over half of all return costs.
- **Customers aged 55+ generate nearly double the profit** of any other age group, suggesting a possible mismatch between who the business markets to and who actually buys.
- No individual product is loss-making outright, but the **Books category consistently underperforms** relative to Electronics and Clothing.

## Recommendations
| # | Action | Estimated Impact |
|---|---|---|
| 1 | Stop blanket promotions; target discounts narrowly | ~$230,000 recovered margin |
| 2 | Shift ad spend from Paid Search/Social to Organic Search & retention | Largest single opportunity |
| 3 | Fix the top 3 preventable return reasons | ~$512,000 recovered refund cost |
| 4 | Reorder all at-risk/stockout-flagged products immediately | Prevents lost sales |
| 5 | Re-align ad targeting with the proven 55+ customer segment | Protects highest-value segment |

**Combined estimated recoverable value: $750,000–$1,000,000+ per year.**

## Dataset
**Source:** [Global E-commerce and Supply Chain Database](https://www.kaggle.com/datasets/parsakh/global-e-commerce-and-supply-chain-database) (Kaggle)

8 interconnected CSV files simulating a full retail backend:
| Table | Description |
|---|---|
| `transactions` | Core sales ledger — dates, quantity, discount, revenue, cost, profit |
| `customers` | Demographics, geography, premium status |
| `returns` | Return logs — reason, refund amount, restocked flag |
| `products` | Product catalog — category, brand, launch date |
| `price_history` | Monthly pricing — competitor price, promo status, margin |
| `inventory` | Warehouse stock — stock level, reorder point, lead time |
| `supplier_costs` | Vendor costs, lead time, reliability score |
| `marketing_spend` | Monthly ad spend by channel — CAC, ROAS |

**Time period:** January 2022 – December 2024 (36 months)
## Methodology
1. **Data cleaning (SQL):** converted all columns from text to proper data types, checked for nulls, duplicates, and broken foreign-key relationships across all 8 tables.
2. **Analysis (SQL):** 23 core queries covering profit trends, product/customer/channel rankings, pricing and promotion effects, return patterns, and inventory risk.
3. **Visualization (Power BI):** 5-page dashboard — Executive Overview, Products, Marketing, Customers & Pricing, Returns & Inventory — with chart types matched to each question (line charts for trends, waterfall for the profit breakdown, bar charts for rankings, donut charts for categorical splits, conditionally formatted tables for action lists).
