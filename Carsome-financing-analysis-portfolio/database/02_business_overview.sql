
-- ============================================================
-- Project: CARSOME Order & Financing Operations Analytics
-- File: 02_business_overview.sql
-- Purpose: Overall Business Performance
-- Source: carsome_orders_analysis.stg_orders_v2
-- ============================================================

USE carsome_orders_analysis;


-- ------------------------------------------------------------
-- Query 1: Overall Business KPI Summary
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT order_id) AS unique_orders,

    SUM(financing_case_flag) AS financing_cases,

    ROUND(
        100.0 * SUM(financing_case_flag)
        / NULLIF(COUNT(*), 0),
        2
    ) AS financing_case_rate_pct,

    SUM(accepted_flag) AS final_accepted_cases,

    ROUND(
        100.0 * SUM(accepted_flag)
        / NULLIF(SUM(financing_case_flag), 0),
        2
    ) AS accepted_vs_financing_pct,

    SUM(disbursement_submitted_flag)
        AS disbursement_submitted_cases,

    SUM(disbursement_received_flag)
        AS disbursement_received_cases,

    SUM(completed_flag) AS completed_cases

FROM stg_orders_v2;


-- ------------------------------------------------------------
-- Query 2: Order Status Distribution
-- ------------------------------------------------------------

SELECT
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status_category,

    COUNT(*) AS cases,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(
            (SELECT COUNT(*) FROM stg_orders_v2),
            0
        ),
        2
    ) AS pct_of_all_orders

FROM stg_orders_v2

GROUP BY
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    )

ORDER BY cases DESC;


-- ------------------------------------------------------------
-- Query 3: Final Loan Status Distribution
-- ------------------------------------------------------------

SELECT
    COALESCE(
        NULLIF(TRIM(final_loan_status), ''),
        'Missing / Blank'
    ) AS final_loan_status_category,

    COUNT(*) AS cases,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(
            (SELECT COUNT(*) FROM stg_orders_v2),
            0
        ),
        2
    ) AS pct_of_all_orders

FROM stg_orders_v2

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_loan_status), ''),
        'Missing / Blank'
    )

ORDER BY cases DESC;


-- ------------------------------------------------------------
-- Query 4: Disbursement Status Distribution
-- ------------------------------------------------------------

SELECT
    COALESCE(
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    ) AS disbursement_status_category,

    COUNT(*) AS cases,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(
            (SELECT COUNT(*) FROM stg_orders_v2),
            0
        ),
        2
    ) AS pct_of_all_orders

FROM stg_orders_v2

GROUP BY
    COALESCE(
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    )

ORDER BY cases DESC;


-- ------------------------------------------------------------
-- Query 5: Order Status x Disbursement Status
-- ------------------------------------------------------------

SELECT
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status_category,

    COALESCE(
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    ) AS disbursement_status_category,

    COUNT(*) AS cases

FROM stg_orders_v2

GROUP BY
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ),  

    COALESCE(
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    )

ORDER BY cases DESC;
