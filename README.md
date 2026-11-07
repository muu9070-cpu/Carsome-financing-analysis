# CARSOME Financing Analysis

### From Operational Data to Business Insights

**SQL · Python · Pandas · MySQL · Streamlit · Plotly**

> An independent business analytics portfolio project examining
> vehicle-financing operations through an order-created cohort from
> September 2026. The project demonstrates data validation, funnel
> analysis, operational diagnostics, and interactive dashboard
> development. It is not an official CARSOME publication.

[**View Live Dashboard**](https://carsome-financing-analysis.streamlit.app/) · [**View
GitHub
Repository**](https://github.com/muu9070-cpu/Carsome-financing-analysis)

------------------------------------------------------------------------

## Executive Summary

Vehicle financing is a multi-stage process. An order may be identified
as a financing case, proceed through approval and customer acceptance,
reach disbursement submission, receive disbursement, and eventually be
completed. These milestones describe different events and should be
monitored separately.

This project analyses **2,747 unique orders created during September
2026** to understand financing participation, stage progression,
disbursement visibility, financier/store patterns, loan reductions, and
cancellation trends.

The analysis combines SQL-based validation and aggregation, Python data
preparation, and a six-page Streamlit dashboard. Its purpose is to turn
operational records into clear performance measures, identify cases and
segments that merit further investigation, and translate observed
patterns into practical follow-up recommendations.

### Selected cohort indicators

  Indicator                                      Result
  ---------------------------------------- ------------
  Total unique orders                         **2,747**
  Financing cases                             **2,062**
  Financing share of orders                  **75.06%**
  Approved financing cases                    **1,500**
  Financing-to-approval rate                 **72.74%**
  Accepted cases                              **1,334**
  Disbursement submitted                      **1,149**
  Disbursement received                         **819**
  Submitted-to-received rate                 **71.28%**
  Submitted but not recorded as received        **330**
  Submitted-not-received share               **28.72%**
  Completed orders                              **947**

**Initial business signal:** 330 submitted cases had no recorded
disbursement receipt in the analysed snapshot. This is a follow-up
population to investigate, not proof that all cases were delayed or
attributable to a financier.

------------------------------------------------------------------------

## 1. Business Context

The project focuses on the operational visibility of a vehicle-financing
workflow. A typical order may pass through several milestones:

1.  Order created
2.  Financing case identified
3.  Financing approved
4.  Customer accepts the financing offer
5.  Disbursement submitted
6.  Disbursement received
7.  Order completed

Each milestone answers a different operational question. For example,
approval does not necessarily mean that a customer has accepted the
offer; disbursement submission does not confirm that funds have been
received; and disbursement receipt is not equivalent to order
completion.

A stage-based view makes it possible to track the flow of cases without
collapsing distinct business events into one status.

## 2. Business Problems & Analytical Questions

The analysis is organised around six operational questions.

  ------------------------------------------------------------------------
  Business area           Problem to investigate  Analytical question
  ----------------------- ----------------------- ------------------------
  Financing conversion    Cases may not progress  How many cases reach
                          consistently through    each milestone, and
                          each stage              where are the largest
                                                  count differences?

  Disbursement tracking   Submitted cases may     How large is the
                          have no receipt         submitted-not-received
                          recorded in the         population?
                          available snapshot      

  Financier and store     Outcomes may vary       How do volumes and
  performance             across business         recorded stage outcomes
                          segments                differ by financier and
                                                  store?

  Waiting time            Some outstanding cases  How long have eligible
                          may have been waiting   submitted-not-received
                          longer than others      cases been waiting?

  Loan slash              Confirmed loan          What are the loan
                          reductions may vary in  amounts, slash amounts,
                          size and distribution   and slash ratios in the
                                                  confirmed cases?

  Cancellation            Cancellation patterns   Which stores or segments
                          may differ between      merit closer
                          financing and           investigation?
                          non-financing orders or 
                          across stores           
  ------------------------------------------------------------------------

These are descriptive and diagnostic questions. Differences between
groups are treated as signals for investigation, not as proof of root
cause or individual performance.

## 3. Analytical Methodology

### 3.1 Data quality and validation

-   Validate cohort date boundaries and distinct order counts.
-   Review key fields, missing values, stage indicators, and data
    completeness.
-   Reconcile aggregate counts against order-level records.
-   Keep different operational milestones separate.
-   Retain missing or blank financier assignments for audit where
    relevant.

### 3.2 Order-level cohort and KPI construction

The primary cohort is defined by **order creation date**, from 1
September 2026 inclusive to 1 October 2026 exclusive. The unit of
analysis for the main funnel KPIs is the unique order.

Later approval, acceptance, disbursement, or completion events may occur
after September. Therefore, this is an order-created cohort analysis,
not a claim that every downstream event happened within September.

### 3.3 Funnel and conversion analysis

Counts and conversion rates are calculated across financing stages. Each
rate must be interpreted using its stated denominator. Stage counts are
not assumed to be mutually exclusive unless the underlying business
definition supports that interpretation.

### 3.4 Segmentation analysis

Financing volumes and recorded outcomes are compared across financiers
and stores. Financier assignment can be stage-dependent; comparisons
grouped by a final recorded financier should not automatically be
interpreted as independent early-stage bank approval performance.

### 3.5 Operational diagnostics

-   **Waiting time:** classify eligible outstanding submitted cases into
    0--7, 8--14, 15--30, and over-30-day buckets.
-   **Loan slash:** examine confirmed slash cases, loan and slash
    amounts, individual ratios, and the weighted ratio.
-   **Cancellation:** compare cancellation patterns across
    financing/non-financing segments and stores, including
    percentage-point gaps and rule-based investigation priorities.

### 3.6 Dashboard delivery

SQL prepares the analytical result sets, Python/Pandas loads and
validates the exported datasets, and Streamlit/Plotly presents the
results in an interactive multi-page dashboard.

------------------------------------------------------------------------

## 4. Key Findings

### 4.1 Financing participation and progression

Out of 2,747 unique orders, 2,062 were identified as financing cases,
representing **75.06%** of the cohort. Of those financing cases, 1,500
were approved, giving a financing-to-approval rate of **72.74%** using
financing cases as the denominator.

The difference between financing cases and approved cases is **562**.
This is the largest absolute count difference highlighted in the main
stage sequence. It identifies a population for further breakdown; the
count difference alone does not explain whether cases were rejected,
withdrawn, incomplete, or affected by another process outcome.

### 4.2 Submitted-to-received disbursement gap

There were 1,149 submitted cases and 819 cases with a recorded
disbursement receipt. The submitted-to-received rate was **71.28%**. A
further **330 cases (28.72%)** had a submission record but no receipt
recorded in the analysed snapshot.

**Business interpretation:** the 330 cases form a practical follow-up
queue. The next step is to inspect case-level status, submission-date
completeness, elapsed waiting time, and the latest available operational
notes before assigning a reason or owner.

### 4.3 Disbursement receipt and order completion are different events

The order-level reconciliation identified:

  Recorded status combination                             Orders
  ----------------------------------------------------- --------
  Completed, without recorded disbursement receipt           538
  Disbursement received, without completed-order flag        410
  Both disbursement received and completed                   409

These combinations reconcile to **947 completed orders** and **819
received cases**. The result demonstrates why disbursement receipt and
order completion must be reported as separate milestones rather than
treated as interchangeable statuses.

### 4.4 Financier, waiting-time, loan-slash, and cancellation diagnostics

The dashboard includes financier/store comparisons, waiting-time
distributions, confirmed loan-slash analysis, and cancellation
investigation priorities. These views are designed to expose patterns
and support drill-down.

The README does not assign a single bank, branch, store, or cancellation
reason as the cause of an observed difference. Specific segment-level
conclusions should be made only after reviewing the corresponding
detailed dashboard results and validating sample sizes, data
completeness, and business definitions.

------------------------------------------------------------------------

## 5. Business Insights & Recommendations

The findings above point to several opportunities to improve operational visibility and prioritise follow-up. The recommendations below are proposed actions for validation; they do not imply that the underlying causes have already been confirmed.

### 5.1 Pending Disbursement Follow-up

**Evidence from the analysis**

- 330 submitted cases had no disbursement receipt recorded in the analysed snapshot.
- This represents 28.72% of the 1,149 submitted cases.

**Business insight**

A sizeable group of submitted cases requires status clarification. The count alone does not establish whether a case is delayed, awaiting documentation, not yet updated in the system, or affected by another issue.

**Recommended action**

Create a pending-disbursement worklist containing the order reference, financier, submission date, elapsed waiting days, latest available status, and follow-up owner. Review the cases with the relevant operational team before assigning a reason.

**Suggested monitoring measures**

- Number of open submitted-not-received cases
- Number and share of cases in each waiting-time bucket
- Number of cases resolved since the previous review

### 5.2 Waiting-Time Escalation

**Evidence from the analysis**

The waiting-time analysis groups eligible outstanding cases into four ageing buckets: 0–7 days, 8–14 days, 15–30 days, and over 30 days. Cases without a usable submission date are identified separately.

**Business insight**

The total number of pending cases does not show which cases have been waiting longest. Missing submission dates also limit the ability to calculate elapsed waiting time.

**Recommended action**

Introduce an ageing-based review process. Prioritise older cases for investigation and route cases with missing submission dates to a separate data-completion check.

**Suggested monitoring measures**

- Case count and share in each ageing bucket
- Number of cases waiting over 30 days
- Number of cases missing a submission date

### 5.3 Financier and Store Performance Monitoring

**Evidence from the analysis**

The dashboard compares recorded financing volumes and stage outcomes across financiers and stores. Financier assignment may be stage-dependent, and some segments may have relatively small case volumes.

**Business insight**

A percentage difference should not be interpreted in isolation. Comparisons need consistent stage definitions, denominators, and sufficient sample sizes. A final recorded financier may not represent the financier involved at every earlier stage.

**Recommended action**

Establish a recurring financier/store scorecard. Display case volume alongside stage conversion, disbursement outcomes, and data-completeness indicators. Flag small-volume segments so that unstable percentages are not over-interpreted.

**Suggested monitoring measures**

- Case volume by financier and store
- Stage conversion rates with clearly stated denominators
- Submitted-not-received case count and rate
- Missing or unassigned financier records

### 5.4 Loan Slash Monitoring

**Evidence from the analysis**

The loan-slash analysis examines confirmed slash cases, loan amounts, slash amounts, individual slash ratios, and the weighted slash-to-loan ratio.

**Business insight**

Absolute reduction amounts and relative reduction ratios provide different perspectives. The average of individual case ratios is not interchangeable with the ratio of total slash amount to total loan amount.

**Recommended action**

Monitor both the amount and ratio measures. Review larger reductions and recurring patterns by financier or loan type, then validate the relevant case details before drawing conclusions about the reasons for the reductions.

**Suggested monitoring measures**

- Number of confirmed loan-slash cases
- Total and average slash amount
- Average individual slash ratio
- Weighted slash-to-loan ratio

### 5.5 Cancellation Investigation Prioritisation

**Evidence from the analysis**

The cancellation analysis compares overall, financing, and non-financing cancellation patterns and applies rule-based store investigation priorities: P1, P2, P3, and Low Group Volume — Monitor.

**Business insight**

A store-level cancellation gap can help identify where investigation may be useful, but it does not reveal the underlying reason for cancellation. Small group volumes also require careful interpretation.

**Recommended action**

Use the P1/P2/P3 and low-volume monitoring classifications to organise case reviews. For each priority store, inspect case-level cancellation evidence and record verified reasons before proposing process changes.

**Suggested monitoring measures**

- Overall cancellation rate
- Financing and non-financing cancellation rates
- Cancellation-rate gap in percentage points
- Number of cases reviewed and share with verified reasons

### 5.6 Separate Disbursement and Completion Controls

**Evidence from the analysis**

The order-level reconciliation identified three status combinations:

- **538 orders:** completed, without a recorded disbursement receipt
- **410 orders:** disbursement received, without a completed-order flag
- **409 orders:** both disbursement received and completed

**Business insight**

Disbursement receipt and order completion represent different operational milestones. One status cannot fully represent both funding progress and sales completion.

**Recommended action**

Maintain separate definitions and monitoring for disbursement receipt and order completion. Add a reconciliation view to surface records with only one of the two status flags, so that operational teams can confirm whether the difference is expected or requires data follow-up.

**Suggested monitoring measures**

- Received-only cases
- Completed-only cases
- Cases with both status flags
- Unreconciled cases over time

### Suggested Operational Review Cadence

- **Daily / operational follow-up:** review the pending-disbursement worklist, older waiting cases, and missing submission dates.
- **Weekly:** review financier/store scorecards, data completeness, and unresolved exceptions.
- **Monthly:** review funnel conversion, loan-slash patterns, cancellation segments, and investigation outcomes.

This cadence is a proposed operating model. It should be adapted to actual team responsibilities, system update frequency, and available operational resources.

---

## 6. Interactive Dashboard

The deployed Streamlit application contains six analytical pages:

  -----------------------------------------------------------------------
  Dashboard page                      What it answers
  ----------------------------------- -----------------------------------
  **1. Executive Overview**           What is the overall order and
                                      financing picture for the cohort?

  **2. Financing Funnel**             How do cases progress through
                                      financing and disbursement
                                      milestones?

  **3. Financier Performance**        How do recorded volumes and
                                      outcomes differ by financier and
                                      store?

  **4. Waiting Time Analysis**        Which submitted-not-received cases
                                      are older, and how is waiting time
                                      distributed?

  **5. Loan Slash Analysis**          What is the scale and distribution
                                      of confirmed loan reductions?

  **6. Cancellation Recommendations** Which store/segment patterns should
                                      be prioritised for investigation?
  -----------------------------------------------------------------------

> Add the public Streamlit URL to the **View Live Dashboard** link at
> the top of this README once the final app URL has been copied from
> Streamlit Community Cloud.

------------------------------------------------------------------------

## 7. Technical Architecture

![CARSOME Financing Analysis Portfolio
Architecture](carsome_portfolio_overview.png)

### End-to-end workflow

``` text
Source / order-level data
        |
        v
SQL validation and business analysis
        |
        v
SQL result sets and dashboard datasets
        |
        v
CSV analytical extracts
        |
        v
Centralised Python data loader
        |
        v
Six-page Streamlit + Plotly dashboard
        |
        v
Business findings and operational recommendations
```

### Technology stack

  -----------------------------------------------------------------------
  Layer                   Tools                   Role
  ----------------------- ----------------------- -----------------------
  Data querying           SQL / MySQL             Validation, joins,
                                                  aggregation, business
                                                  rules, analytical views

  Data preparation        Python / Pandas         Data loading, type
                                                  conversion, field
                                                  normalisation

  Exploratory work        Jupyter Notebook        Data quality, feature
                                                  preparation, KPI
                                                  exploration

  Visualisation           Streamlit / Plotly      Interactive dashboards
                                                  and business views

  Version control         Git / GitHub            Project organisation
                                                  and portfolio
                                                  publication
  -----------------------------------------------------------------------

## 8. SQL Analysis and Data Assets

The `database/` directory contains the SQL analysis workflow:

  ----------------------------------------------------------------------------------
  SQL file                                       Purpose
  ---------------------------------------------- -----------------------------------
  `01_data_validation.sql`                       Validate source data and key fields

  `02_business_overview.sql`                     Establish the overall business view

  `03_cancellation_analysis.sql`                 Analyse cancellation patterns and
                                                 investigation priorities

  `04_financing_funnel.sql`                      Build financing-stage and
                                                 conversion analysis

  `04_financing_performance.sql`                 Analyse financing performance

  `05_bank_branch_performance.sql`               Analyse financier and store-level
                                                 performance

  `06_loan_amount_analysis.sql`                  Analyse loan amounts and loan slash

  `07_Business_Insights & Recommendations.sql`   Consolidate business insights and
                                                 recommendations

  `08_Dashboard_Dataset_Preparation.sql`         Prepare datasets for dashboard
                                                 consumption

  `dashboard_views.sql`                          Define dashboard-oriented SQL views
  ----------------------------------------------------------------------------------

Nine analytical CSV extracts are stored under `data/processed/`:

-   `CARSOME_Financing_Dashboard.csv`
-   `financier_overall_performance.csv`
-   `financier_store_performance.csv`
-   `financier_stage_conversion.csv`
-   `financier_assignment_audit.csv`
-   `financier_disbursement_conversion.csv`
-   `CARSOME_Waiting_Time_Analysis.csv`
-   `CARSOME_Loan_Slash_Analysis.csv`
-   `CARSOME_Cancellation_Recommendations.csv`

All dashboard pages use the centralised `utils/data_loader.py` module to
read and validate the datasets.

## 9. Jupyter Notebooks

The `notebooks/` directory contains:

-   `Data quality layer.ipynb`
-   `Feature layer.ipynb`
-   `Feature or KPI Layer.ipynb`

These notebooks preserve exploratory and preparation work that supports
the SQL datasets and dashboard calculations.

## 10. Repository Structure

``` text
Carsome-financing-analysis/
├── app.py
├── README.md
├── requirements.txt
├── carsome_portfolio_overview.png
├── data/
│   └── processed/
│       ├── CARSOME_Financing_Dashboard.csv
│       ├── CARSOME_Waiting_Time_Analysis.csv
│       ├── CARSOME_Loan_Slash_Analysis.csv
│       ├── CARSOME_Cancellation_Recommendations.csv
│       └── financier_*.csv
├── database/
│   ├── 01_data_validation.sql
│   ├── 02_business_overview.sql
│   ├── 03_cancellation_analysis.sql
│   ├── 04_financing_funnel.sql
│   ├── 04_financing_performance.sql
│   ├── 05_bank_branch_performance.sql
│   ├── 06_loan_amount_analysis.sql
│   ├── 07_Business_Insights & Recommendations.sql
│   ├── 08_Dashboard_Dataset_Preparation.sql
│   └── dashboard_views.sql
├── notebooks/
│   ├── Data quality layer.ipynb
│   ├── Feature layer.ipynb
│   └── Feature or KPI Layer.ipynb
├── pages/
│   ├── 1_Executive_Overview.py
│   ├── 2_Financing_Funnel.py
│   ├── 3_Financier_Performance.py
│   ├── 4_Waiting_Time_Analysis.py
│   ├── 5_Loan_Slash_Analysis.py
│   └── 6_Cancellation_Recommendations.py
└── utils/
    ├── __init__.py
    └── data_loader.py
```

## 11. Run Locally

### Requirements

Python and the packages listed in `requirements.txt`.

### Setup

``` bash
git clone https://github.com/muu9070-cpu/Carsome-financing-analysis.git
cd Carsome-financing-analysis

python -m venv .venv
```

Activate the environment:

**Windows PowerShell**

``` powershell
.venv\Scripts\Activate.ps1
```

**macOS / Linux**

``` bash
source .venv/bin/activate
```

Install dependencies and launch the app:

``` bash
pip install -r requirements.txt
streamlit run app.py
```

The nine CSV extracts must be present in `data/processed/` with the
expected file names and columns.

------------------------------------------------------------------------

## 12. Scope, Limitations & Data Responsibility

-   **Cohort period:** Main cohort is based on order creation from 1--30
    September 2026. Later-stage events may occur after the cohort month.
-   **Waiting-time snapshot:** Waiting-time measures depend on the
    snapshot date used in the corresponding analysis script. They are
    not a live operational feed.
-   **Distinct milestones:** Disbursement received and order completed
    are different business events.
-   **Denominators:** Conversion rates must be interpreted with their
    stated base population; stage counts should not be compared as if
    every stage had an identical eligible population.
-   **Financier attribution:** Assignment may be stage-dependent.
    Descriptive differences do not establish that a financier caused an
    outcome.
-   **Missing information:** Missing dates and financier values may
    affect which cases can be included in a given calculation.
-   **Causality:** The project is descriptive and diagnostic. It does
    not prove why an order was cancelled, why a loan was reduced, or why
    disbursement was not recorded as received.
-   **Data snapshot:** Findings describe the available extract and
    analysis snapshot, not current live company operations.

This is an independent portfolio case study and is not an official
CARSOME product or an endorsement by CARSOME. Public repository contents
must be authorised for disclosure and appropriately anonymised or
synthetic. Do not publish customer-identifiable information,
confidential company information, credentials, private database
connection details, or internal-only URLs.

------------------------------------------------------------------------

**Built with SQL, Python, Pandas, Streamlit and Plotly.**
