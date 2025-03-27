
----1. Identify all transactions flagged as fraudulent.
SELECT * FROM transactions WHERE is_fraud = TRUE;


----2. Find the total fraudulent transactions
SELECT COUNT(*) AS fraud_count FROM transactions WHERE is_fraud = TRUE;


----3. Find the top 5 merchants with the most fraudulent transactions.
SELECT m.merchant_name, COUNT(t.transaction_id) AS fraud_count 
FROM transactions t
JOIN merchant m ON t.merchant_id = m.merchant_id
WHERE t.is_fraud = TRUE
GROUP BY m.merchant_name
ORDER BY fraud_count DESC 
LIMIT 5;

----4. Find avg transaction amount for fraudlent and non fraudulent transactions: false being non-fraudulent, true being fraudulent.
SELECT is_fraud, AVG(amount) AS avg_transaction_amount 
FROM transactions 
GROUP BY is_fraud;

---5. lists the cardholders who have made fraudulaent transactions and number of transactions they have made.
SELECT c.cardholder_id, c.first_name, c.last_name, COUNT(t.transaction_id) AS fraud_count
FROM transactions t
JOIN cardholder c ON t.cardholder_id = c.cardholder_id
WHERE t.is_fraud = TRUE
GROUP BY c.cardholder_id, c.first_name, c.last_name
ORDER BY fraud_count DESC;


----6. Lists the locatations with the highest amount of fradulent activity
SELECT cl.city, COUNT(t.transaction_id) AS fraud_count 
FROM transactions t
JOIN cardholder_location cl ON t.cardholder_id = cl.cardholder_id
WHERE t.is_fraud = TRUE
GROUP BY cl.city
ORDER BY fraud_count DESC
LIMIT 10;


----7. Lists merchants where fraudulent transactions consits of more than 5% of their total transactions
SELECT m.merchant_name, 
       COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) * 100.0 / COUNT(*) AS fraud_percentage
FROM transactions t
JOIN merchant m ON t.merchant_id = m.merchant_id
GROUP BY m.merchant_name
HAVING COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) * 100.0 / COUNT(*) > 5;


----8. Finds the total fraudulent transaction volume per merchant categoy (per scope of business)
SELECT mc.category_name, SUM(t.amount) AS total_fraud_value
FROM transactions t
JOIN merchant m ON t.merchant_id = m.merchant_id
JOIN merchant_category mc ON m.merchant_cat_id = mc.merchant_cat_id
WHERE t.is_fraud = TRUE
GROUP BY mc.category_name
ORDER BY total_fraud_value DESC;


----9.Find any Cardholders Making Transactions at Multiple Merchants on the Same Day, 
--grouped by cardholder name, since one person may be using multiple cards.
--Groups transactions by first_name, last_name, transaction_date (so we track spending per person per day).
--Calculates the total amount spent that day (total_spent).
--Adds and orders by the fraud check: COUNT(CASE WHEN t.is_fraud = TRUE THEN 1 END) AS fraud_transactions
		-- and Counts how many of that person's transactions on that day were flagged as fraudulent.
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
SELECT * FROM transactions WHERE is_fraud = TRUE ORDER BY transaction_date DESC LIMIT 1;



