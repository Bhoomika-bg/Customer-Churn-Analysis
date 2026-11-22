-- Business-oriented customer churn analysis queries
-- All calculations use the actual rows stored in customer_churn.telco_churn.

USE customer_churn;

-- 1. Overall churn KPIs.
-- SUM(CASE...) converts the text label "Yes" into a 1 for each churned customer.
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    SUM(CASE WHEN Churn = 'No' THEN 1 ELSE 0 END) AS retained_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent,
    ROUND(AVG(MonthlyCharges), 2) AS average_monthly_charge
FROM telco_churn;

-- 2. Churn rate by contract type.
-- GROUP BY creates a separate result for each contract.
SELECT
    Contract,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent
FROM telco_churn
GROUP BY Contract
ORDER BY churn_rate_percent DESC;

-- 3. Churn rate by InternetService.
-- This identifies whether fiber, DSL, or no internet is associated with higher churn.
SELECT
    InternetService,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent
FROM telco_churn
GROUP BY InternetService
ORDER BY churn_rate_percent DESC;

-- 4. Churn rate by PaymentMethod.
SELECT
    PaymentMethod,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent
FROM telco_churn
GROUP BY PaymentMethod
ORDER BY churn_rate_percent DESC;

-- 5. Churn rate by tenure stage.
-- CASE divides tenure into four relationship-life stages.
SELECT
    CASE
        WHEN tenure <= 12 THEN 'New: 0-12 months'
        WHEN tenure <= 24 THEN 'Developing: 13-24 months'
        WHEN tenure <= 48 THEN 'Established: 25-48 months'
        ELSE 'Long-term: 49+ months'
    END AS tenure_group,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent
FROM telco_churn
GROUP BY tenure_group
ORDER BY MIN(tenure);

-- 6. Churn rate by MonthlyCharges quartile.
-- NTILE is a window function that sorts customers by monthly charge and divides them into four groups.
WITH charge_quartiles AS (
    SELECT
        customerID,
        Churn,
        NTILE(4) OVER (ORDER BY MonthlyCharges) AS charge_quartile
    FROM telco_churn
)
SELECT
    charge_quartile,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent
FROM charge_quartiles
GROUP BY charge_quartile
ORDER BY charge_quartile;

-- 7. Churn rate by senior citizen status.
-- The CASE expression labels 0 and 1 for beginner-friendly output.
SELECT
    CASE
        WHEN SeniorCitizen = 1 THEN 'Senior citizen'
        ELSE 'Not a senior citizen'
    END AS customer_status,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent
FROM telco_churn
GROUP BY customer_status
ORDER BY churn_rate_percent DESC;

-- 8. Churn rate by online security and technical support subscriptions.
-- This produces the 9 combinations of both service choices.
SELECT
    OnlineSecurity,
    TechSupport,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent
FROM telco_churn
GROUP BY OnlineSecurity, TechSupport
HAVING COUNT(*) >= 30
ORDER BY churn_rate_percent DESC;

-- 9. Average monthly charges for churned and retained customers.
-- The CASE expression separates charge averages into the two outcome groups.
SELECT
    Churn,
    COUNT(*) AS customer_count,
    ROUND(AVG(MonthlyCharges), 2) AS average_monthly_charge,
    ROUND(MIN(MonthlyCharges), 2) AS minimum_monthly_charge,
    ROUND(MAX(MonthlyCharges), 2) AS maximum_monthly_charge
FROM telco_churn
GROUP BY Churn
ORDER BY Churn;

-- 10. Revenue-related churn exposure by contract.
-- Monthly revenue is an estimate based on each customer's current monthly charge.
SELECT
    Contract,
    ROUND(SUM(MonthlyCharges), 2) AS total_monthly_revenue,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges ELSE 0 END), 2) AS revenue_from_churned,
    ROUND(
        100.0 * SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges ELSE 0 END)
        / NULLIF(SUM(MonthlyCharges), 0),
        2
    ) AS revenue_exposure_percent
FROM telco_churn
GROUP BY Contract
ORDER BY revenue_from_churned DESC;

-- 11. Revenue-related churn exposure by payment method.
SELECT
    PaymentMethod,
    COUNT(*) AS total_customers,
    ROUND(SUM(MonthlyCharges), 2) AS total_monthly_revenue,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges ELSE 0 END), 2) AS revenue_from_churned
FROM telco_churn
GROUP BY PaymentMethod
ORDER BY revenue_from_churned DESC;

-- 12. Identify high-risk combinations of contract, internet service, and tenure stage.
-- The subquery first calculates metrics for each segment.
WITH customer_segments AS (
    SELECT
        Contract,
        InternetService,
        CASE
            WHEN tenure <= 12 THEN 'New'
            WHEN tenure <= 24 THEN 'Developing'
            WHEN tenure <= 48 THEN 'Established'
            ELSE 'Long-term'
        END AS tenure_group,
        COUNT(*) AS total_customers,
        SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
        ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent
    FROM telco_churn
    GROUP BY Contract, InternetService, tenure_group
)
SELECT *
FROM customer_segments
WHERE total_customers >= 30
ORDER BY churn_rate_percent DESC, total_customers DESC;

-- 13. Rank contract and internet segments by churn rate.
-- RANK() is a window function, so segment rows remain separate while receiving a relative rank.
WITH segment_ranking AS (
    SELECT
        Contract,
        InternetService,
        COUNT(*) AS total_customers,
        ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent
    FROM telco_churn
    GROUP BY Contract, InternetService
)
SELECT
    Contract,
    InternetService,
    total_customers,
    churn_rate_percent,
    RANK() OVER (ORDER BY churn_rate_percent DESC) AS churn_risk_rank
FROM segment_ranking
WHERE total_customers >= 30
ORDER BY churn_risk_rank, Contract, InternetService;

-- 14. Compare churn rates and charge averages for partner/dependent households.
SELECT
    Partner,
    Dependents,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(100.0 * SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_rate_percent,
    ROUND(AVG(MonthlyCharges), 2) AS average_monthly_charge
FROM telco_churn
GROUP BY Partner, Dependents
ORDER BY churn_rate_percent DESC;

-- 15. Rank customers within each contract using monthly charge.
-- This illustrates window ranking for individual churn-risk prioritization.
WITH charge_ranked AS (
    SELECT
        customerID,
        Contract,
        MonthlyCharges,
        Churn,
        RANK() OVER (
            PARTITION BY Contract
            ORDER BY MonthlyCharges DESC
        ) AS charge_rank_within_contract
    FROM telco_churn
)
SELECT *
FROM charge_ranked
WHERE charge_rank_within_contract <= 10
  AND Churn = 'Yes'
ORDER BY Contract, charge_rank_within_contract, customerID;
