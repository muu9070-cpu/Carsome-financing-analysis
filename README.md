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

## 5. Business Priorities & Recommended Actions

The analysis highlights six areas where clearer monitoring and targeted follow-up can support financing operations. The actions below are proposed operating practices based on the available data.

### Priority 1 — Clear the Disbursement Backlog

**Signal:** 330 of 1,149 submitted cases (28.72%) had no disbursement receipt recorded in the analysed snapshot.

**Action**
- Maintain a single queue of submitted-but-not-received cases.
- Show order reference, financier, submission date, days outstanding, latest status, and follow-up owner.
- Review unresolved cases with the relevant operational team before assigning a delay reason.

**Track:** Open cases · Ageing by bucket · Cases resolved since last review

### Priority 2 — Escalate Older and Untraceable Cases

**Signal:** The waiting-time view segments eligible cases into 0–7, 8–14, 15–30, and over-30-day buckets. Cases without a usable submission date are identified separately.

**Action**
- Review the oldest cases first, using the ageing buckets as an escalation guide.
- Route records with missing submission dates to a separate data-completion queue.
- Record the latest follow-up outcome to prevent repeated investigation.

**Track:** Cases by ageing bucket · Cases over 30 days · Missing submission dates

### Priority 3 — Standardise Financier and Store Reviews

**Signal:** The dashboard compares recorded volumes and outcomes by financier and store. Assignment can be stage-dependent, and low-volume segments may produce unstable rates.

**Action**
- Use a consistent scorecard for financier and store reviews.
- Show case volume beside conversion and outcome rates; always display the denominator.
- Flag small samples and missing financier assignments rather than ranking them as if they were directly comparable.

**Track:** Case volume · Stage conversion · Submitted-not-received count/rate · Missing assignments

### Priority 4 — Monitor Loan Reductions

**Signal:** Confirmed loan-slash records include loan amount, slash amount, individual slash ratio, and weighted slash-to-loan ratio.

**Action**
- Review total slash amount alongside both ratio measures.
- Drill into larger reductions and recurring patterns by financier or loan type.
- Validate individual cases before attributing a reduction to a specific cause.

**Track:** Confirmed slash cases · Total slash amount · Average individual slash ratio · Weighted slash-to-loan ratio

### Priority 5 — Focus Cancellation Reviews Where They Matter

**Signal:** Cancellation patterns are compared across financing/non-financing orders and stores. The dashboard applies P1, P2, P3, and Low Group Volume — Monitor investigation categories.

**Action**
- Use the priority categories to organise store-level case reviews.
- Validate cancellation reasons from case-level evidence before recommending process changes.
- Treat low-volume groups cautiously; do not over-interpret percentage gaps from small samples.

**Track:** Overall cancellation rate · Segment rates · Gap in percentage points · Cases reviewed with verified reasons

### Priority 6 — Reconcile Funding and Order Completion Separately

**Signal:** The cohort contains 538 completed-only orders, 410 received-only orders, and 409 orders with both flags.

**Action**
- Keep disbursement receipt and order completion as separate operational measures.
- Review received-only and completed-only records as reconciliation exceptions.
- Confirm whether each difference reflects an expected process sequence, a timing issue, or a data-quality gap.

**Track:** Received-only · Completed-only · Both-status cases · Outstanding reconciliation exceptions

### Operating Review Rhythm

| Review cycle | Focus |
|---|---|
| Daily | Pending disbursement queue, ageing exceptions, missing submission dates |
| Weekly | Financier/store scorecard, unresolved cases, data completeness |
| Monthly | Funnel performance, loan-slash trends, cancellation priorities, investigation outcomes |

*These are proposed monitoring practices. Final ownership, escalation thresholds, and review frequency should be aligned with the operating team's processes and system update cadence.*

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
