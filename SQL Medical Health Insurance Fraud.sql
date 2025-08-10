  
CREATE DATABASE healthcare_fraud;
USE healthcare_fraud;


CREATE TABLE beneficiary( 
                         BENEID VARCHAR(50) Primary Key, 
                         DOB Date, 
                         DOD Date, 
                         Gender Char(1),
                         Race CHAR(1),
                         RenalDiseaseIndicator VARCHAR(10),
                         StateCHAR VARCHAR(2),
                         County INT,
                         NoOfMonths INT,
                         NoOfMonths_PartBCov INT,
                         ChronicCond_Alzheimer INT,
                         ChronicCond_Heartfailure INT,
                         ChronicCond_KidneyDisease INT,
                         ChronicCond_Cancer INT,
                         ChronicCond_ObstrPulmonary INT,
                         ChronicCond_Depression INT,
                         ChronicCond_Diabetes INT,
                         ChronicCond_IschemicHeart INT,
                         ChronicCond_Osteoporasis INT,
                         ChronicCond_rheumatoidarthritis INT,
                         ChronicCond_stroke INT,
                         IPAnnualReimbursementAmt INT,
                         IPAnnualDeductibleAmt INT,
                         OPAnnualReimbursementAmt INT,
                         OPAnnualDeductibleAmt INT
                         );
						
	ALTER TABLE beneficiary
CHANGE BENEID BeneID VARCHAR(50);

 ALTER Table beneficiary
    CHANGE COLUMN StateCHAR State VARCHAR(2);

    
	CREATE TABLE inpatient (
    ClaimID VARCHAR(50) PRIMARY KEY,
    BeneID VARCHAR(50),
    ClaimStart DATE,
    ClaimEndDt DATE,
    Provider VARCHAR(50),
    InscClaimAmtReimbursed INT,
    AttendingPhysician VARCHAR(50),
    OperatingPhysician VARCHAR(50),
    OtherPhysician VARCHAR(50),
    AdmissionDt DATE,
    ClmAdmitDiagnosisCode VARCHAR(50),
    DeductibleAmtPaid INT,
    DischargeDt DATE,
    DiagnosisGroupCode VARCHAR(50),
    ClmDiagnosisCode_1 VARCHAR(50),
    ClmDiagnosisCode_2 VARCHAR(50),
    ClmDiagnosisCode_3 VARCHAR(50),
    ClmDiagnosisCode_4 VARCHAR(50),
    ClmDiagnosisCode_5 VARCHAR(50),
    ClmDiagnosisCode_6 VARCHAR(50),
    ClmDiagnosisCode_7 VARCHAR(50),
    ClmDiagnosisCode_8 VARCHAR(50),
    ClmDiagnosisCode_9 VARCHAR(50),
    ClmDiagnosisCode_10 VARCHAR(50),
    ClmProcedureCode_1 INT,
    ClmProcedureCode_2 INT,
    ClmProcedureCode_3 INT,
    ClmProcedureCode_4 INT,
    ClmProcedureCode_5 INT,
    ClmProcedureCode_6 INT,
    FOREIGN KEY (BeneID)
        REFERENCES beneficiary (BENEID)
);
        
        CREATE TABLE outpatient (
    ClaimID VARCHAR(50) PRIMARY KEY,
    BeneID VARCHAR(50),
    ClaimStart DATE,
    ClaimEndDt DATE,
    Provider VARCHAR(50),
    InscClaimAmtReimbursed INT,
    AttendingPhysician VARCHAR(50),
    OperatingPhysician VARCHAR(50),
    OtherPhysician VARCHAR(50),
    ClmDiagnosisCode_1 VARCHAR(50),
    ClmDiagnosisCode_2 VARCHAR(50),
    ClmDiagnosisCode_3 VARCHAR(50),
    ClmDiagnosisCode_4 VARCHAR(50),
    ClmDiagnosisCode_5 VARCHAR(50),
    ClmDiagnosisCode_6 VARCHAR(50),
    ClmDiagnosisCode_7 VARCHAR(50),
    ClmDiagnosisCode_8 VARCHAR(50),
    ClmDiagnosisCode_9 VARCHAR(50),
    ClmDiagnosisCode_10 VARCHAR(50),
    ClmProcedureCode_1 INT,
    ClmProcedureCode_2 INT,
    ClmProcedureCode_3 INT,
    ClmProcedureCode_4 INT,
    ClmProcedureCode_5 INT,
    ClmProcedureCode_6 INT,
    DeductibleAmtPaid  INT,
    ClmAdmitDiagnosisCode VARCHAR(50),
    FOREIGN KEY (BeneID)
        REFERENCES beneficiary (BeneID)
);
			
CREATE TABLE potential_fraud (
    Provider VARCHAR(50) PRIMARY KEY
);

 -- 1. DATA CLEANING
-- 1.1 Check or duplicates
SELECT ClaimID, COUNT(*)
FROM inpatient
GROUP BY ClaimID
HAVING COUNT(*)>1;

-- 1.2 Standardizing Gender Column
UPDATE beneficiary 
SET 
    Gender = CASE
        WHEN Gender = 1 THEN 'M'
        WHEN GENDER = 2 THEN 'F'
        ELSE 'U'
    END;
   
   -- 1.3 Standardize Age Groups (create column)
   
ALTER TABLE beneficiary ADD AgeGroup VARCHAR(20);
UPDATE beneficiary
SET AgeGroup = CASE
    WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) < 18 THEN 'Under 18'
    WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 18 AND 35 THEN '18-35'
    WHEN TIMESTAMPDIFF(YEAR, DOB, CURDATE()) BETWEEN 36 AND 60 THEN '36-60'
    ELSE '60+'
END;


-- 1.4 Handle NULLs (Diagnosis Codes)

UPDATE inpatient
SET DiagnosisGroupCode = 'UNKNOWN'
WHERE DiagnosisGroupCode IS NULL OR DiagnosisGroupCode = '';

 
-- 2. DATA TRANSFORMATION

--  2.1 Claim Duration (Inpatient)

ALTER TABLE inpatient
ADD ClaimDuration INT;
UPDATE inpatient
SET ClaimDuration=DATEDIFF(DischargeDt, AdmissionDt);

-- 2.2 Join tables to create enriched claim view
CREATE VIEW vw_enriched_claims AS
SELECT 
i.ClaimID,
i.BeneID,
b.Gender,
b.AgeGroup,
i.Provider,
i.InscClaimAmtReimbursed,
i.AdmissionDt,
i.DischargeDt,
i.ClaimDuration,
i.DiagnosisGroupCode
FROM inpatient i
JOIN beneficiary b ON
i.BeneID = b.BeneID;

--  3. FRAUD DETECTION LOGIC
-- 3.1 High number of claims per provider
WITH provider_claims AS (
    SELECT Provider, COUNT(*) AS ClaimCount
    FROM inpatient
    GROUP BY Provider
),
avg_claims AS (
    SELECT AVG(ClaimCount) AS avg_claims FROM provider_claims
)
SELECT pc.*
FROM provider_claims pc
JOIN avg_claims ac ON 1=1
WHERE pc.ClaimCount > ac.avg_claims;

CREATE VIEW vw_high_claim_providers AS
SELECT pc.*
FROM (
    SELECT Provider, COUNT(*) AS ClaimCount
    FROM inpatient
    GROUP BY Provider
) pc
JOIN (
    SELECT AVG(ClaimCount) AS avg_claims
    FROM (
        SELECT Provider, COUNT(*) AS ClaimCount
        FROM inpatient
        GROUP BY Provider
    ) t
) ac ON 1=1
WHERE pc.ClaimCount > ac.avg_claims;

-- 3.2 Short duration, high reimbursement
CREATE VIEW vw_short_stay_high_cost AS
SELECT *
FROM inpatient
WHERE ClaimDuration <= 1 AND InscClaimAmtReimbursed > 10000;

-- 3.3 Duplicate claims (same patient, same date, same amount)
CREATE VIEW vw_duplicate_claims AS
SELECT BeneID, AdmissionDt, InscClaimAmtReimbursed, COUNT(*) AS dup_count
FROM inpatient
GROUP BY BeneID, AdmissionDt, InscClaimAmtReimbursed
HAVING dup_count > 1;

-- 3.4 Invalid claim dates (Discharge before Admission)
CREATE VIEW vw_invalid_claim_dates AS
SELECT *
FROM inpatient
WHERE DischargeDt < AdmissionDt;


-- 3.5 Negative or zero amounts (possibly invalid or fraudulent)
   SELECT * 
FROM inpatient
WHERE InscClaimAmtReimbursed <= 0;

-- 3.6  Add column to flag duplicate claims
ALTER TABLE inpatient ADD DuplicateFlag BOOLEAN DEFAULT 0;

-- 3.7 Flag duplicate claim (same patient, date, amount)
UPDATE inpatient
SET DuplicateFlag = 1
WHERE ClaimID IN (
    SELECT ClaimID
    FROM (
        SELECT ClaimID
        FROM inpatient
        GROUP BY BeneID, AdmissionDt, InscClaimAmtReimbursed
        HAVING COUNT(*) > 1
    ) dup
);
-- 3.8 Top 5 providers with highest average claim amount:
SELECT Provider, AVG(InscClaimAmtReimbursed) AS avg_claim
FROM 
inpatient
GROUP BY Provider
ORDER BY avg_claim DESC
LIMIT 5;

-- 3.9  Duplicate patient claims on same day (possible double billing)
SELECT BeneID, AdmissionDt, COUNT(*) AS claim_count
FROM inpatient
GROUP BY BeneID, AdmissionDt
HAVING claim_count > 1;



-- 4. ANALYTICAL QUERIES
-- 4.1 Top 10 Provider by Total Claim Amount

SELECT Provider, SUM(InscClaimAmtReimbursed) AS TotalClaimAmount
FROM inpatient
GROUP BY Provider
ORDER BY TotalClaimAmount DESC
LIMIT 10;

-- 4.2 Most Common Diagnosis Codes
SELECT DiagnosisGroupCode, COUNT(*) AS count
FROM inpatient
GROUP BY DiagnosisGroupCode
ORDER BY count DESC
LIMIT 10;

-- 4.3 Patients with Most Claims
SELECT BeneID, COUNT(*) AS claim_amount
FROM inpatient
GROUP BY BeneID
Order By claim_amount DESC
LIMIT 10;

-- 4.4 Claim Trends by Month
SELECT YEAR(AdmissionDt) AS Year, MONTH(AdmissionDt) AS Month, COUNT(*) AS claim_amount
FROM inpatient
GROUP BY YEAR(AdmissionDt), MONTH(AdmissionDt)
ORDER BY Year, Month;

-- 4.5 Gender and Age Distribution of Claims
SELECT b.Gender,b.AgeGroup, COUNT(i.ClaimID) AS ClaimAmount
FROM inpatient i 
JOIN beneficiary b  ON i.BeneID= b.BeneID
GROUP BY b.Gender, b.AgeGroup;

-- 5. KPI Summary Via Views
-- 5.1 Total Claim Amount
CREATE VIEW vw_kpi_total_claim_Amount AS
    SELECT 
        SUM(InscClaimAmtReimbursed) AS TotalClaims
    FROM
        inpatient;
-- 5.2 Average Claim Amount Per Member
CREATE VIEW vw_kpi_average_claim_amount_per_member AS
    SELECT 
        AVG(ClaimCount) AS AvgClaimPerMember
    FROM
        (SELECT 
            BeneID, COUNT(*) AS ClaimCount
        FROM
            inpatient
        GROUP BY BeneID) AS member_claims;
        
-- 5.3 Number of Flagged Fraud Cases

CREATE VIEW vw_kpi_fraud_cases AS
SELECT 
  (SELECT COUNT(*) FROM vw_short_stay_high_cost) +
  (SELECT COUNT(*) FROM vw_duplicate_claims) +
  (SELECT COUNT(*) FROM vw_invalid_claim_dates)
  AS TotalFlaggedCases;   
  
  
  -- 5.4 Total Providers and Patients
CREATE VIEW vw_kpi_totals AS
SELECT 
  (SELECT COUNT(DISTINCT Provider) FROM inpatient) AS TotalProviders,
  (SELECT COUNT(DISTINCT BeneID) FROM beneficiary) AS TotalPatients;


