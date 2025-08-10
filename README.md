# Medical-Insurance-Claims-Analysis-and-Fraud-Detection-Using-SQL
# 🏥 Healthcare Claims Fraud Detection Using SQL

This project analyzes synthetic healthcare claims data to detect potential fraud and optimize reimbursement insights. It showcases advanced SQL skills in data cleaning, transformation, anomaly detection, and analytical reporting — aligned with real-world healthcare and insurance analytics.

---

## 📌 Project Objectives

- Clean and prepare raw healthcare claims data
- Join beneficiary and claim data for enriched insights
- Detect suspicious claims using fraud indicators
- Generate analytical reports and KPIs for dashboards

---


## 🗂️ Dataset Overview

Used a synthetic dataset based on Kaggle’s [Healthcare Provider Fraud Detection](https://www.kaggle.com/datasets/rohitrox/healthcare-provider-fraud-detection-analysis).

### Tables:
- `beneficiary.csv` – patient demographics and coverage
- `inpatient.csv` – hospitalization claims
- `outpatient.csv` – outpatient service claims

---

## 🛠️ Tools & Technologies

- **SQL (MySQL)** – core logic for data processing and analytics
- **Power BI / Tableau (optional)** – for data visualization (future steps)
- **Excel / CSVs** – data staging
- **GitHub** – version control and portfolio hosting

---

## ✅ Key SQL Workflows

### 1. Data Cleaning
- Removed duplicate claim records
- Handled nulls in diagnosis fields and date columns
- Standardized gender and added age groups using `DOB`

### 2. Data Transformation
- Calculated claim durations using `DATEDIFF`
- Created age buckets (Under 18, 18–35, 36–60, 60+)
- Joined inpatient and beneficiary tables for enriched insights

### 3. Fraud Detection Logic
- Flagged providers with unusually high claim volumes
- Identified short hospital stays with high reimbursement amounts
- Detected duplicate claims by patient, date, and amount
- Checked for illogical claim dates (e.g., discharge before admission)

### 4. Analytical Queries
- Top 10 providers by claim amount
- Most frequent diagnosis codes
- Claim distribution by gender and age
- Monthly and yearly claims trend
- Patients with the highest number of claims

### 5. KPI Summary (via Views)
- Total claim amount
- Average claims per patient
- Total flagged fraud cases
- Total unique patients and providers

---

## 📊 Sample Output Metrics

| KPI | Value (Example) |
|-----|-----------------|
| Total Claim Amount | $7,212,000 |
| Avg Claims per Patient | 3.4 |
| Flagged Fraud Cases | 294 |
| Unique Patients | 12,000 |
| Unique Providers | 312 |

---

## 🔍 Sample Fraud Detection Logic

```sql
SELECT *
FROM inpatient
WHERE ClaimDuration <= 1 AND InscClaimAmtReimbursed > 10000;
sql
Copy
Edit
SELECT BeneID, AdmissionDt, COUNT(*) AS ClaimCount
FROM inpatient
GROUP BY BeneID, AdmissionDt
HAVING ClaimCount > 1;
