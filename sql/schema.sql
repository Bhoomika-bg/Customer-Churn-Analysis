-- Customer Churn database and table schema
-- IBM Telco Customer Churn: 21 columns and 7,043 customer records

CREATE DATABASE IF NOT EXISTS customer_churn
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_0900_ai_ci;

USE customer_churn;

-- Create the table only when it does not already exist.
-- Existing rows and other tables are never deleted by this script.
CREATE TABLE IF NOT EXISTS telco_churn (
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

    PRIMARY KEY (customerID),
    CONSTRAINT chk_senior_citizen CHECK (SeniorCitizen IN (0, 1)),
    CONSTRAINT chk_tenure CHECK (tenure BETWEEN 0 AND 72),
    CONSTRAINT chk_monthly_charges CHECK (MonthlyCharges >= 0),
    CONSTRAINT chk_total_charges CHECK (TotalCharges IS NULL OR TotalCharges >= 0),
    CONSTRAINT chk_gender CHECK (gender IN ('Male', 'Female')),
    CONSTRAINT chk_churn CHECK (Churn IN ('Yes', 'No')),
    CONSTRAINT chk_contract CHECK (Contract IN ('Month-to-month', 'One year', 'Two year')),
    CONSTRAINT chk_internet_service CHECK (InternetService IN ('DSL', 'Fiber optic', 'No')),

    INDEX idx_contract (Contract),
    INDEX idx_internet_service (InternetService),
    INDEX idx_payment_method (PaymentMethod),
    INDEX idx_churn (Churn),
    INDEX idx_tenure (tenure)
) ENGINE=InnoDB;

-- The following statements migrate an existing permissive table to the final types.
-- MODIFY is safe for valid data and does not remove rows.
ALTER TABLE telco_churn
    MODIFY customerID VARCHAR(20) NOT NULL,
    MODIFY gender VARCHAR(6) NOT NULL,
    MODIFY SeniorCitizen TINYINT UNSIGNED NOT NULL,
    MODIFY Partner VARCHAR(3) NOT NULL,
    MODIFY Dependents VARCHAR(3) NOT NULL,
    MODIFY tenure TINYINT UNSIGNED NOT NULL,
    MODIFY PhoneService VARCHAR(3) NOT NULL,
    MODIFY MultipleLines VARCHAR(20) NOT NULL,
    MODIFY InternetService VARCHAR(20) NOT NULL,
    MODIFY OnlineSecurity VARCHAR(20) NOT NULL,
    MODIFY OnlineBackup VARCHAR(20) NOT NULL,
    MODIFY DeviceProtection VARCHAR(20) NOT NULL,
    MODIFY TechSupport VARCHAR(20) NOT NULL,
    MODIFY StreamingTV VARCHAR(20) NOT NULL,
    MODIFY StreamingMovies VARCHAR(20) NOT NULL,
    MODIFY Contract VARCHAR(20) NOT NULL,
    MODIFY PaperlessBilling VARCHAR(3) NOT NULL,
    MODIFY PaymentMethod VARCHAR(30) NOT NULL,
    MODIFY MonthlyCharges DECIMAL(6,2) NOT NULL,
    MODIFY TotalCharges DECIMAL(10,2) NULL,
    MODIFY Churn VARCHAR(3) NOT NULL;

-- Add a primary key only if an older version of this table does not have one.
-- Duplicate customer IDs must be resolved before this migration can succeed.
DELIMITER //
CREATE PROCEDURE ensure_telco_customer_primary_key()
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLE_CONSTRAINTS
        WHERE TABLE_SCHEMA = 'customer_churn'
          AND TABLE_NAME = 'telco_churn'
          AND CONSTRAINT_TYPE = 'PRIMARY KEY'
    ) THEN
        ALTER TABLE telco_churn ADD PRIMARY KEY (customerID);
    END IF;
END//
DELIMITER ;

CALL ensure_telco_customer_primary_key();
DROP PROCEDURE ensure_telco_customer_primary_key;
