-- This shows the list of column names inside the transactions table, so you know what fields exist before writing any query
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'transactions';

-- This checks the transactions table for any missing (NULL) values in any important column. If this returns rows, something is incomplete in that table
SELECT *
FROM transactions
WHERE transaction_id IS NULL
   OR customer_id IS NULL
   OR product_id IS NULL
   OR date IS NULL
   OR quantity IS NULL
   OR unit_price_usd IS NULL
   OR discount_pct IS NULL
   OR revenue_usd IS NULL
   OR cost_usd IS NULL
   OR profit_usd IS NULL
   OR shipping_cost_usd IS NULL
   OR channel IS NULL
   OR payment_method IS NULL
   OR status IS NULL
   OR country IS NULL
   OR category IS NULL;


--This checks the supplier_costs table for missing values in any column
SELECT *
FROM supplier_costs
WHERE product_id IS NULL
   OR category IS NULL
   OR supplier_name IS NULL
   OR supplier_rank IS NULL
   OR unit_cost_usd IS NULL
   OR ordering_cost_usd IS NULL
   OR annual_holding_cost_usd IS NULL
   OR holding_cost_pct IS NULL
   OR lead_time_days IS NULL
   OR min_order_qty IS NULL
   OR reliability_score IS NULL
   OR is_primary IS NULL;

--This checks the returns table for missing values in any column
SELECT *
FROM returns
WHERE return_id IS NULL
   OR transaction_id IS NULL
   OR customer_id IS NULL
   OR product_id IS NULL
   OR return_date IS NULL
   OR reason IS NULL
   OR refund_amount_usd IS NULL
   OR restocked IS NULL;

-- This checks the products table for missing values in any column
SELECT *
FROM products
WHERE product_id IS NULL
   OR name IS NULL
   OR category IS NULL
   OR brand IS NULL
   OR unit_price_usd IS NULL
   OR unit_cost_usd IS NULL
   OR weight_kg IS NULL
   OR is_active IS NULL
   OR launch_date IS NULL;

-- Tis checks the customers table for missing values in any column
SELECT *
FROM customers
WHERE customer_id IS NULL
   OR first_name IS NULL
   OR last_name IS NULL
   OR country IS NULL
   OR currency IS NULL
   OR age IS NULL
   OR gender IS NULL
   OR registration_date IS NULL
   OR is_premium IS NULL
   OR email_verified IS NULL
   OR email IS NULL;


--This checks the inventory table for missing values in any column
SELECT *
FROM inventory
WHERE product_id IS NULL
   OR category IS NULL
   OR stock_units IS NULL
   OR reorder_point IS NULL
   OR warehouse_location IS NULL
   OR last_restock_date IS NULL
   OR supplier_lead_days IS NULL;


--This checks the marketing_spend table for missing values in any column
SELECT *
FROM marketing_spend
WHERE year_month IS NULL
   OR channel IS NULL
   OR spend_usd IS NULL
   OR impressions IS NULL
   OR clicks IS NULL
   OR ctr IS NULL
   OR actual_orders IS NULL
   OR actual_customers IS NULL
   OR actual_revenue_usd IS NULL
   OR roas IS NULL
   OR cac_usd IS NULL
   OR cost_per_order_usd IS NULL
   OR month_multiplier IS NULL;


--This checks the price_history table for missing values in any column
SELECT *
FROM price_history
WHERE product_id IS NULL
   OR category IS NULL
   OR year_month IS NULL
   OR listed_price_usd IS NULL
   OR base_price_usd IS NULL
   OR competitor_price_usd IS NULL
   OR price_index IS NULL
   OR is_promotional IS NULL
   OR price_elasticity IS NULL
   OR units_sold IS NULL
   OR revenue_usd IS NULL
   OR margin_pct IS NULL;


--This shows each column in transactions along with its data type (text, number, date, etc.), so you know whether it needs converting before doing math or date operations on it
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'transactions'
ORDER BY ORDINAL_POSITION;


-- Same check, but for the inventory table
SELECT COLUMN_NAME, DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'inventory'
ORDER BY ORDINAL_POSITION;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Q1. How much money does the shop really make, month by month? Compares Revenue, Reported Profit, and True Profit (after refunds and ad spend) for each month
WITH sales AS (
    SELECT CONVERT(CHAR(7), [date], 23) AS year_month,
           SUM(revenue_usd) AS revenue,
           SUM(profit_usd)  AS reported_profit
    FROM transactions
    GROUP BY CONVERT(CHAR(7), [date], 23)
),
refunds AS (
    SELECT CONVERT(CHAR(7), t.[date], 23) AS year_month,
           SUM(r.refund_amount_usd) AS refunds
    FROM returns r
    JOIN transactions t ON r.transaction_id = t.transaction_id
    GROUP BY CONVERT(CHAR(7), t.[date], 23)
),
ads AS (
    SELECT LEFT(year_month, 7) AS year_month, SUM(spend_usd) AS ad_spend
    FROM marketing_spend
    GROUP BY LEFT(year_month, 7)
)
SELECT s.year_month, s.revenue, s.reported_profit,
       ISNULL(r.refunds, 0)  AS refunds,
       ISNULL(a.ad_spend, 0) AS ad_spend,
       s.reported_profit - ISNULL(r.refunds, 0) - ISNULL(a.ad_spend, 0) AS true_profit
FROM sales s
LEFT JOIN refunds r ON s.year_month = r.year_month
LEFT JOIN ads a     ON s.year_month = a.year_month
ORDER BY s.year_month;

-- Q2. This shows the 10 products that bring in the most profit
SELECT TOP 10 t.product_id, p.name, p.category,
       SUM(t.revenue_usd) AS revenue, SUM(t.profit_usd) AS profit
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY t.product_id, p.name, p.category
ORDER BY profit DESC;

-- Q3.This shows the 10 products that are losing the most money
SELECT TOP 10 t.product_id, p.name, p.category,
       SUM(t.revenue_usd) AS revenue, SUM(t.profit_usd) AS profit
FROM transactions t
JOIN products p ON t.product_id = p.product_id
GROUP BY t.product_id, p.name, p.category
ORDER BY profit ASC;

-- Q4. This compares ad spend against the revenue and profit each channel brought in, and calculates ROAS, profit after ads, and cost per customer, to see which channels are actually worth the money
WITH ads AS (
    SELECT channel, SUM(spend_usd) AS spend, SUM(actual_customers) AS customers
    FROM marketing_spend
    GROUP BY channel
),
sales AS (
    SELECT channel, SUM(revenue_usd) AS revenue, SUM(profit_usd) AS profit
    FROM transactions
    GROUP BY channel
)
SELECT a.channel, a.spend, s.revenue, s.profit,
       ROUND(s.revenue / NULLIF(a.spend, 0), 2)   AS roas,
       ROUND(s.profit - a.spend, 0)               AS profit_after_ads,
       ROUND(a.spend / NULLIF(a.customers, 0), 2) AS cost_per_customer
FROM ads a
LEFT JOIN sales s ON a.channel = s.channel
ORDER BY profit_after_ads DESC;


-- Q5. This compares premium vs non-premium customers on orders, revenue, profit, and revenue per customer, to see if premium members are actually worth more
SELECT c.is_premium,
       COUNT(DISTINCT t.customer_id) AS customers,
       COUNT(*) AS orders,
       SUM(t.revenue_usd) AS revenue,
       SUM(t.profit_usd) AS profit,
       ROUND(SUM(t.revenue_usd) / COUNT(DISTINCT t.customer_id), 2) AS revenue_per_customer
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.is_premium;

-- Q6.This shows the 10 customers who brought in the most profit
SELECT TOP 10 t.customer_id, c.country, c.is_premium,
       COUNT(*) AS orders, SUM(t.revenue_usd) AS revenue, SUM(t.profit_usd) AS profit
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY t.customer_id, c.country, c.is_premium
ORDER BY profit DESC;

-- Q7. This shows total orders, revenue, and profit broken down by customer's country
SELECT c.country, COUNT(*) AS orders, SUM(t.revenue_usd) AS revenue, SUM(t.profit_usd) AS profit
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY c.country
ORDER BY profit DESC;

-- Q8. This groups customers into age bands and shows total orders, revenue, and profit per age group
SELECT CASE WHEN c.age < 25 THEN 'Under 25'
            WHEN c.age < 35 THEN '25-34'
            WHEN c.age < 45 THEN '35-44'
            WHEN c.age < 55 THEN '45-54'
            ELSE '55+' END AS age_group,
       COUNT(*) AS orders, SUM(t.revenue_usd) AS revenue, SUM(t.profit_usd) AS profit
FROM transactions t
JOIN customers c ON t.customer_id = c.customer_id
GROUP BY CASE WHEN c.age < 25 THEN 'Under 25'
              WHEN c.age < 35 THEN '25-34'
              WHEN c.age < 45 THEN '35-44'
              WHEN c.age < 55 THEN '45-54'
              ELSE '55+' END
ORDER BY profit DESC;

-- Q9. This checks whether being priced cheaper, the same, or more expensive than competitors affects how many units get sold, broken down by category
SELECT category, price_position,
       COUNT(*) AS product_months,
       ROUND(AVG(units_sold * 1.0), 1) AS avg_units_sold
FROM (
    SELECT category, units_sold,
           CASE WHEN listed_price_usd / NULLIF(competitor_price_usd, 0) < 0.95 THEN '1. Cheaper than competitor'
                WHEN listed_price_usd / NULLIF(competitor_price_usd, 0) <= 1.05 THEN '2. About the same'
                ELSE '3. More expensive' END AS price_position
    FROM price_history
) x
GROUP BY category, price_position
ORDER BY category, price_position;

-- Q10. This compares promoted vs non-promoted products on units sold, revenue, and margin, to see if promotions actually help or just move volume without real profit
SELECT is_promotional,
       COUNT(*) AS product_months,
       ROUND(AVG(units_sold * 1.0), 1) AS avg_units_sold,
       ROUND(AVG(revenue_usd), 2) AS avg_revenue,
       ROUND(AVG(margin_pct), 4) AS avg_margin
FROM price_history
GROUP BY is_promotional;

-- Q11. This shows what percentage of orders get returned in each product category, and how much money was refunded
SELECT t.category,
       COUNT(*) AS orders,
       COUNT(DISTINCT r.transaction_id) AS returned_orders,
       ROUND(100.0 * COUNT(DISTINCT r.transaction_id) / COUNT(*), 2) AS return_rate_pct,
       SUM(ISNULL(r.refund_amount_usd, 0)) AS money_refunded
FROM transactions t
LEFT JOIN returns r ON t.transaction_id = r.transaction_id
GROUP BY t.category
ORDER BY return_rate_pct DESC;

-- Q12. This shows how many returns happened for each reason, how much was refunded, and how many of those returned items made it back into stock
SELECT reason, COUNT(*) AS returns, SUM(refund_amount_usd) AS refunded,
       SUM(CASE WHEN restocked = 1 THEN 1 ELSE 0 END) AS restocked_back
FROM returns
GROUP BY reason
ORDER BY returns DESC;

-- Q13. This looks at how fast each product has been selling in the last 90 days, compares that to current stock, and flags products that need reordering now, will run out before restock, or are overstocked
DECLARE @end DATE = (SELECT MAX([date]) FROM transactions);

WITH v AS (
    SELECT product_id, SUM(quantity) / 90.0 AS daily_units
    FROM transactions
    WHERE [date] > DATEADD(DAY, -90, @end)
    GROUP BY product_id
)
SELECT i.product_id, i.category, i.stock_units, i.reorder_point, i.supplier_lead_days,
       ROUND(v.daily_units, 2) AS daily_units_sold,
       ROUND(i.stock_units / NULLIF(v.daily_units, 0), 0) AS days_of_stock_left,
       CASE WHEN i.stock_units <= i.reorder_point THEN 'Reorder now'
            WHEN i.stock_units / NULLIF(v.daily_units, 0) < i.supplier_lead_days THEN 'Will run out before restock'
            WHEN i.stock_units / NULLIF(v.daily_units, 0) > 180 THEN 'Overstocked'
            ELSE 'OK' END AS stock_flag
FROM inventory i
LEFT JOIN v ON i.product_id = v.product_id
ORDER BY days_of_stock_left;

-- Q14. This adds up how many products are losing money overall, and how much total profit is being lost to them
SELECT COUNT(*) AS loss_making_products, SUM(profit) AS total_loss
FROM (
    SELECT product_id, SUM(profit_usd) AS profit
    FROM transactions
    GROUP BY product_id
    HAVING SUM(profit_usd) < 0
) x;

-- Q15. This counts every customer registered in the system, whether they've ordered or not
SELECT COUNT(*) AS total_customers
FROM customers;

-- Q16. This counts only the customers who have actually placed at least one order
SELECT COUNT(DISTINCT customer_id) AS total_customers_with_orders
FROM transactions;

-- Q17. This adds up the total profit figure as reported directly in the transactions table, before accounting for refunds or ad spend
SELECT SUM(profit_usd) AS total_reported_profit
FROM transactions;


-- Q18. This calculates the real total profit after subtracting total refunds and total ad spend from reported profit
WITH total_profit AS (
    SELECT SUM(profit_usd) AS reported_profit
    FROM transactions
),
total_refunds AS (
    SELECT SUM(refund_amount_usd) AS refunds
    FROM returns
),
total_ads AS (
    SELECT SUM(spend_usd) AS ad_spend
    FROM marketing_spend
)
SELECT p.reported_profit,
       ISNULL(r.refunds, 0)   AS refunds,
       ISNULL(a.ad_spend, 0)  AS ad_spend,
       p.reported_profit - ISNULL(r.refunds, 0) - ISNULL(a.ad_spend, 0) AS total_true_profit
FROM total_profit p
CROSS JOIN total_refunds r
CROSS JOIN total_ads a;

-- Q19. This calculates the overall profit margin percentage (reported profit divided by total revenue)
SELECT SUM(profit_usd) AS total_reported_profit,
       SUM(revenue_usd) AS total_revenue,
       ROUND(100.0 * SUM(profit_usd) / NULLIF(SUM(revenue_usd), 0), 2) AS overall_margin_pct
FROM transactions;

-- Q20. This builds the data for a waterfall chart (for March 2024), showing Revenue, then Refunds and Ad Spend as money leaving, ending with the final True Profit
WITH totals AS (
    SELECT 
        (SELECT SUM(revenue_usd) FROM transactions WHERE CONVERT(CHAR(7), [date], 23) = '2024-03') AS revenue,
        (SELECT SUM(refund_amount_usd) FROM returns r JOIN transactions t ON r.transaction_id = t.transaction_id 
         WHERE CONVERT(CHAR(7), t.[date], 23) = '2024-03') * -1 AS refunds,
        (SELECT SUM(spend_usd) FROM marketing_spend WHERE LEFT(year_month, 7) = '2024-03') * -1 AS ad_spend
)
SELECT 'Revenue' AS category, 1 AS sort_order, revenue AS amount FROM totals
UNION ALL
SELECT 'Refunds', 2, refunds FROM totals
UNION ALL
SELECT 'Ad Spend', 3, ad_spend FROM totals
UNION ALL
SELECT 'True Profit', 4, revenue + refunds + ad_spend FROM totals
ORDER BY sort_order;

-- Q21. This shows how many product-months fall into each pricing position (cheaper, same, or more expensive than competitor), for an overall pie chart
SELECT 
    CASE WHEN listed_price_usd / NULLIF(competitor_price_usd, 0) < 0.95 THEN 'Cheaper'
         WHEN listed_price_usd / NULLIF(competitor_price_usd, 0) <= 1.05 THEN 'About the Same'
         ELSE 'More Expensive' END AS price_position,
    COUNT(*) AS product_months
FROM price_history
GROUP BY 
    CASE WHEN listed_price_usd / NULLIF(competitor_price_usd, 0) < 0.95 THEN 'Cheaper'
         WHEN listed_price_usd / NULLIF(competitor_price_usd, 0) <= 1.05 THEN 'About the Same'
         ELSE 'More Expensive' END;

-- Q22. This shows how much revenue came from promoted vs non-promoted products, for a pie chart
SELECT is_promotional,
       SUM(revenue_usd) AS revenue
FROM price_history
GROUP BY is_promotional;

-- Q23. This shows how many returns happened for each reason, for a pie chart
SELECT reason, COUNT(*) AS returns
FROM returns
GROUP BY reason
ORDER BY returns DESC;