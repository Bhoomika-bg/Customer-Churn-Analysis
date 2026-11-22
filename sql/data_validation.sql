-- Validation queries for customer_churn.telco_churn
-- Run each query and review unexpected nonzero counts before analysis.

USE customer_churn;

-- 1. Verify the table has exactly the expected IBM dataset row count.
-- COUNT(*) counts every record in the table.
SELECT
    COUNT(*) AS total_records,
    CASE
        WHEN COUNT(*) = 7043 THEN 'PASS'
        ELSE 'FAIL'
    END AS expected_count_check
FROM telco_churn;

-- 2. Compare actual rows with distinct customer IDs.
-- Equal counts confirm that every customer has a unique identifier.
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT customerID) AS unique_customer_ids,
    COUNT(*) - COUNT(DISTINCT customerID) AS duplicate_row_count
FROM telco_churn;

-- 3. Find duplicate customer IDs and how many times each occurs.
-- HAVING keeps only identifiers that occur more than once.
SELECT
    customerID,
    COUNT(*) AS duplicate_count
FROM telco_churn
GROUP BY customerID
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC, customerID;

-- 4. Report missing or whitespace-only values for required text fields.
-- SUM(CASE...) counts a blank value in each field as one.
SELECT
    SUM(CASE WHEN TRIM(customerID) = '' THEN 1 ELSE 0 END) AS missing_customer_id,
    SUM(CASE WHEN TRIM(gender) = '' THEN 1 ELSE 0 END) AS missing_gender,
    SUM(CASE WHEN TRIM(Partner) = '' THEN 1 ELSE 0 END) AS missing_partner,
    SUM(CASE WHEN TRIM(Dependents) = '' THEN 1 ELSE 0 END) AS missing_dependents,
    SUM(CASE WHEN TRIM(PhoneService) = '' THEN 1 ELSE 0 END) AS missing_phone_service,
    SUM(CASE WHEN TRIM(MultipleLines) = '' THEN 1 ELSE 0 END) AS missing_multiple_lines,
    SUM(CASE WHEN TRIM(InternetService) = '' THEN 1 ELSE 0 END) AS missing_internet_service,
    SUM(CASE WHEN TRIM(Contract) = '' THEN 1 ELSE 0 END) AS missing_contract,
    SUM(CASE WHEN TRIM(PaymentMethod) = '' THEN 1 ELSE 0 END) AS missing_payment_method,
    SUM(CASE WHEN TRIM(Churn) = '' THEN 1 ELSE 0 END) AS missing_churn,
    SUM(CASE WHEN TotalCharges IS NULL THEN 1 ELSE 0 END) AS missing_total_charges
FROM telco_churn;

-- 5. Show the exact churn distribution.
-- This verifies that only the two expected labels are present.
SELECT
    Churn,
    COUNT(*) AS customer_count,
    ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM telco_churn), 2) AS percentage
FROM telco_churn
GROUP BY Churn
ORDER BY customer_count DESC;

-- 6. Validate numeric ranges and charge fields.
-- Negative values and out-of-dataset tenure values are counted as invalid.
SELECT
    SUM(CASE WHEN SeniorCitizen NOT IN (0, 1) THEN 1 ELSE 0 END) AS invalid_senior_citizen,
    SUM(CASE WHEN tenure < 0 OR tenure > 72 THEN 1 ELSE 0 END) AS invalid_tenure,
    SUM(CASE WHEN MonthlyCharges < 0 THEN 1 ELSE 0 END) AS invalid_monthly_charges,
    SUM(CASE WHEN TotalCharges IS NOT NULL AND TotalCharges < 0 THEN 1 ELSE 0 END) AS invalid_total_charges
FROM telco_churn;

-- 7. Report numeric and tenure summary statistics.
SELECT
    MIN(tenure) AS minimum_tenure,
    MAX(tenure) AS maximum_tenure,
    ROUND(AVG(tenure), 2) AS average_tenure,
    MIN(MonthlyCharges) AS minimum_monthly_charge,
    MAX(MonthlyCharges) AS maximum_monthly_charge,
    ROUND(AVG(MonthlyCharges), 2) AS average_monthly_charge,
    MIN(TotalCharges) AS minimum_total_charge,
    MAX(TotalCharges) AS maximum_total_charge,
    ROUND(AVG(TotalCharges), 2) AS average_total_charge
FROM telco_churn;

-- 8. Validate binary Yes/No fields.
SELECT
    SUM(CASE WHEN gender NOT IN ('Male', 'Female') THEN 1 ELSE 0 END) AS invalid_gender,
    SUM(CASE WHEN Partner NOT IN ('Yes', 'No') THEN 1 ELSE 0 END) AS invalid_partner,
    SUM(CASE WHEN Dependents NOT IN ('Yes', 'No') THEN 1 ELSE 0 END) AS invalid_dependents,
    SUM(CASE WHEN PhoneService NOT IN ('Yes', 'No') THEN 1 ELSE 0 END) AS invalid_phone_service,
    SUM(CASE WHEN PaperlessBilling NOT IN ('Yes', 'No') THEN 1 ELSE 0 END) AS invalid_paperless_billing,
    SUM(CASE WHEN Churn NOT IN ('Yes', 'No') THEN 1 ELSE 0 END) AS invalid_churn
FROM telco_churn;

-- 9. Validate allowed contract, internet, and three-line-service categories.
-- Each aggregate expression counts values outside the known IBM data labels.
SELECT
    SUM(CASE WHEN Contract NOT IN ('Month-to-month', 'One year', 'Two year') THEN 1 ELSE 0 END) AS invalid_contract,
    SUM(CASE WHEN InternetService NOT IN ('DSL', 'Fiber optic', 'No') THEN 1 ELSE 0 END) AS invalid_internet_service,
    SUM(CASE WHEN MultipleLines NOT IN ('No', 'No phone service', 'Yes') THEN 1 ELSE 0 END) AS invalid_multiple_lines,
    SUM(CASE WHEN OnlineSecurity NOT IN ('No', 'No internet service', 'Yes') THEN 1 ELSE 0 END) AS invalid_online_security,
    SUM(CASE WHEN OnlineBackup NOT IN ('No', 'No internet service', 'Yes') THEN 1 ELSE 0 END) AS invalid_online_backup,
    SUM(CASE WHEN DeviceProtection NOT IN ('No', 'No internet service', 'Yes') THEN 1 ELSE 0 END) AS invalid_device_protection,
    SUM(CASE WHEN TechSupport NOT IN ('No', 'No internet service', 'Yes') THEN 1 ELSE 0 END) AS invalid_tech_support,
    SUM(CASE WHEN StreamingTV NOT IN ('No', 'No internet service', 'Yes') THEN 1 ELSE 0 END) AS invalid_streaming_tv,
    SUM(CASE WHEN StreamingMovies NOT IN ('No', 'No internet service', 'Yes') THEN 1 ELSE 0 END) AS invalid_streaming_movies
FROM telco_churn;

-- 10. Validate the allowed payment method categories.
SELECT
    SUM(CASE WHEN PaymentMethod NOT IN (
        'Electronic check',
        'Mailed check',
        'Bank transfer (automatic)',
        'Credit card (automatic)'
    ) THEN 1 ELSE 0 END) AS invalid_payment_method
FROM telco_churn;

-- 11. Display all unexpected categorical values, if any.
-- These UNION ALL sections keep one distinct category per section.
SELECT 'Contract' AS column_name, telco_churn.Contract AS unexpected_value, COUNT(*) AS row_count
FROM telco_churn
WHERE telco_churn.Contract NOT IN ('Month-to-month', 'One year', 'Two year')
GROUP BY telco_churn.Contract
UNION ALL
SELECT 'InternetService', telco_churn.InternetService, COUNT(*)
FROM telco_churn
WHERE telco_churn.InternetService NOT IN ('DSL', 'Fiber optic', 'No')
GROUP BY telco_churn.InternetService
UNION ALL
SELECT 'PaymentMethod', telco_churn.PaymentMethod, COUNT(*)
FROM telco_churn
WHERE telco_churn.PaymentMethod NOT IN (
    'Electronic check',
    'Mailed check',
    'Bank transfer (automatic)',
    'Credit card (automatic)'
)
GROUP BY telco_churn.PaymentMethod;
