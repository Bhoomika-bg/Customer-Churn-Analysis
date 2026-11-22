-- Non-destructive import of the cleaned IBM Telco CSV.
-- Prerequisites:
--   1. Run sql/schema.sql first.
--   2. Server variable local_infile must be enabled.
--   3. Client must be started with --local-infile=1.

USE customer_churn;

DROP TABLE IF EXISTS telco_churn_staging;

CREATE TABLE telco_churn_staging (
    customerID         VARCHAR(20)   NOT NULL,
    gender             VARCHAR(6)    NOT NULL,
    SeniorCitizen      TINYINT UNSIGNED NOT NULL,
    Partner            VARCHAR(3)    NOT NULL,
    Dependents         VARCHAR(3)    NOT NULL,
    tenure             TINYINT UNSIGNED NOT NULL,
    PhoneService       VARCHAR(3)    NOT NULL,
    MultipleLines      VARCHAR(20)   NOT NULL,
    InternetService    VARCHAR(20)   NOT NULL,
    OnlineSecurity     VARCHAR(20)   NOT NULL,
    OnlineBackup       VARCHAR(20)   NOT NULL,
    DeviceProtection   VARCHAR(20)   NOT NULL,
    TechSupport        VARCHAR(20)   NOT NULL,
    StreamingTV        VARCHAR(20)   NOT NULL,
    StreamingMovies    VARCHAR(20)   NOT NULL,
    Contract           VARCHAR(20)   NOT NULL,
    PaperlessBilling   VARCHAR(3)    NOT NULL,
    PaymentMethod      VARCHAR(30)   NOT NULL,
    MonthlyCharges     DECIMAL(6,2)  NOT NULL,
    TotalCharges       DECIMAL(10,2) NULL,
    Churn              VARCHAR(3)    NOT NULL,
    PRIMARY KEY (customerID)
) ENGINE=InnoDB;

-- LOAD DATA LOCAL INFILE does not silently skip malformed numeric values.
-- Verify the affected-row count and warnings after execution.
LOAD DATA LOCAL INFILE 'C:/Users/BHOOMIKA/Desktop/Customer-Churn-Analysis/dataset/processed/cleaned_telco.csv'
INTO TABLE telco_churn_staging
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
ESCAPED BY '\\'
LINES TERMINATED BY '\r\n'
IGNORE 1 LINES;

-- Abort the merge if the staging file does not contain exactly 7,043 records.
-- This validation is a data-quality gate, not a silent fallback.
SELECT
    COUNT(*) AS staging_row_count,
    CASE
        WHEN COUNT(*) = 7043 THEN 'PASS'
        ELSE 'FAIL'
    END AS staging_count_check
FROM telco_churn_staging;

-- Reconcile the staging rows into the final table.
-- Existing matching IDs are updated rather than duplicated.
INSERT INTO telco_churn (
    customerID, gender, SeniorCitizen, Partner, Dependents, tenure,
    PhoneService, MultipleLines, InternetService, OnlineSecurity,
    OnlineBackup, DeviceProtection, TechSupport, StreamingTV,
    StreamingMovies, Contract, PaperlessBilling, PaymentMethod,
    MonthlyCharges, TotalCharges, Churn
)
SELECT
    customerID, gender, SeniorCitizen, Partner, Dependents, tenure,
    PhoneService, MultipleLines, InternetService, OnlineSecurity,
    OnlineBackup, DeviceProtection, TechSupport, StreamingTV,
    StreamingMovies, Contract, PaperlessBilling, PaymentMethod,
    MonthlyCharges, TotalCharges, Churn
FROM telco_churn_staging AS source_row
ON DUPLICATE KEY UPDATE
    gender = source_row.gender,
    SeniorCitizen = source_row.SeniorCitizen,
    Partner = source_row.Partner,
    Dependents = source_row.Dependents,
    tenure = source_row.tenure,
    PhoneService = source_row.PhoneService,
    MultipleLines = source_row.MultipleLines,
    InternetService = source_row.InternetService,
    OnlineSecurity = source_row.OnlineSecurity,
    OnlineBackup = source_row.OnlineBackup,
    DeviceProtection = source_row.DeviceProtection,
    TechSupport = source_row.TechSupport,
    StreamingTV = source_row.StreamingTV,
    StreamingMovies = source_row.StreamingMovies,
    Contract = source_row.Contract,
    PaperlessBilling = source_row.PaperlessBilling,
    PaymentMethod = source_row.PaymentMethod,
    MonthlyCharges = source_row.MonthlyCharges,
    TotalCharges = source_row.TotalCharges,
    Churn = source_row.Churn;

-- Final import verification.
SELECT
    COUNT(*) AS final_row_count,
    COUNT(DISTINCT customerID) AS unique_customer_ids
FROM telco_churn;
