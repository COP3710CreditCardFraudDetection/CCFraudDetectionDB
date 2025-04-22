
----1. Identify all transactions flagged as fraudulent.
-- select all fraudulent transactions.
SELECT * FROM transactions WHERE is_fraud = TRUE;


----2. Find the total fraudulent transactions
-- with FILTER(...) we count all fraudulent flagged transactions as fraud_count
-- count all transactions as total_transactions
SELECT
  COUNT(*) FILTER (WHERE is_fraud = true) AS fraud_count,
  COUNT(*) AS total_transactions
FROM transactions;


----3. Find the top 5 merchants with the most fraudulent transactions.
-- we use JOIN to link transactions to merchants
-- we use GROUP BY and ORDER BY to count and sort frauds per merchant
-- we use a LIMIT 5 to show the top 5
SELECT m.merchant_name, COUNT(t.transaction_id) AS fraud_count 
FROM transactions t
JOIN merchant m ON t.merchant_id = m.merchant_id
WHERE t.is_fraud = TRUE
GROUP BY m.merchant_name
ORDER BY fraud_count DESC 
LIMIT 5;

----4. Find avg transaction amount for fraudlent and non fraudulent transactions: false being non-fraudulent, true being fraudulent.
-- we use GROUP BY on a boolean column to split by fraud flag
-- we Use AVG(amount) to make the comparison between the average amount of true and false.
SELECT is_fraud, AVG(amount) AS avg_transaction_amount 
FROM transactions 
GROUP BY is_fraud;

---5. lists the cardholders who have made fraudulaent transactions and number of transactions they have made.
-- we use GROUP BY with JOIN on carholder_id, first name, and last name to get the owners of the card
-- we use WHERE and GROUP and ORDER by to gather people by fraud count and sort by the amount.
SELECT c.cardholder_id, c.first_name, c.last_name, COUNT(t.transaction_id) AS fraud_count
FROM transactions t
JOIN cardholder c ON t.cardholder_id = c.cardholder_id
WHERE t.is_fraud = TRUE
GROUP BY c.cardholder_id, c.first_name, c.last_name
ORDER BY fraud_count DESC;


----6. Lists the locations with the highest amount of fradulent activity
-- we use multiple JOINs to connect transactions to city info
-- we GROUP BY and ORDER BY to rank cities by fraud volume
-- we use LIMIT restricts result to top 10
SELECT cd.city, COUNT(t.transaction_id) AS fraud_count 
FROM transactions t
JOIN cardholder_location cl ON t.cardholder_id = cl.cardholder_id
JOIN city_details cd ON cl.city_id = cd.city_id
WHERE t.is_fraud = TRUE
GROUP BY cd.city
ORDER BY fraud_count DESC
LIMIT 10;


----7. Lists merchants where fraudulent transactions consits of more than 5% of their total transactions
-- With COUNT(CASE WHEN ..) we count frauds and we divide that by the total number of transactions for that merchant
-- The HAVING clause filters only merchants above a 5% fraud threshold
SELECT m.merchant_name, 
       COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) * 100.0 / COUNT(*) AS fraud_percentage
FROM transactions t
JOIN merchant m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_name
HAVING COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) * 100.0 / COUNT(*) > 5;


----8. Finds the total fraudulent transaction volume per merchant categoy (per scope of business)
-- we do a multi-table JOIN to link transactions to merchants and their business category
-- we SUM transaction amount total fraud dollars for that category
-- we use GROUP BY and ORDER BY to by highest value
SELECT mc.category_name, SUM(t.amount) AS total_fraud_value
FROM transactions t
JOIN merchant m ON t.merchant_id = m.merchant_id
JOIN merchant_category mc ON m.merchant_cat_id = mc.merchant_cat_id
WHERE t.is_fraud = TRUE
GROUP BY mc.category_name
ORDER BY total_fraud_value DESC;


----9.Find any Cardholders Making Transactions at Multiple Merchants on the Same Day, 
-- we use COUNT(DISTINCT ) to track how many different merchants visited per day
-- we use COUNT(CASE WHEN ) for fraud count and we filter for high merchant diversity with HAVING
SELECT 
    c.first_name, 
    c.last_name, 
    t.transaction_date, 
    COUNT(DISTINCT t.merchant_id) AS unique_merchants,
    SUM(t.amount) AS total_spent,
    COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) AS fraud_transactions
FROM transactions t
JOIN cardholder c ON t.cardholder_id = c.cardholder_id
GROUP BY c.first_name, c.last_name, t.transaction_date
HAVING COUNT(DISTINCT t.merchant_id) > 3  
ORDER BY fraud_transactions DESC, unique_merchants DESC, total_spent DESC;


----10. most recent faudulent flagged transaction
-- we use a simple SELECT-FROM-WHERE with ORDER BY and LIMIT
SELECT * FROM transactions WHERE is_fraud = TRUE ORDER BY transaction_date DESC LIMIT 1;



