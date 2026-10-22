-- Q1: Pending transfers and the customers involved.
SELECT t.reference,
       sender.full_name AS sender,
       receiver.full_name AS receiver,
       t.amount
FROM public."transaction" AS t
JOIN public.account AS debit ON debit.account_id = t.debit_account_id
JOIN public.customer AS sender ON sender.customer_id = debit.customer_id
JOIN public.account AS credit ON credit.account_id = t.credit_account_id
JOIN public.customer AS receiver ON receiver.customer_id = credit.customer_id
WHERE t.type = 'transfer' AND t.status = 'pending'
ORDER BY t.reference;

-- Q2: Accounts with no debit or credit transaction records.
SELECT a.account_number, c.full_name
FROM public.account AS a
JOIN public.customer AS c ON c.customer_id = a.customer_id
WHERE NOT EXISTS (
    SELECT 1
    FROM public."transaction" AS t
    WHERE t.debit_account_id = a.account_id
       OR t.credit_account_id = a.account_id
)
ORDER BY a.account_number;

-- Q3: Count all transaction records per account, including all statuses.
SELECT a.account_number,
       c.full_name,
       COUNT(t.transaction_id) AS total_transactions
FROM public.account AS a
JOIN public.customer AS c ON c.customer_id = a.customer_id
LEFT JOIN public."transaction" AS t
    ON t.debit_account_id = a.account_id
    OR t.credit_account_id = a.account_id
GROUP BY a.account_id, a.account_number, c.full_name
ORDER BY a.account_number;