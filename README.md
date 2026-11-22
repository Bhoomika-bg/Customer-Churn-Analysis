## Customer Churn Analysis

This project analyzes the IBM Telco Customer Churn dataset using Python and MySQL.

### Dataset

- Raw records: 7,043
- Columns: 21
- Processed CSV: `dataset/processed/cleaned_telco.csv`
- Verified CSV row count: 7,043
- Verified CSV column count: 21
- Duplicate customer IDs in CSV: 0

### SQL Workflow

1. Run `sql/schema.sql` to create or migrate `customer_churn.telco_churn`.
2. Run `sql/import_data.sql` only with a MySQL client that has `--local-infile=1`.
3. Run `sql/data_validation.sql` to verify row counts, duplicates, blanks, numeric ranges, and categories.
4. Run `sql/churn_analysis.sql` for the business and revenue analysis.

The SQL scripts preserve original IBM column names, including `customerID`, `InternetService`, `Contract`, and `Churn`.
The table uses `customerID` as the primary key and stores charges as `DECIMAL` values.

### SQL Files

- `sql/schema.sql`: database/table creation and non-destructive schema migration
- `sql/import_data.sql`: staging-based CSV import and duplicate-safe reconciliation
- `sql/data_validation.sql`: record, duplicate, missing-value, numeric, and category validation
- `sql/churn_analysis.sql`: 15 business-oriented SQL queries

### Current Local Database Status

- MySQL: 8.0.44
- Database: `customer_churn`
- Existing table: `telco_churn`
- Table status after import: 7,043 rows and 7,043 unique customer IDs
- Duplicate customer IDs: 0
- Missing required text values: 0
- Missing `TotalCharges` values: 0
- Invalid numeric values: 0
- Invalid categorical values: 0
- The table has a primary key on `customerID`, range/category check constraints, and indexes for the main analysis dimensions.

### Verified SQL Findings

These findings are calculated directly from `customer_churn.telco_churn`.

- Overall churn rate: 26.54 percent (1,869 churned out of 7,043 customers).
- Churn by contract:
  - Month-to-month: 42.71 percent
  - One year: 11.27 percent
  - Two year: 2.83 percent
- Churn by internet service:
  - Fiber optic: 41.89 percent
  - DSL: 18.96 percent
  - No internet: 7.40 percent
- Churn by payment method:
  - Electronic check: 45.29 percent
  - Mailed check: 19.11 percent
  - Bank transfer (automatic): 16.71 percent
  - Credit card (automatic): 15.24 percent
- Churn by tenure stage:
  - 0-12 months: 47.44 percent
  - 13-24 months: 28.71 percent
  - 25-48 months: 20.39 percent
  - 49+ months: 9.51 percent
- Senior citizen churn rate: 41.68 percent, compared with 23.61 percent for non-senior customers.
- Customers without both online security and technical support had the highest displayed service-segment churn rate: 48.96 percent.
- Average monthly charge:
  - Churned customers: 74.44 (minimum 18.85, maximum 118.35)
  - Retained customers: 61.27 (minimum 18.25, maximum 118.75)
- Month-to-month contracts represented the largest actual monthly-revenue exposure: 120,847.10 from churned customers.
- The highest ranked contract/internet segment was Month-to-month + Fiber optic, with a 54.61 percent churn rate.

These are observed SQL results. They describe association in the dataset and do not independently establish causation.