
USE carsome_orders_analysis;

-- 1. Check source table structure
DESCRIBE stg_orders;


-- 2. Check source data volume and order uniqueness
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows,
    COUNT(order_id) AS non_null_order_ids
FROM stg_orders;


-- 3. Check key business flags
SELECT
    COUNT(*) AS total_orders,

    SUM(COALESCE(financing_case_flag, 0))
        AS financing_cases,

    SUM(COALESCE(approved_flag, 0))
        AS approved_cases,

    SUM(COALESCE(accepted_flag, 0))
        AS accepted_cases,

    SUM(COALESCE(disbursement_submitted_flag, 0))
        AS submitted_cases,

    SUM(COALESCE(disbursement_received_flag, 0))
        AS received_cases,

    SUM(COALESCE(completed_flag, 0))
        AS completed_cases

FROM stg_orders;



-- ============================================================
-- CARSOME FINANCING ANALYSIS
-- DASHBOARD DATA PREPARATION
-- 01. BASE DATA VIEW
-- ============================================================

USE carsome_orders_analysis;


-- ------------------------------------------------------------
-- 1. Create Base Dashboard View
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_dashboard_base AS

SELECT

    -- --------------------------------------------------------
    -- A. Order Identification
    -- --------------------------------------------------------

    order_id,
    summarised_order_id,
    new_order,

    -- --------------------------------------------------------
    -- B. Order Information
    -- --------------------------------------------------------

    created_time,
    store,
    order_status,
    payment_method,
    order_price,

    -- --------------------------------------------------------
    -- C. Vehicle Information
    -- --------------------------------------------------------

    car_id,
    car_type,
    car,

    -- --------------------------------------------------------
    -- D. Financing Information
    -- --------------------------------------------------------

    final_loan_status,
    final_loan_type,
    final_financier,

    loan_acceptance_date,
    loan_amount,
    loan_tenure,
    loan_status_date,

    loan_profit,
    fis___loan,

    -- --------------------------------------------------------
    -- E. Financing Submission Dates
    -- --------------------------------------------------------

    loan_submission_date1,
    loan_submission_date2,
    loan_submission_date3,
    loan_submission_date4,
    loan_submission_date5,

    -- --------------------------------------------------------
    -- F. Disbursement Information
    -- --------------------------------------------------------

    disbursement_status,
    disbursement_submit_date,
    disbursement_slip_date,
    disbursement_receive_date,

    -- --------------------------------------------------------
    -- G. Financing Process Flags
    -- NULL flags are treated as 0 in this view only
    -- --------------------------------------------------------

    COALESCE(financing_case_flag, 0)
        AS financing_case_flag,

    COALESCE(resubmission_flag, 0)
        AS resubmission_flag,

    COALESCE(approved_flag, 0)
        AS approved_flag,

    COALESCE(accepted_flag, 0)
        AS accepted_flag,

    COALESCE(disbursement_submitted_flag, 0)
        AS disbursement_submitted_flag,

    COALESCE(disbursement_received_flag, 0)
        AS disbursement_received_flag,

    COALESCE(completed_flag, 0)
        AS completed_flag,

    -- --------------------------------------------------------
    -- H. Existing Process Gap Flags
    -- --------------------------------------------------------

    COALESCE(approved_not_accepted_flag, 0)
        AS approved_not_accepted_flag,

    COALESCE(accepted_not_disb_submitted_flag, 0)
        AS accepted_not_disb_submitted_flag,

    COALESCE(submitted_not_received_flag, 0)
        AS submitted_not_received_flag,

    COALESCE(received_not_completed_flag, 0)
        AS received_not_completed_flag,

    -- --------------------------------------------------------
    -- I. Turnaround Time
    -- --------------------------------------------------------

    acceptance_tat_days,
    acceptance_tat_clean,

    disbursement_tat_days,
    disbursement_tat_clean,

    -- --------------------------------------------------------
    -- J. Remarks
    -- Internal analytical field
    -- Do not expose raw remarks in public dashboard
    -- --------------------------------------------------------

    final_status_remark

FROM stg_orders;


-- ============================================================
-- 2. VALIDATION
-- Compare Base View with Original Source Table
-- ============================================================

SELECT

    'stg_orders' AS source_name,

    COUNT(*) AS total_rows,

    COUNT(DISTINCT order_id) AS unique_orders,

    SUM(COALESCE(financing_case_flag, 0))
        AS financing_cases,

    SUM(COALESCE(approved_flag, 0))
        AS approved_cases,

    SUM(COALESCE(accepted_flag, 0))
        AS accepted_cases,

    SUM(COALESCE(disbursement_submitted_flag, 0))
        AS submitted_cases,

    SUM(COALESCE(disbursement_received_flag, 0))
        AS received_cases,

    SUM(COALESCE(completed_flag, 0))
        AS completed_cases

FROM stg_orders

UNION ALL

SELECT

    'vw_dashboard_base' AS source_name,

    COUNT(*) AS total_rows,

    COUNT(DISTINCT order_id) AS unique_orders,

    SUM(financing_case_flag)
        AS financing_cases,

    SUM(approved_flag)
        AS approved_cases,

    SUM(accepted_flag)
        AS accepted_cases,

    SUM(disbursement_submitted_flag)
        AS submitted_cases,

    SUM(disbursement_received_flag)
        AS received_cases,

    SUM(completed_flag)
        AS completed_cases

FROM vw_dashboard_base;


-- ============================================================
-- 3. CHECK VIEW STRUCTURE
-- ============================================================

DESCRIBE vw_dashboard_base;


-- ============================================================
-- 4. CHECK DUPLICATE ORDER IDS
-- ============================================================

SELECT

    COUNT(*) AS total_rows,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_rows,

    COUNT(order_id) AS non_null_order_ids

FROM vw_dashboard_base;


-- ============================================================
-- 5. CHECK NULL FLAGS IN SOURCE VS BASE VIEW
-- ============================================================

SELECT

    COUNT(*) AS total_rows,

    SUM(
        CASE WHEN financing_case_flag IS NULL
        THEN 1 ELSE 0 END
    ) AS null_financing_flags,

    SUM(
        CASE WHEN approved_flag IS NULL
        THEN 1 ELSE 0 END
    ) AS null_approved_flags,

    SUM(
        CASE WHEN accepted_flag IS NULL
        THEN 1 ELSE 0 END
    ) AS null_accepted_flags,

    SUM(
        CASE WHEN disbursement_submitted_flag IS NULL
        THEN 1 ELSE 0 END
    ) AS null_submitted_flags,

    SUM(
        CASE WHEN disbursement_received_flag IS NULL
        THEN 1 ELSE 0 END
    ) AS null_received_flags,

    SUM(
        CASE WHEN completed_flag IS NULL
        THEN 1 ELSE 0 END
    ) AS null_completed_flags

FROM vw_dashboard_base;



USE carsome_orders_analysis;

-- ============================================================
-- CHECK 1: Compare source table row counts
-- ============================================================

SELECT
    'stg_orders' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM stg_orders

UNION ALL

SELECT
    'stg_orders_v2',
    COUNT(*),
    COUNT(DISTINCT order_id)
FROM stg_orders_v2;


-- ============================================================
-- CHECK 2: Compare key financing metrics
-- ============================================================

SELECT
    'stg_orders' AS source_name,

    COUNT(*) AS total_orders,

    SUM(COALESCE(financing_case_flag, 0))
        AS financing_cases,

    SUM(COALESCE(approved_flag, 0))
        AS approved_cases,

    SUM(COALESCE(accepted_flag, 0))
        AS accepted_cases,

    SUM(COALESCE(disbursement_submitted_flag, 0))
        AS submitted_cases,

    SUM(COALESCE(disbursement_received_flag, 0))
        AS received_cases,

    SUM(COALESCE(completed_flag, 0))
        AS completed_cases

FROM stg_orders

UNION ALL

SELECT
    'stg_orders_v2',

    COUNT(*),

    SUM(COALESCE(financing_case_flag, 0)),

    SUM(COALESCE(approved_flag, 0)),

    SUM(COALESCE(accepted_flag, 0)),

    SUM(COALESCE(disbursement_submitted_flag, 0)),

    SUM(COALESCE(disbursement_received_flag, 0)),

    SUM(COALESCE(completed_flag, 0))

FROM stg_orders_v2;


-- ============================================================
-- CHECK 3: Compare order ID matching
-- ============================================================

SELECT
    COUNT(*) AS matched_order_ids
FROM stg_orders s
INNER JOIN stg_orders_v2 v
    ON s.order_id = v.order_id;


SELECT
    COUNT(*) AS only_in_stg_orders
FROM stg_orders s
LEFT JOIN stg_orders_v2 v
    ON s.order_id = v.order_id
WHERE v.order_id IS NULL;


SELECT
    COUNT(*) AS only_in_stg_orders_v2
FROM stg_orders_v2 v
LEFT JOIN stg_orders s
    ON v.order_id = s.order_id
WHERE s.order_id IS NULL;




USE carsome_orders_analysis;

-- Compare columns between two source tables

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'carsome_orders_analysis'
  AND TABLE_NAME IN (
      'stg_orders',
      'stg_orders_v2'
  )
ORDER BY
    COLUMN_NAME,
    TABLE_NAME;


-- Check whether key financing flags exist

SELECT
    column_name,

    MAX(
        CASE
            WHEN table_name = 'stg_orders'
            THEN 'YES'
            ELSE 'NO'
        END
    ) AS exists_in_stg_orders,

    MAX(
        CASE
            WHEN table_name = 'stg_orders_v2'
            THEN 'YES'
            ELSE 'NO'
        END
    ) AS exists_in_stg_orders_v2

FROM INFORMATION_SCHEMA.COLUMNS

WHERE TABLE_SCHEMA = 'carsome_orders_analysis'
  AND TABLE_NAME IN (
      'stg_orders',
      'stg_orders_v2'
  )
  AND COLUMN_NAME IN (
      'financing_case_flag',
      'approved_flag',
      'accepted_flag',
      'disbursement_submitted_flag',
      'disbursement_received_flag',
      'completed_flag',
      'approved_not_accepted_flag',
      'accepted_not_disb_submitted_flag',
      'submitted_not_received_flag',
      'received_not_completed_flag'
  )

GROUP BY COLUMN_NAME
ORDER BY COLUMN_NAME;




USE carsome_orders_analysis;

-- 1. Orders in stg_orders but not in stg_orders_v2

SELECT
    COUNT(*) AS only_in_stg_orders
FROM stg_orders s
LEFT JOIN stg_orders_v2 v
    ON s.order_id = v.order_id
WHERE v.order_id IS NULL;


-- 2. Orders in stg_orders_v2 but not in stg_orders

SELECT
    COUNT(*) AS only_in_stg_orders_v2
FROM stg_orders_v2 v
LEFT JOIN stg_orders s
    ON v.order_id = s.order_id
WHERE s.order_id IS NULL;


-- 3. Compare common financing flags

SELECT

    SUM(
        CASE WHEN s.financing_case_flag
            <> v.financing_case_flag
        THEN 1 ELSE 0 END
    ) AS financing_flag_mismatch,

    SUM(
        CASE WHEN s.accepted_flag
            <> v.accepted_flag
        THEN 1 ELSE 0 END
    ) AS accepted_flag_mismatch,

    SUM(
        CASE WHEN s.completed_flag
            <> v.completed_flag
        THEN 1 ELSE 0 END
    ) AS completed_flag_mismatch,

    SUM(
        CASE WHEN s.disbursement_submitted_flag
            <> v.disbursement_submitted_flag
        THEN 1 ELSE 0 END
    ) AS submitted_flag_mismatch,

    SUM(
        CASE WHEN s.disbursement_received_flag
            <> v.disbursement_received_flag
        THEN 1 ELSE 0 END
    ) AS received_flag_mismatch

FROM stg_orders s

INNER JOIN stg_orders_v2 v
    ON s.order_id = v.order_id;



USE carsome_orders_analysis;

-- ============================================================
-- 1. Order Status Distribution
-- ============================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    SUM(completed_flag) AS completed_orders,
    SUM(financing_case_flag) AS financing_cases
FROM vw_dashboard_base
GROUP BY order_status
ORDER BY total_orders DESC;


-- ============================================================
-- 2. Monthly Order Trend
-- ============================================================

SELECT
    DATE_FORMAT(created_time, '%Y-%m') AS order_month,
    COUNT(*) AS total_orders,
    SUM(completed_flag) AS completed_orders,
    SUM(financing_case_flag) AS financing_cases,
    SUM(disbursement_received_flag) AS received_cases
FROM vw_dashboard_base
WHERE created_time IS NOT NULL
GROUP BY DATE_FORMAT(created_time, '%Y-%m')
ORDER BY order_month;


-- ============================================================
-- 3. Store Performance
-- ============================================================

SELECT
    store,
    COUNT(*) AS total_orders,
    SUM(completed_flag) AS completed_orders,
    SUM(financing_case_flag) AS financing_cases,
    SUM(
        CASE
            WHEN LOWER(order_status) LIKE '%cancel%'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders
FROM vw_dashboard_base
GROUP BY store
ORDER BY total_orders DESC;




-- ============================================================
-- 02. EXECUTIVE OVERVIEW VIEWS
-- Data Source: vw_dashboard_base
-- ============================================================

USE carsome_orders_analysis;


-- ------------------------------------------------------------
-- VIEW 1: Executive KPI
-- One row containing overall business metrics
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_executive_kpi AS

SELECT

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'Order Completed'
            THEN 1 ELSE 0
        END
    ) AS completed_orders,

    SUM(
        CASE
            WHEN order_status = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    SUM(
        CASE
            WHEN order_status = 'Order Closed'
            THEN 1 ELSE 0
        END
    ) AS closed_orders,

    SUM(financing_case_flag) AS financing_cases,

    SUM(approved_flag) AS approved_cases,

    SUM(accepted_flag) AS accepted_cases,

    SUM(disbursement_submitted_flag)
        AS submitted_cases,

    SUM(disbursement_received_flag)
        AS received_cases,

    SUM(completed_flag) AS completed_flag_cases,

    ROUND(
        SUM(financing_case_flag) / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS financing_rate_pct,

    ROUND(
        SUM(
            CASE WHEN order_status = 'Order Completed'
            THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS order_completion_rate_pct,

    ROUND(
        SUM(
            CASE WHEN order_status = 'Order Cancelled'
            THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS cancellation_rate_pct,

    ROUND(
        SUM(disbursement_received_flag)
        / NULLIF(SUM(financing_case_flag), 0) * 100,
        2
    ) AS disbursement_received_rate_pct

FROM vw_dashboard_base;


-- ------------------------------------------------------------
-- VIEW 2: Monthly Business Overview
-- One row per order month
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_executive_monthly AS

SELECT

    DATE_FORMAT(created_time, '%Y-%m')
        AS order_month,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'Order Completed'
            THEN 1 ELSE 0
        END
    ) AS completed_orders,

    SUM(
        CASE
            WHEN order_status = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    SUM(financing_case_flag) AS financing_cases,

    SUM(approved_flag) AS approved_cases,

    SUM(accepted_flag) AS accepted_cases,

    SUM(disbursement_received_flag)
        AS received_cases,

    ROUND(
        SUM(financing_case_flag) / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS financing_rate_pct

FROM vw_dashboard_base

WHERE created_time IS NOT NULL

GROUP BY DATE_FORMAT(created_time, '%Y-%m');


-- ------------------------------------------------------------
-- VIEW 3: Order Status Distribution
-- One row per order status
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_executive_order_status AS

SELECT

    order_status,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'Order Completed'
            THEN 1 ELSE 0
        END
    ) AS completed_orders,

    SUM(financing_case_flag) AS financing_cases,

    ROUND(
        COUNT(*) / (
            SELECT COUNT(*)
            FROM vw_dashboard_base
        ) * 100,
        2
    ) AS order_share_pct

FROM vw_dashboard_base

GROUP BY order_status;


-- ------------------------------------------------------------
-- VIEW 4: Store Performance
-- One row per store
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_executive_store AS

SELECT

    store,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN order_status = 'Order Completed'
            THEN 1 ELSE 0
        END
    ) AS completed_orders,

    SUM(
        CASE
            WHEN order_status = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    SUM(financing_case_flag) AS financing_cases,

    SUM(disbursement_received_flag)
        AS received_cases,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Order Completed'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS completion_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN order_status = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS cancellation_rate_pct,

    ROUND(
        SUM(financing_case_flag)
        / NULLIF(COUNT(*), 0) * 100,
        2
    ) AS financing_rate_pct

FROM vw_dashboard_base

GROUP BY store;


-- ============================================================
-- 03. VALIDATION
-- ============================================================

-- KPI
SELECT *
FROM vw_executive_kpi;


-- Monthly
SELECT *
FROM vw_executive_monthly
ORDER BY order_month;


-- Order Status
SELECT *
FROM vw_executive_order_status
ORDER BY total_orders DESC;


-- Store
SELECT *
FROM vw_executive_store
ORDER BY total_orders DESC;


-- Check total store orders
SELECT
    SUM(total_orders) AS store_total_orders,
    SUM(completed_orders) AS store_completed_orders,
    SUM(cancelled_orders) AS store_cancelled_orders
FROM vw_executive_store;






-- ============================================================
-- 03. FINANCING FUNNEL VIEWS
-- Source: vw_dashboard_base
-- Original analysis: 04_financing_funnel.sql
-- ============================================================

USE carsome_orders_analysis;


-- ------------------------------------------------------------
-- VIEW 1: Main Financing Funnel
-- Population: Financing Cases Only
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW vw_financing_funnel AS

WITH funnel_counts AS (

    SELECT

        COUNT(*) AS financing_cases,

        SUM(approved_flag) AS approved_cases,

        SUM(accepted_flag) AS accepted_cases,

        SUM(disbursement_submitted_flag)
            AS submitted_cases,

        SUM(disbursement_received_flag)
            AS received_cases,

        SUM(completed_flag)
            AS completed_cases

    FROM vw_dashboard_base

    WHERE financing_case_flag = 1

),

funnel_stages AS (

    SELECT
        1 AS stage_order,
        'Financing Case' AS funnel_stage,
        financing_cases AS stage_cases,
        CAST(NULL AS DECIMAL(10,2))
            AS conversion_rate_pct,
        CAST(NULL AS SIGNED)
            AS stage_dropoff_cases
    FROM funnel_counts

    UNION ALL

    SELECT
        2,
        'Approved',
        approved_cases,
        ROUND(
            approved_cases * 100.0
            / NULLIF(financing_cases, 0),
            2
        ),
        financing_cases - approved_cases
    FROM funnel_counts

    UNION ALL

    SELECT
        3,
        'Accepted',
        accepted_cases,
        ROUND(
            accepted_cases * 100.0
            / NULLIF(approved_cases, 0),
            2
        ),
        approved_cases - accepted_cases
    FROM funnel_counts

    UNION ALL

    SELECT
        4,
        'Disbursement Submitted',
        submitted_cases,
        ROUND(
            submitted_cases * 100.0
            / NULLIF(accepted_cases, 0),
            2
        ),
        accepted_cases - submitted_cases
    FROM funnel_counts

    UNION ALL

    SELECT
        5,
        'Disbursement Received',
        received_cases,
        ROUND(
            received_cases * 100.0
            / NULLIF(submitted_cases, 0),
            2
        ),
        submitted_cases - received_cases
    FROM funnel_counts

)

SELECT
    stage_order,
    funnel_stage,
    stage_cases,
    conversion_rate_pct,
    stage_dropoff_cases
FROM funnel_stages;


-- ------------------------------------------------------------
-- VIEW 2: Completion and Disbursement Reconciliation
-- One row per order status
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW
vw_financing_reconciliation_status AS

SELECT

    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status,

    COUNT(*) AS total_orders,

    SUM(financing_case_flag)
        AS financing_cases,

    SUM(disbursement_received_flag)
        AS disbursement_received_cases,

    SUM(completed_flag)
        AS completed_cases,

    SUM(
        CASE
            WHEN completed_flag = 1
             AND disbursement_received_flag = 0
            THEN 1 ELSE 0
        END
    ) AS completed_without_received_cases,

    SUM(
        CASE
            WHEN disbursement_received_flag = 1
             AND completed_flag = 0
            THEN 1 ELSE 0
        END
    ) AS received_not_completed_cases

FROM vw_dashboard_base

GROUP BY
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    );


-- ------------------------------------------------------------
-- VIEW 3: Financing Flag Consistency Audit
-- Only financing cases are included, matching original SQL
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW
vw_financing_flag_audit AS

SELECT

    COUNT(*) AS financing_cases,

    SUM(
        CASE
            WHEN approved_flag = 1
             AND financing_case_flag = 0
            THEN 1 ELSE 0
        END
    ) AS approved_without_financing_flag,

    SUM(
        CASE
            WHEN accepted_flag = 1
             AND approved_flag = 0
            THEN 1 ELSE 0
        END
    ) AS accepted_without_approval_flag,

    SUM(
        CASE
            WHEN disbursement_submitted_flag = 1
             AND accepted_flag = 0
            THEN 1 ELSE 0
        END
    ) AS submitted_without_acceptance_flag,

    SUM(
        CASE
            WHEN disbursement_received_flag = 1
             AND disbursement_submitted_flag = 0
            THEN 1 ELSE 0
        END
    ) AS received_without_submission_flag,

    SUM(
        CASE
            WHEN completed_flag = 1
             AND disbursement_received_flag = 0
            THEN 1 ELSE 0
        END
    ) AS completed_without_received_flag,

    SUM(
        CASE
            WHEN disbursement_received_flag = 1
             AND completed_flag = 0
            THEN 1 ELSE 0
        END
    ) AS received_not_completed_flag

FROM vw_dashboard_base

WHERE financing_case_flag = 1;


-- ------------------------------------------------------------
-- VIEW 4: Submitted but Not Received
-- Grouped by order status, loan status, loan type and financier
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW
vw_financing_submitted_not_received AS

SELECT

    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status,

    COALESCE(
        NULLIF(TRIM(final_loan_status), ''),
        'Missing / Blank'
    ) AS final_loan_status,

    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    ) AS final_loan_type,

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS final_financier,

    COUNT(*) AS case_count

FROM vw_dashboard_base

WHERE financing_case_flag = 1
  AND disbursement_submitted_flag = 1
  AND disbursement_received_flag = 0

GROUP BY

    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ),

    COALESCE(
        NULLIF(TRIM(final_loan_status), ''),
        'Missing / Blank'
    ),

    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    ),

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    );


-- ------------------------------------------------------------
-- VIEW 5: Submission and Receipt Date Coverage
-- Submitted but Not Received cases grouped by order status
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW
vw_financing_submission_date_audit AS

SELECT

    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status,

    COUNT(*) AS submitted_not_received_cases,

    SUM(
        CASE
            WHEN final_loan_status = 'Accepted'
            THEN 1 ELSE 0
        END
    ) AS accepted_loan_status_cases,

    SUM(
        CASE
            WHEN disbursement_receive_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_receive_date,

    SUM(
        CASE
            WHEN disbursement_slip_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_disbursement_slip_date,

    SUM(
        CASE
            WHEN disbursement_submit_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_submission_date

FROM vw_dashboard_base

WHERE financing_case_flag = 1
  AND disbursement_submitted_flag = 1
  AND disbursement_received_flag = 0

GROUP BY

    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    );


-- ============================================================
-- 04. VALIDATION
-- ============================================================

-- Result 1: Main Financing Funnel

SELECT *
FROM vw_financing_funnel
ORDER BY stage_order;


-- Result 2: Completion and Disbursement Reconciliation

SELECT *
FROM vw_financing_reconciliation_status
ORDER BY total_orders DESC;


-- Result 3: Flag Consistency Audit

SELECT *
FROM vw_financing_flag_audit;


-- Result 4: Submitted but Not Received

SELECT *
FROM vw_financing_submitted_not_received
ORDER BY case_count DESC;


-- Result 5: Submission Date Audit

SELECT *
FROM vw_financing_submission_date_audit
ORDER BY submitted_not_received_cases DESC;


-- ============================================================
-- 05. MAIN FUNNEL TOTAL VALIDATION
-- ============================================================

SELECT

    SUM(stage_cases) AS sum_of_stage_cases,

    MAX(
        CASE
            WHEN funnel_stage = 'Financing Case'
            THEN stage_cases
        END
    ) AS financing_cases,

    MAX(
        CASE
            WHEN funnel_stage = 'Disbursement Received'
            THEN stage_cases
        END
    ) AS received_cases

FROM vw_financing_funnel;


-- ============================================================
-- 04. FINANCIER PERFORMANCE VIEWS
--
-- Source: vw_dashboard_base
-- Original SQL:
-- 04_financing_performance.sql
-- 05_bank_branch_performance.sql
--
-- Important:
-- 1. Financier means financing institution.
-- 2. Store means CARSOME store, NOT bank branch.
-- 3. Rates are descriptive, flag-based indicators.
-- ============================================================

USE carsome_orders_analysis;


-- ============================================================
-- VIEW 1: OVERALL FINANCIER PERFORMANCE
-- Original: 05_bank_branch_performance.sql - Result Set 1
--
-- Population: All source orders grouped by final_financier.
-- Missing financier is retained as a separate group.
-- ============================================================

CREATE OR REPLACE VIEW
vw_financier_overall_performance AS

SELECT

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS total_orders,

    SUM(financing_case_flag)
        AS financing_cases,

    SUM(approved_flag)
        AS approved_cases,

    SUM(accepted_flag)
        AS accepted_cases,

    SUM(disbursement_submitted_flag)
        AS disbursement_submitted_cases,

    SUM(disbursement_received_flag)
        AS disbursement_received_cases,

    SUM(completed_flag)
        AS completed_cases,

    ROUND(
        100.0 * SUM(approved_flag)
        / NULLIF(SUM(financing_case_flag), 0),
        2
    ) AS financing_to_approval_pct,

    ROUND(
        100.0 * SUM(accepted_flag)
        / NULLIF(SUM(approved_flag), 0),
        2
    ) AS approval_to_acceptance_pct,

    ROUND(
        100.0 * SUM(disbursement_received_flag)
        / NULLIF(SUM(disbursement_submitted_flag), 0),
        2
    ) AS submission_to_received_pct,

    SUM(
        CASE
            WHEN completed_flag = 1
             AND disbursement_received_flag = 0
            THEN 1 ELSE 0
        END
    ) AS completed_without_received_flag,

    'Descriptive only; financier assignment may be stage-dependent'
        AS interpretation_note

FROM vw_dashboard_base

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    );


-- ============================================================
-- VIEW 2: FINANCIER x CARSOME STORE PERFORMANCE
-- Original: 05_bank_branch_performance.sql - Result Set 2
--
-- Important:
-- Store is a CARSOME store, NOT a bank branch.
-- ============================================================

CREATE OR REPLACE VIEW
vw_financier_store_performance AS

SELECT

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    ) AS carsome_store,

    COUNT(*) AS total_orders,

    SUM(financing_case_flag)
        AS financing_cases,

    SUM(approved_flag)
        AS approved_cases,

    SUM(accepted_flag)
        AS accepted_cases,

    SUM(disbursement_submitted_flag)
        AS submitted_cases,

    SUM(disbursement_received_flag)
        AS received_cases,

    ROUND(
        100.0 * SUM(disbursement_received_flag)
        / NULLIF(SUM(disbursement_submitted_flag), 0),
        2
    ) AS submission_to_received_pct

FROM vw_dashboard_base

GROUP BY

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ),

    COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    );


-- ============================================================
-- VIEW 3: FINANCING STAGE CONVERSION BY FINANCIER
-- Original: 05_bank_branch_performance.sql - Result Set 3
--
-- Denominators:
-- Financing -> Approval:
--     approved / financing
--
-- Approval -> Acceptance:
--     accepted / approved
--
-- Acceptance -> Submission:
--     submitted / accepted
--
-- Submission -> Received:
--     received / submitted
--
-- These are flag-based descriptive ratios,
-- not necessarily cohort conversion rates.
-- ============================================================

CREATE OR REPLACE VIEW
vw_financier_stage_conversion AS

SELECT

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    SUM(financing_case_flag)
        AS financing_cases,

    SUM(approved_flag)
        AS approved_cases,

    SUM(accepted_flag)
        AS accepted_cases,

    SUM(disbursement_submitted_flag)
        AS submitted_cases,

    SUM(disbursement_received_flag)
        AS received_cases,

    ROUND(
        100.0 * SUM(approved_flag)
        / NULLIF(SUM(financing_case_flag), 0),
        2
    ) AS financing_to_approval_pct,

    ROUND(
        100.0 * SUM(accepted_flag)
        / NULLIF(SUM(approved_flag), 0),
        2
    ) AS approval_to_acceptance_pct,

    ROUND(
        100.0 * SUM(disbursement_submitted_flag)
        / NULLIF(SUM(accepted_flag), 0),
        2
    ) AS acceptance_to_submission_pct,

    ROUND(
        100.0 * SUM(disbursement_received_flag)
        / NULLIF(SUM(disbursement_submitted_flag), 0),
        2
    ) AS submission_to_received_pct

FROM vw_dashboard_base

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    );


-- ============================================================
-- VIEW 4: FINANCIER ASSIGNMENT AUDIT
-- Original: 04_financing_performance.sql
--
-- Shows how missing financier assignments are distributed
-- across order statuses.
-- ============================================================

CREATE OR REPLACE VIEW
vw_financier_assignment_audit AS

SELECT

    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status,

    CASE
        WHEN final_financier IS NULL
          OR TRIM(final_financier) = ''
        THEN 'Missing / Blank'
        ELSE 'Financier Identified'
    END AS financier_field_status,

    COUNT(*) AS total_orders,

    SUM(financing_case_flag)
        AS financing_cases,

    SUM(approved_flag)
        AS approved_cases,

    SUM(accepted_flag)
        AS accepted_cases,

    SUM(disbursement_submitted_flag)
        AS submitted_cases,

    SUM(disbursement_received_flag)
        AS received_cases,

    SUM(completed_flag)
        AS completed_cases,

    SUM(
        CASE
            WHEN final_financier IS NULL
              OR TRIM(final_financier) = ''
            THEN 1 ELSE 0
        END
    ) AS missing_financier_orders

FROM vw_dashboard_base

WHERE financing_case_flag = 1

GROUP BY

    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ),

    CASE
        WHEN final_financier IS NULL
          OR TRIM(final_financier) = ''
        THEN 'Missing / Blank'
        ELSE 'Financier Identified'
    END;


-- ============================================================
-- 05. VALIDATION
-- ============================================================

-- Result 1: Overall Financier Performance

SELECT *
FROM vw_financier_overall_performance
ORDER BY financing_cases DESC;


-- Result 2: Financier x CARSOME Store

SELECT *
FROM vw_financier_store_performance
ORDER BY financing_cases DESC;


-- Result 3: Stage Conversion by Financier

SELECT *
FROM vw_financier_stage_conversion
ORDER BY financing_cases DESC;


-- Result 4: Financier Assignment Audit

SELECT *
FROM vw_financier_assignment_audit
ORDER BY total_orders DESC;


-- ============================================================
-- 06. RECONCILIATION CHECKS
-- ============================================================

-- Check 1: Overall financing cases

SELECT
    SUM(financing_cases) AS total_financing_cases
FROM vw_financier_overall_performance;


-- Check 2: Store-level financing cases

SELECT
    SUM(financing_cases) AS store_financing_cases
FROM vw_financier_store_performance;


-- Check 3: Stage conversion financing cases

SELECT
    SUM(financing_cases) AS stage_financing_cases
FROM vw_financier_stage_conversion;


-- Check 4: Missing financier financing cases

SELECT
    SUM(financing_cases) AS missing_financier_cases
FROM vw_financier_overall_performance
WHERE financier = 'Missing / Blank';



USE carsome_orders_analysis;

SELECT
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'carsome_orders_analysis'
  AND TABLE_NAME = 'stg_orders'
  AND (
      LOWER(COLUMN_NAME) LIKE '%financier%'
      OR LOWER(COLUMN_NAME) LIKE '%bank%'
      OR LOWER(COLUMN_NAME) LIKE '%loan%'
      OR LOWER(COLUMN_NAME) LIKE '%application%'
  )
ORDER BY ORDINAL_POSITION;



USE carsome_orders_analysis;

-- Check all tables containing financier/bank fields

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'carsome_orders_analysis'
  AND (
      LOWER(COLUMN_NAME) LIKE '%financier%'
      OR LOWER(COLUMN_NAME) LIKE '%bank%'
  )
ORDER BY TABLE_NAME, ORDINAL_POSITION;



USE carsome_orders_analysis;

-- 1. Check original financier conversion logic

SHOW CREATE VIEW vw_072_financier_conversion;


-- 2. Check original financier waiting logic

SHOW CREATE VIEW vw_072_financier_waiting;


USE carsome_orders_analysis;

-- ============================================================
-- 1. Historical Financier Conversion
-- Snapshot period: September 2026
-- ============================================================

SELECT *
FROM vw_072_financier_conversion
ORDER BY submitted_cases DESC;


-- ============================================================
-- 2. Historical Financier Waiting
-- Snapshot date: 6 October 2026
-- ============================================================

SELECT *
FROM vw_072_financier_waiting
ORDER BY not_received_cases DESC;


-- ============================================================
-- 3. Compare Historical Conversion with New View
-- ============================================================

SELECT

    h.financier,

    h.submitted_cases AS historical_submitted,

    h.received_cases AS historical_received,

    n.submitted_cases AS current_submitted,

    n.received_cases AS current_received,

    h.received_conversion_rate_pct
        AS historical_received_rate,

    n.submission_to_received_pct
        AS current_received_rate

FROM vw_072_financier_conversion h

LEFT JOIN vw_financier_stage_conversion n

    ON h.financier = n.financier

ORDER BY h.submitted_cases DESC;



USE carsome_orders_analysis;

SELECT '01 Overall Performance' AS dataset,
       COUNT(*) AS row_count
FROM vw_financier_overall_performance

UNION ALL

SELECT '02 Store Performance',
       COUNT(*)
FROM vw_financier_store_performance

UNION ALL

SELECT '03 Stage Conversion',
       COUNT(*)
FROM vw_financier_stage_conversion

UNION ALL

SELECT '04 Assignment Audit',
       COUNT(*)
FROM vw_financier_assignment_audit

UNION ALL

SELECT '05 Disbursement Conversion',
       COUNT(*)
FROM vw_072_financier_conversion;



SELECT *
FROM vw_financier_overall_performance;

SELECT *
FROM vw_financier_store_performance;


SELECT *
FROM vw_financier_stage_conversion;

SELECT *
FROM vw_financier_assignment_audit;

SELECT *
FROM vw_072_financier_conversion;