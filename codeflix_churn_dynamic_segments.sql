--Get a feel for the data and structure
SELECT * FROM subscriptions LIMIT 10;

--identify unique values in each column, asd generate ocunts to manually verify the accuracy for future calculations. 
SELECT STRFTIME('%m-%Y',subscription_start) as start_month, COUNT(*) FROM subscriptions
GROUP BY STRFTIME('%m-%Y',subscription_start)
ORDER BY STRFTIME('%Y',subscription_start);

SELECT STRFTIME('%m-%Y',subscription_end)  as end_month, COUNT(*) FROM subscriptions
GROUP BY STRFTIME('%m-%Y',subscription_end);

SELECT segment, COUNT(*) 
FROM subscriptions
GROUP BY segment;

-- Churn can NOT be calculated for December, December was the first month users could sign up and Codeflix requires a minimum subscription length of 31 days, so a user can never start and end their subscription in the same month.

--alias a temporary table with months to check user counts and cancellations during
WITH months AS
(SELECT
  '2017-01-01' AS first_date,
  '2017-01-31' AS last_date
UNION
SELECT
  '2017-02-01' AS first_date,
  '2017-02-28' AS last_date
UNION
SELECT
  '2017-03-01' AS first_date,
  '2017-03-31' AS last_date
),
--Cross join subscriptons with months to pair every subscription record with the start and end datae of every month.
cross_join AS
(SELECT * FROM
  subscriptions CROSS JOIN months
),
-- Identify the users from each segment that were active at the start of each month, and the users who cancelled during a specific month.
status AS
(SELECT id, segment, first_date AS month, 
  CASE
    WHEN (subscription_start < first_date)
      AND ((subscription_end >= first_date) OR (subscription_end IS NULL))
    THEN 1 
    ELSE 0
  END AS is_active,
  CASE
    WHEN (subscription_start < first_date)
      AND (subscription_end BETWEEN first_date AND last_date)
    THEN 1
    ELSE 0
  END AS is_canceled
  FROM cross_join
),
-- Aggregate the users from each segment that were active at the start of each month, and the users who cancelled during a specific month to get total counts.
status_aggregate AS
(SELECT month, segment,
        SUM(is_active) AS sum_active,
        SUM(is_canceled) AS sum_canceled
FROM status
GROUP BY month, segment
),
-- Use those total to calculate the churn for each segment during each month.
churn AS
(SELECT month, segment,
        100.0* sum_canceled/sum_active AS churn_perc
FROM status_aggregate
)
SELECT * FROM churn
ORDER BY segment, month