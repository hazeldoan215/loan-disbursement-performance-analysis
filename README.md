# Loan Disbursement Performance Analysis (Q1 vs Q2 2025)

> **Volume-driven demand vs. conversion and ticket-size contraction**
> A fintech case study: why did disbursed loan value fall ~15% in Q2 even though marketing spend rose 25% and applications rose 35%?

**Tools:** PostgreSQL (data inspection) · Power BI + DAX (driver decomposition, dashboard) 
**Author:** Hien (Hazel) Doan

*Currency is Vietnamese dong (VND). "bn" = billion VND, "M" = million VND.*

---

## 1. Business Problem

In Q2, marketing spend increased **25%** (20bn → 25bn VND) and loan applications increased **35%** (100K → 135K). Yet total disbursed value **fell 14.8%**, from 2,401bn to 2,045bn VND.

**Questions:** What is the root cause, and which stage of the funnel should be optimized first?

## 2. Analytical Framework

Disbursed value is decomposed into four multiplicative drivers:

```
Disbursed Value = Applications × Approval Rate × Disbursement Rate × Average Disbursed Value (ADV)
```

| Metric | Q1 | Q2 | Change (relative) |
|---|---|---|---|
| Marketing spend | 20bn | 25bn | +25% |
| Applications | 100,000 | 135,000 | +35% |
| Approved applications | 55,000 | 59,535 | +8% |
| Disbursed applications | 47,848 | 47,969 | ~flat |
| Approval rate | 55.0% | 44.1% | ≈ −20% |
| Disbursement rate | 87.0% | 80.6% | ≈ −7.4% |
| ADV | 50.2M | 42.6M | −15% |
| **Disbursed value** | **2,401bn** | **2,045bn** | **−14.8%** |

Waterfall of the change in disbursed value (bn VND):

| Q1 value | Applications | Approval rate | Disbursement rate | ADV | Q2 value |
|---|---|---|---|---|---|
| 2,401 | **+666** | **−490** | **−170** | **−362** | 2,045 |

Applications is the only driver that grew. Approval rate is the largest drag, followed by ADV, then disbursement rate. The extra applications barely moved through the funnel: applications +35%, approvals only +8%, disbursed loans flat.

## 3. Dataset

Six tables in PostgreSQL schema `case1_finance`:

| Table | Role | Grain | Rows |
|---|---|---|---|
| `loan_application` | Application fact | 1 row / application | 235,000 |
| `credit_assessment` | Credit decision | 1 row / application | 235,000 |
| `loan_disbursement` | Disbursement outcome | 1 row / application | 235,000 |
| `customer_profile` | Customer dimension | 1 row / customer | 235,000 |
| `marketing_performance` | Marketing performance | date × channel × campaign | 1,177 |
| `dim_date` | Date dimension | 1 row / date | 212 |

**Data inspection (SQL):** grain and key checks for every table, null checks (no nulls found), and range checks on numerical fields (negative / zero amounts, min / max). Zero values in `approved_limit` and `disbursed_amount` correspond to rejected / non-disbursed applications. The SQL covers inspection and baseline metrics only; the analysis and driver decomposition are built in Power BI with DAX.

> **Data limitation:** there is no interest-rate field, so the "offer declined – interest rate" reason can only be reported by share, not explained further.

## 4. Key Findings

### Finding 1: Volume rose, but approval rate, disbursement rate and ADV all fell
Only the application count grew. The other three drivers all declined (table above).

### Finding 2: All three declines trace back to one campaign, `TikTok_Personal_Loan`, which only started in Q2
- It took **42% of the Q2 budget (10.5bn)** and **45% of applications**, but produced only **6.7% of disbursed value (138bn)**.
- Approval rate of **18%**, versus **65.5%** for all other campaigns. Excluding TikTok, Q2 approval rate (65.5%) is *higher* than Q1 (55.0%), and every income group and risk band improves.
- Its applicants: **92%** earn under 20M/month, average credit score **575** (vs ~683 elsewhere), **64%** in the two riskiest bands (D–E), click-to-lead rate only **19%**, plus duplicate / suspicious applications.

### Finding 3: Budget was shifted from high-value to low-value campaigns
- Budget for the other campaigns fell from 20bn to 14.5bn (brand search 7.0 → 4.2bn; retargeting 4.0 → 3.2bn).
- The existing-customer campaigns (`Search_Brand_Loan`, `FB_Retargeting_Existing`, `Partner_Existing_CrossSell`) lost about **717bn** of disbursed value. The three growing campaigns (`TikTok_Personal_Loan`, `FB_LeadGen_New`, `Search_Generic_Loan`) recovered only about **364bn** because their loans are smaller.
- This group's share of disbursed loans fell from **81% to 53%**.

### Finding 4: Other hypotheses were ruled out
- **Credit policy:** policy-rule violations fell from 7.0% to 3.3% of applications, with no sign of tightening. The increase in rejections came from low credit score (8.3% → 15.8%), unverified income (7.0% → 11.3%) and a new reason, duplicate / suspicious applications (5.6%, absent in Q1). These reflect application quality, not stricter thresholds.
- **Operations:** average processing time stayed at **3.0 days** in both quarters, and the mix of non-disbursement reasons barely changed.
- **Top of funnel:** cost per lead was flat (145K → 143K VND), lead-to-application conversion edged up (72.7% → 77.1%), and cost per application fell 7%. Cost deteriorates only from approval onward (cost per approved 364K → 420K; cost per disbursed 418K → 521K, +25%). One warning sign: clicks rose 87% but leads only 27%, so click-to-lead fell from 40.4% to 27.4%, meaning the extra traffic was lower quality.

## 5. Deep Dive by Driver

### 5.1 Approval rate: customer mix, not credit policy
- Applications from customers earning under 20M rose from **35% to 63%** of the total; ages 20–25 from 17% to 31%; average credit score fell from 685 to 634; the two riskiest bands (D, E) rose from 10% to 35%.
- Of the 10.9 percentage-point drop in approval rate, about **7.3 pp is mix effect** and about **3.6 pp is rate effect** (within-group declines, e.g. under 10M: 30% → 24%; 10–20M: 43% → 38%).
- The within-group decline is almost entirely TikTok as well: excluding it, every income group and risk band improves.

### 5.2 Disbursement rate: why approved customers do not take the money
- Approved-but-not-disbursed applications rose from **7,152 to 11,566**. Main reasons (customer side): no response (~31%), offer declined because the limit was too low (~27%), offer declined because of interest rate (~18%).
- **The bank was not stricter.** For applicants who declined over a low limit, the approved limit was ~73–77% of the amount requested in both quarters and across income bands. Limits fell because requests fell: under 10M requested 39M → 30M (−23%) and was approved 30M → 22M (−27%); 10–20M requested 49M → 36M (−27%) and was approved 36M → 27M (−25%).
- Existing customers kept a 90% disbursement rate in both quarters; TikTok reached only **70%**.
- Overall the bank approves about 85% of the requested amount, a feature present since Q1 and across campaigns, so it does not explain the Q2 decline.
- Sensitivity: **each 1 pp of disbursement rate ≈ 25bn VND** of disbursed value.

### 5.3 ADV: a customer-profile shift, not tighter limits
- ADV fell from 50.2M to 42.6M (−15%), yet **within each campaign it was flat or higher** (existing customers 56M → 58M; new customers 25M → 32M). Structure (mix) effect ≈ **−9.8M**; within-campaign effect ≈ **+2.3M**.
- TikTok alone is more than half of the structure effect (average loan only ~18M).
- The age × income matrix shows ADV declines concentrated among young, lower-income customers: ages 20–25 −13.4% (income < 10M) and −11.3% (10–20M); ages 26–35 −15.1% and −13.1%. Customers earning 20M+ and those aged 46+ are roughly flat, and the declining groups are exactly the ones whose share grew most.
- Approved limit was 77–88% of requested amount in every campaign (TikTok Q2: 82%), so the bank did not approve lower amounts. Demand per customer fell: Q2 requested amounts were ~26% lower.

**Causal chain:** younger, lower-income customers → smaller loan requests → proportionally lower approved limits → lower disbursed value.

## 6. Conclusion

The problem is not lead-generation efficiency, the underwriting process, or operations. It is **how the budget was reallocated**: nearly half of Q2 spend moved into one campaign that delivers many applications of low quality, while high-value campaigns were cut. That campaign pulled the customer base toward younger, lower-income, higher-risk applicants, which explains the drop in approval rate (largest effect) and ADV (smaller requests), and contributes to the drop in disbursement rate (TikTok disburses only 70%).

## 7. Recommendations

**1. Fix the TikTok campaign (root cause)**
- Pre-screen at the lead form (income, credit score, duplicate check), or reduce budget until lead quality improves.
- Switch ad optimization from clicks / leads to *approved applications* by sending conversion data back to the ad platform.
- Add duplicate protection at the form and reconcile traffic quality with the ad platform.

**2. Reallocate budget**
- Fix or stop campaigns with low disbursed value per VND spent: TikTok returns ~13x and `Partner_New_Affiliate` ~20x, versus **170–177x** for existing-customer campaigns.
- Cap budgets for new campaigns and scale only after hitting approval-rate and cost-per-disbursement thresholds for 2–4 consecutive weeks. TikTok received 42% of budget in its first quarter with no history.
- Evaluate campaigns on cost and value per disbursed loan, not on application count.
- Consider restoring budget to the high-value existing-customer campaigns.

**3. Disbursement**
- Re-contact non-responsive customers within 24–48 hours by message or call.
- Review limits versus requested amounts; test tiered limit offers.
- Test interest-rate incentives for low-risk customers.
- Simplify the e-contract signing step and add automated reminders.

## 8. Power BI Report Structure

| Page | Content |
|---|---|
| Executive Summary | Business problem, insights, recommendations |
| Story | Full narrative from hypothesis to root cause |
| Dashboard | KPI cards, driver waterfall, applications and conversion by channel, spend by channel, funnel |
| Analysis | Approval rate (mix vs rate effect), disbursement leakage, ticket-size trajectory, ads vs. landing |

## 9. Repository Structure

```
├── README.md
├── fintech_analysis.sql                    # grain checks, joins, Q1 vs Q2 baseline metrics
├── Disbursement_Analysis_PowerBI_EN.pbix   # Power BI report (English, DAX measures)
├── Disbursement_Analysis_PowerBI_EN.pdf    # exported report (English)
└── Disbursement_Analysis_PowerBI_VN.pdf    # exported report (Vietnamese)
```

> **Note:** the dataset is not included in this repository. The SQL file documents the schema (`case1_finance`) and the queries used, and the Power BI file contains the report and DAX measures.
