
USE carsome_orders_analysis;

/* ============================================================
   04_financing_funnel.sql
   Step 1: Audit financing funnel stage counts and consistency
   Source: stg_orders
   Purpose: Validate stage definitions before calculating conversion
   ============================================================ */


/* RESULT SET 1
   Compare stage counts across all orders and financing cases.
   Raw flags are preserved; no source data is modified.
*/
SELECT
    'All Orders' AS analysis_population,
    COUNT(*) AS population_orders,

    SUM(COALESCE(financing_case_flag, 0))
        AS financing_cases,

    SUM(COALESCE(approved_flag, 0))
        AS approved_cases,

    SUM(COALESCE(accepted_flag, 0))
        AS accepted_cases,

    SUM(COALESCE(disbursement_submitted_flag, 0))
        AS disbursement_submitted_cases,

    SUM(COALESCE(disbursement_received_flag, 0))
        AS disbursement_received_cases,

    SUM(COALESCE(completed_flag, 0))
        AS completed_cases

FROM stg_orders

UNION ALL

SELECT
    'Financing Cases Only' AS analysis_population,
    SUM(
        CASE
            WHEN COALESCE(financing_case_flag, 0) = 1
            THEN 1 ELSE 0
        END
    ) AS population_orders,

    SUM(
        CASE
            WHEN COALESCE(financing_case_flag, 0) = 1
            THEN COALESCE(financing_case_flag, 0)
            ELSE 0
        END
    ) AS financing_cases,

    SUM(
        CASE
            WHEN COALESCE(financing_case_flag, 0) = 1
            THEN COALESCE(approved_flag, 0)
            ELSE 0
        END
    ) AS approved_cases,

    SUM(
        CASE
            WHEN COALESCE(financing_case_flag, 0) = 1
            THEN COALESCE(accepted_flag, 0)
            ELSE 0
        END
    ) AS accepted_cases,

    SUM(
        CASE
            WHEN COALESCE(financing_case_flag, 0) = 1
            THEN COALESCE(disbursement_submitted_flag, 0)
            ELSE 0
        END
    ) AS disbursement_submitted_cases,

    SUM(
        CASE
            WHEN COALESCE(financing_case_flag, 0) = 1
            THEN COALESCE(disbursement_received_flag, 0)
            ELSE 0
        END
    ) AS disbursement_received_cases,

    SUM(
        CASE
            WHEN COALESCE(financing_case_flag, 0) = 1
            THEN COALESCE(completed_flag, 0)
            ELSE 0
        END
    ) AS completed_cases

FROM stg_orders;


/* RESULT SET 2
   Count records that violate the expected stage sequence.
   These are data-quality diagnostics, not automatically confirmed errors.
*/
SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN COALESCE(approved_flag, 0) = 1
             AND COALESCE(financing_case_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS approved_without_financing_flag,

    SUM(
        CASE
            WHEN COALESCE(accepted_flag, 0) = 1
             AND COALESCE(approved_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS accepted_without_approval_flag,

    SUM(
        CASE
            WHEN COALESCE(disbursement_submitted_flag, 0) = 1
             AND COALESCE(accepted_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS submitted_without_acceptance_flag,

    SUM(
        CASE
            WHEN COALESCE(disbursement_received_flag, 0) = 1
             AND COALESCE(disbursement_submitted_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS received_without_submission_flag,

    SUM(
        CASE
            WHEN COALESCE(completed_flag, 0) = 1
             AND COALESCE(disbursement_received_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS completed_without_received_flag,

    SUM(
        CASE
            WHEN COALESCE(disbursement_received_flag, 0) = 1
             AND COALESCE(completed_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS received_but_not_completed_flag

FROM stg_orders;




USE carsome_orders_analysis;

/* ============================================================
   04_financing_funnel.sql

   Purpose:
   1. Measure conversion across financing stages.
   2. Quantify stage-to-stage drop-off.
   3. Audit inconsistencies between completion and disbursement.
   4. Preserve original flags without modifying source data.

   Source: stg_orders
   Population: financing_case_flag = 1 for main funnel.
   Note: This query uses the current loaded dataset.
         It does not claim to reconstruct a historical snapshot.
   ============================================================ */


/* ============================================================
   RESULT SET 1: Main Financing Funnel
   ============================================================ */

WITH funnel_base AS (
    SELECT
        order_id,
        financing_case_flag,
        approved_flag,
        accepted_flag,
        disbursement_submitted_flag,
        disbursement_received_flag,
        completed_flag
    FROM stg_orders
    WHERE COALESCE(financing_case_flag, 0) = 1
),

funnel_counts AS (
    SELECT
        COUNT(*) AS financing_cases,

        SUM(CASE
            WHEN COALESCE(approved_flag, 0) = 1
            THEN 1 ELSE 0
        END) AS approved_cases,

        SUM(CASE
            WHEN COALESCE(accepted_flag, 0) = 1
            THEN 1 ELSE 0
        END) AS accepted_cases,

        SUM(CASE
            WHEN COALESCE(disbursement_submitted_flag, 0) = 1
            THEN 1 ELSE 0
        END) AS submitted_cases,

        SUM(CASE
            WHEN COALESCE(disbursement_received_flag, 0) = 1
            THEN 1 ELSE 0
        END) AS received_cases,

        SUM(CASE
            WHEN COALESCE(completed_flag, 0) = 1
            THEN 1 ELSE 0
        END) AS completed_cases

    FROM funnel_base
),

funnel_stages AS (
    SELECT
        1 AS stage_order,
        'Financing Case' AS funnel_stage,
        financing_cases AS stage_cases,
        CAST(NULL AS DECIMAL(10,2)) AS conversion_rate_pct,
        CAST(NULL AS SIGNED) AS stage_dropoff_cases
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
FROM funnel_stages
ORDER BY stage_order;


/* ============================================================
   RESULT SET 2: Completion and Disbursement Reconciliation
   Completion is reported separately from the main funnel.
   ============================================================ */

SELECT
    COALESCE(order_status, 'Missing / Blank') AS order_status,

    COUNT(*) AS total_orders,

    SUM(CASE
        WHEN COALESCE(financing_case_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS financing_cases,

    SUM(CASE
        WHEN COALESCE(disbursement_received_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS disbursement_received_cases,

    SUM(CASE
        WHEN COALESCE(completed_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS completed_cases,

    SUM(CASE
        WHEN COALESCE(completed_flag, 0) = 1
         AND COALESCE(disbursement_received_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS completed_without_received_cases,

    SUM(CASE
        WHEN COALESCE(disbursement_received_flag, 0) = 1
         AND COALESCE(completed_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS received_not_completed_cases

FROM stg_orders

GROUP BY COALESCE(order_status, 'Missing / Blank')

ORDER BY total_orders DESC;


/* ============================================================
   RESULT SET 3: Original Flag Consistency Audit
   Counts only; source flags remain unchanged.
   ============================================================ */

SELECT
    COUNT(*) AS financing_cases,

    SUM(CASE
        WHEN COALESCE(approved_flag, 0) = 1
         AND COALESCE(financing_case_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS approved_without_financing_flag,

    SUM(CASE
        WHEN COALESCE(accepted_flag, 0) = 1
         AND COALESCE(approved_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS accepted_without_approval_flag,

    SUM(CASE
        WHEN COALESCE(disbursement_submitted_flag, 0) = 1
         AND COALESCE(accepted_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS submitted_without_acceptance_flag,

    SUM(CASE
        WHEN COALESCE(disbursement_received_flag, 0) = 1
         AND COALESCE(disbursement_submitted_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS received_without_submission_flag,

    SUM(CASE
        WHEN COALESCE(completed_flag, 0) = 1
         AND COALESCE(disbursement_received_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS completed_without_received_flag,

    SUM(CASE
        WHEN COALESCE(disbursement_received_flag, 0) = 1
         AND COALESCE(completed_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS received_not_completed_flag

FROM stg_orders
WHERE COALESCE(financing_case_flag, 0) = 1;



USE carsome_orders_analysis;

SELECT
    order_status,
    final_loan_status,
    final_loan_type,
    final_financier,
    COUNT(*) AS case_count
FROM stg_orders
WHERE COALESCE(financing_case_flag, 0) = 1
  AND COALESCE(disbursement_submitted_flag, 0) = 1
  AND COALESCE(disbursement_received_flag, 0) = 0
GROUP BY
    order_status,
    final_loan_status,
    final_loan_type,
    final_financier
ORDER BY case_count DESC;



USE carsome_orders_analysis;

SELECT
    order_status,

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

FROM stg_orders

WHERE COALESCE(financing_case_flag, 0) = 1
  AND COALESCE(disbursement_submitted_flag, 0) = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY order_status

ORDER BY submitted_not_received_cases DESC;




USE carsome_orders_analysis;

/* 04_financing_funnel.sql
   Reconciliation analysis:
   Completed orders submitted for disbursement
   but without received flag.
*/

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS final_financier,

    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    ) AS final_loan_type,

    COUNT(*) AS completed_submitted_not_received_cases,

    SUM(
        CASE
            WHEN disbursement_submit_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_submission_date,

    SUM(
        CASE
            WHEN loan_acceptance_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_loan_acceptance_date,

    MIN(disbursement_submit_date) AS earliest_submission_date,
    MAX(disbursement_submit_date) AS latest_submission_date

FROM stg_orders

WHERE COALESCE(financing_case_flag, 0) = 1
  AND COALESCE(completed_flag, 0) = 1
  AND COALESCE(disbursement_submitted_flag, 0) = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ),
    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    )

ORDER BY
    completed_submitted_not_received_cases DESC,
    final_financier,
    final_loan_type;




USE carsome_orders_analysis;

/* 04_financing_funnel.sql
   Completion–Disbursement Reconciliation
   Fixed snapshot date: 2026-10-13
*/

WITH reconciliation_cases AS (
    SELECT
        order_id,
        final_financier,
        final_loan_type,
        order_status,
        disbursement_submit_date,

        DATEDIFF(
            DATE('2026-10-13'),
            DATE(disbursement_submit_date)
        ) AS submission_wait_days

    FROM stg_orders

    WHERE COALESCE(financing_case_flag, 0) = 1
      AND COALESCE(completed_flag, 0) = 1
      AND COALESCE(disbursement_submitted_flag, 0) = 1
      AND COALESCE(disbursement_received_flag, 0) = 0
      AND disbursement_submit_date IS NOT NULL
)

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS final_financier,

    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    ) AS final_loan_type,

    COUNT(*) AS reconciliation_cases,

    MIN(submission_wait_days) AS min_wait_days,
    ROUND(AVG(submission_wait_days), 2) AS avg_wait_days,
    MAX(submission_wait_days) AS max_wait_days,

    SUM(
        CASE
            WHEN submission_wait_days BETWEEN 0 AND 7
            THEN 1 ELSE 0
        END
    ) AS wait_0_to_7_days,

    SUM(
        CASE
            WHEN submission_wait_days BETWEEN 8 AND 14
            THEN 1 ELSE 0
        END
    ) AS wait_8_to_14_days,

    SUM(
        CASE
            WHEN submission_wait_days BETWEEN 15 AND 30
            THEN 1 ELSE 0
        END
    ) AS wait_15_to_30_days,

    SUM(
        CASE
            WHEN submission_wait_days > 30
            THEN 1 ELSE 0
        END
    ) AS wait_over_30_days

FROM reconciliation_cases

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ),
    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    )

ORDER BY
    reconciliation_cases DESC,
    max_wait_days DESC;
