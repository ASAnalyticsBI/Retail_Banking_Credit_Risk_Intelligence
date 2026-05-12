# Retail Banking Loan Performance & Credit Risk Intelligence
**Domain:** Financial Services | **Tools:** Python · SQL · Power BI

## Business Problem
A retail bank's ₹50+ Crore loan portfolio lacked structured 
risk intelligence. Management had no visibility into which 
segments were defaulting, why recovery was below benchmark, 
and which loan cohorts carried highest risk.

## Key Findings

| Metric | Value | Benchmark |
|--------|-------|-----------|
| Portfolio Size | ₹50+ Crore | — |
| Default Rate | 18% | Industry: <10% |
| NPA Rate | 9.49% | RBI Guideline: <5% |
| Recovery Rate | 32.22% | Industry: 65% |
| Critical Risk Default | 73% | — |
| High EMI Burden Borrowers | 34% | — |

## Strategic Recommendations

1. **Tighten Underwriting** — EMI cap 40%, min credit score 600
   → Projected: 15-20% reduction in new defaults

2. **Personal Loan Policy Reform** — Co-borrower mandate above ₹2L
   → Projected: 8-12% default rate reduction

3. **Early Warning System** — Flag at 60-day EMI miss
   → Projected: ₹3-4 Crore additional recovery

4. **2021-22 Vintage Audit** — Proactive restructuring
   → Projected: ₹15-20 Crore stressed book stabilization

## Dashboard — 4 Pages

### Page 1: Executive Overview
![Executive Overview](screenshots/page1_executive_overview.png)

### Page 2: Credit Risk Intelligence
![Credit Risk](screenshots/page2_credit_risk_intelligence.png)

### Page 3: Recovery Analysis
![Recovery](screenshots/page3_recovery_analysis.png)

### Page 4: Strategic Recommendations
![Recommendations](screenshots/page4_recommendations.png)

## Tools & Methods
- **Python:** Data cleaning pipeline — 96.8% data quality achieved
- **SQL:** CTEs, Window Functions (RANK, LAG, NTILE) for risk tiering
- **Power BI:** 4-page dashboard, 8 DAX measures, conditional formatting

## Data Cleaning Summary
| Issue | Count | Action |
|-------|-------|--------|
| Duplicate records | 150 | Removed |
| Missing credit scores | 120 | Median imputation |
| Future-dated entries | 30 | Eliminated |
| **Final quality** | **96.8%** | |
