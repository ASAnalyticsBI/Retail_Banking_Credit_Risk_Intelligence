-- ============================================
-- RETAIL BANKING LOAN PERFORMANCE ANALYSIS
-- Author: Ansa Siddiqui
-- Date: April 2026
-- Purpose: OTIF, TAT, Freight Cost Analysis
-- ============================================

use finance_project;


-- Query 1 : Portfolio Overview KPIs
SELECT
    COUNT(*) AS Total_Loans,
    ROUND(SUM(loan_amount)/1e7, 2) AS Portfolio_Value_Crore,
    ROUND(AVG(loan_amount), 0) AS Avg_Loan_Amount,
    ROUND(AVG(interest_rate), 2) AS Avg_Interest_Rate,
    ROUND(AVG(credit_score), 0) AS Avg_Credit_Score,
    ROUND(SUM(CASE WHEN is_defaulted = 1 THEN 1.0 ELSE 0 END) 
          * 100 / COUNT(*), 1) AS Default_Rate_Pct,
    ROUND(SUM(CASE WHEN loan_status = 'NPA' THEN 1.0 ELSE 0 END) 
          * 100 / COUNT(*), 1) AS NPA_Rate_Pct,
    ROUND(SUM(CASE WHEN is_defaulted = 1 THEN loan_amount ELSE 0 END)
          / 1e7, 2) AS At_Risk_Portfolio_Crore,
    ROUND(SUM(amount_recovered) / 
          NULLIF(SUM(CASE WHEN is_defaulted=1 THEN loan_amount END), 0) 
          * 100, 1) AS Recovery_Rate_Pct
FROM loans;


-- Query 2 : Default Rate by Loan Type
WITH loan_summary AS (
    SELECT
        loan_type,
        COUNT(*) AS Total_Loans,
        ROUND(SUM(loan_amount)/1e7, 2) AS Portfolio_Crore,
        ROUND(AVG(credit_score), 0) AS Avg_Credit_Score,
        ROUND(SUM(is_defaulted) * 100.0 / COUNT(*), 1) AS Default_Rate_Pct,
        ROUND(SUM(CASE WHEN loan_status='NPA' THEN 1.0 ELSE 0 END) 
              * 100 / COUNT(*), 1) AS NPA_Rate_Pct,
        ROUND(SUM(CASE WHEN is_defaulted=1 THEN loan_amount ELSE 0 END)/1e7, 2) 
            AS Defaulted_Amount_Crore
    FROM loans
    GROUP BY loan_type
)
SELECT
    loan_type,
    Total_Loans,
    Portfolio_Crore,
    Avg_Credit_Score,
    Default_Rate_Pct,
    NPA_Rate_Pct,
    Defaulted_Amount_Crore,
    ROUND(Portfolio_Crore * 100.0 / SUM(Portfolio_Crore) OVER(), 1) 
        AS Portfolio_Share_Pct,
    RANK() OVER (ORDER BY Default_Rate_Pct DESC) AS Risk_Rank
FROM loan_summary
ORDER BY Default_Rate_Pct DESC;


-- Query 3 : EMI Burden vs Default Risk Matrix
SELECT
    emi_burden_category,
    credit_category,
    COUNT(*) AS Loan_Count,
    ROUND(AVG(loan_amount), 0) AS Avg_Loan_Amount,
    ROUND(SUM(is_defaulted) * 100.0 / COUNT(*), 1) AS Default_Rate_Pct,
    ROUND(SUM(CASE WHEN is_defaulted=1 THEN loan_amount ELSE 0 END)/1e5, 1) 
        AS Defaulted_Amount_Lakh,
    ROUND(AVG(emi_to_income_ratio), 1) AS Avg_EMI_Ratio
FROM loans
GROUP BY emi_burden_category, credit_category
ORDER BY Default_Rate_Pct DESC;


-- Query 4 : Vintage Analysis
WITH vintage AS (
    SELECT
        disbursal_year,
        loan_type,
        COUNT(*) AS Loans_Disbursed,
        ROUND(SUM(loan_amount)/1e7, 2) AS Disbursed_Crore,
        ROUND(SUM(is_defaulted) * 100.0 / COUNT(*), 1) AS Default_Rate_Pct,
        ROUND(AVG(credit_score), 0) AS Avg_Credit_Score
    FROM loans
    GROUP BY disbursal_year, loan_type
),
vintage_ranked AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY loan_type ORDER BY Default_Rate_Pct DESC) 
            AS Worst_Year_Rank,
        ROUND(Default_Rate_Pct - LAG(Default_Rate_Pct) 
              OVER (PARTITION BY loan_type ORDER BY disbursal_year), 1) 
            AS YoY_Default_Change
    FROM vintage
)
SELECT * FROM vintage_ranked
ORDER BY loan_type, disbursal_year;


-- Query 5 : City-wise Risk Concentration
SELECT
    city,
    COUNT(*) AS Total_Loans,
    ROUND(SUM(loan_amount)/1e7, 2) AS Portfolio_Crore,
    ROUND(SUM(is_defaulted) * 100.0 / COUNT(*), 1) AS Default_Rate_Pct,
    ROUND(AVG(credit_score), 0) AS Avg_Credit_Score,
    ROUND(AVG(emi_to_income_ratio), 1) AS Avg_EMI_Burden,
    ROUND(SUM(CASE WHEN is_defaulted=1 THEN loan_amount ELSE 0 END)/1e7, 2) 
        AS At_Risk_Crore,
    ROUND(SUM(loan_amount)*100.0/SUM(SUM(loan_amount)) OVER(), 1) 
        AS Portfolio_Share_Pct
FROM loans
GROUP BY city
ORDER BY Default_Rate_Pct DESC;


-- Query 6 : Recovery Rate Analysis
WITH recovery_analysis AS (
    SELECT
        loan_type,
        employment_type,
        COUNT(*) AS Defaulted_Loans,
        ROUND(SUM(loan_amount)/1e5, 1) AS Total_Defaulted_Lakh,
        ROUND(SUM(amount_recovered)/1e5, 1) AS Total_Recovered_Lakh,
        ROUND(SUM(amount_recovered) * 100.0 / 
              NULLIF(SUM(loan_amount), 0), 1) AS Recovery_Rate_Pct
    FROM loans
    WHERE is_defaulted = 1
    GROUP BY loan_type, employment_type
)
SELECT
    loan_type,
    employment_type,
    Defaulted_Loans,
    Total_Defaulted_Lakh,
    Total_Recovered_Lakh,
    Recovery_Rate_Pct,
    ROUND(Total_Defaulted_Lakh - Total_Recovered_Lakh, 1) AS Unrecovered_Lakh,
    RANK() OVER (ORDER BY Recovery_Rate_Pct ASC) AS Worst_Recovery_Rank
FROM recovery_analysis
ORDER BY Recovery_Rate_Pct ASC;



-- Query 7 : High Risk Customer Profiling 
WITH risk_profile AS (
    SELECT
        loan_id,
        customer_id,
        loan_type,
        city,
        employment_type,
        loan_amount,
        credit_score,
        emi_to_income_ratio,
        loan_status,
        is_defaulted,
        CASE
            WHEN credit_score < 550 AND emi_to_income_ratio > 50 THEN 'Critical Risk'
            WHEN credit_score < 600 AND emi_to_income_ratio > 40 THEN 'High Risk'
            WHEN credit_score < 650 AND emi_to_income_ratio > 35 THEN 'Medium Risk'
            WHEN credit_score >= 750 AND emi_to_income_ratio <= 25 THEN 'Low Risk'
            ELSE 'Moderate Risk'
        END AS risk_tier
    FROM loans
),
risk_summary AS (
    SELECT
        risk_tier,
        COUNT(*) AS Loan_Count,
        ROUND(SUM(loan_amount)/1e7, 2) AS Portfolio_Crore,
        ROUND(SUM(is_defaulted)*100.0/COUNT(*), 1) AS Actual_Default_Rate,
        ROUND(AVG(credit_score), 0) AS Avg_Credit_Score,
        ROUND(AVG(emi_to_income_ratio), 1) AS Avg_EMI_Burden,
        ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER(), 1) AS Portfolio_Share_Pct
    FROM risk_profile
    GROUP BY risk_tier
)
SELECT
    risk_tier,
    Loan_Count,
    Portfolio_Crore,
    Actual_Default_Rate,
    Avg_Credit_Score,
    Avg_EMI_Burden,
    Portfolio_Share_Pct,
    RANK() OVER (ORDER BY Actual_Default_Rate DESC) AS Risk_Rank
FROM risk_summary
ORDER BY Actual_Default_Rate DESC;
