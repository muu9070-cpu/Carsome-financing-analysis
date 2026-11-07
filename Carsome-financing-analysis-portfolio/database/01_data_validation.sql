CREATE DATABASE IF NOT EXISTS carsome_orders_analysis;

USE carsome_orders_analysis;

SELECT COUNT(*) AS total_rows
FROM stg_orders;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(DISTINCT summarised_order_id) AS unique_summarised_orders
FROM stg_orders;

USE carsome_orders_analysis;

SELECT DATABASE();

DESCRIBE stg_orders;

SELECT
    COUNT(*) AS total_rows,

    COUNT(order_id) AS order_id_non_null,
    COUNT(summarised_order_id) AS summarised_order_id_non_null,

    COUNT(created_time) AS created_time_non_null,

    COUNT(financing_case_flag) AS financing_flag_non_null,
    COUNT(approved_flag) AS approved_flag_non_null,
    COUNT(accepted_flag) AS accepted_flag_non_null,

    COUNT(disbursement_submitted_flag) AS disb_submitted_flag_non_null,
    COUNT(disbursement_received_flag) AS disb_received_flag_non_null,
    COUNT(completed_flag) AS completed_flag_non_null

FROM stg_orders;


SELECT
    COUNT(*) AS all_orders,

    SUM(financing_case_flag) AS financing_cases,

    SUM(resubmission_flag) AS resubmission_cases,

    SUM(approved_flag) AS approved_cases,

    SUM(accepted_flag) AS accepted_cases,

    SUM(disbursement_submitted_flag) AS disbursement_submitted,

    SUM(disbursement_received_flag) AS disbursement_received,

    SUM(completed_flag) AS order_completed

FROM stg_orders;


SELECT
    'financing_case_flag' AS field_name,
    MIN(financing_case_flag) AS min_value,
    MAX(financing_case_flag) AS max_value
FROM stg_orders

UNION ALL

SELECT
    'resubmission_flag',
    MIN(resubmission_flag),
    MAX(resubmission_flag)
FROM stg_orders

UNION ALL

SELECT
    'approved_flag',
    MIN(approved_flag),
    MAX(approved_flag)
FROM stg_orders

UNION ALL

SELECT
    'accepted_flag',
    MIN(accepted_flag),
    MAX(accepted_flag)
FROM stg_orders

UNION ALL

SELECT
    'disbursement_submitted_flag',
    MIN(disbursement_submitted_flag),
    MAX(disbursement_submitted_flag)
FROM stg_orders

UNION ALL

SELECT
    'disbursement_received_flag',
    MIN(disbursement_received_flag),
    MAX(disbursement_received_flag)
FROM stg_orders

UNION ALL

SELECT
    'completed_flag',
    MIN(completed_flag),
    MAX(completed_flag)
FROM stg_orders;

SELECT
    COUNT(*) AS all_orders,

    SUM(financing_case_flag) AS financing_cases,

    SUM(resubmission_flag) AS resubmission_cases,

    SUM(approved_flag) AS approved_cases,

    SUM(accepted_flag) AS accepted_cases,

    SUM(disbursement_submitted_flag) AS disbursement_submitted,

    SUM(disbursement_received_flag) AS disbursement_received,

    SUM(completed_flag) AS order_completed,

    -- Financing Conversion
    ROUND(
        SUM(financing_case_flag) / COUNT(*) * 100,
        2
    ) AS financing_rate,

    -- Approval Conversion
    ROUND(
        SUM(approved_flag)
        / NULLIF(SUM(financing_case_flag), 0) * 100,
        2
    ) AS approval_rate,

    -- Acceptance Conversion
    ROUND(
        SUM(accepted_flag)
        / NULLIF(SUM(approved_flag), 0) * 100,
        2
    ) AS acceptance_rate,

    -- Disbursement Submission Conversion
    ROUND(
        SUM(disbursement_submitted_flag)
        / NULLIF(SUM(accepted_flag), 0) * 100,
        2
    ) AS disbursement_submission_rate,

    -- Disbursement Receipt Conversion
    ROUND(
        SUM(disbursement_received_flag)
        / NULLIF(SUM(disbursement_submitted_flag), 0) * 100,
        2
    ) AS disbursement_receipt_rate,

    -- Completion Conversion
    ROUND(
        SUM(completed_flag)
        / NULLIF(SUM(disbursement_received_flag), 0) * 100,
        2
    ) AS completion_rate

FROM stg_orders;


SELECT

    COUNT(*) AS total_orders,

    -- Accepted but not Approved
    SUM(
        CASE
            WHEN accepted_flag = 1
             AND approved_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS accepted_not_approved,

    -- Disbursement Submitted but not Accepted
    SUM(
        CASE
            WHEN disbursement_submitted_flag = 1
             AND accepted_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS submitted_not_accepted,

    -- Disbursement Received but not Submitted
    SUM(
        CASE
            WHEN disbursement_received_flag = 1
             AND disbursement_submitted_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS received_not_submitted,

    -- Order Completed but Disbursement not Received
    SUM(
        CASE
            WHEN completed_flag = 1
             AND disbursement_received_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS completed_not_received,

    -- Disbursement Received but Order not Completed
    SUM(
        CASE
            WHEN disbursement_received_flag = 1
             AND completed_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS received_not_completed

FROM stg_orders;
    
SELECT

    /* 1. Approved → Not Accepted */
    SUM(
        CASE
            WHEN approved_flag = 1
             AND accepted_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS approved_not_accepted,

    ROUND(
        SUM(
            CASE
                WHEN approved_flag = 1
                 AND accepted_flag = 0
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(SUM(approved_flag), 0) * 100,
        2
    ) AS approved_not_accepted_rate,

    /* 2. Accepted → Not Disbursement Submitted */
    SUM(
        CASE
            WHEN accepted_flag = 1
             AND disbursement_submitted_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS accepted_not_disb_submitted,

    ROUND(
        SUM(
            CASE
                WHEN accepted_flag = 1
                 AND disbursement_submitted_flag = 0
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(SUM(accepted_flag), 0) * 100,
        2
    ) AS accepted_not_disb_submitted_rate,

    /* 3. Disbursement Submitted → Not Received */
    SUM(
        CASE
            WHEN disbursement_submitted_flag = 1
             AND disbursement_received_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS submitted_not_received,

    ROUND(
        SUM(
            CASE
                WHEN disbursement_submitted_flag = 1
                 AND disbursement_received_flag = 0
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(SUM(disbursement_submitted_flag), 0) * 100,
        2
    ) AS submitted_not_received_rate,

    /* 4. Disbursement Received → Not Completed */
    SUM(
        CASE
            WHEN disbursement_received_flag = 1
             AND completed_flag = 0
            THEN 1
            ELSE 0
        END
    ) AS received_not_completed,

    ROUND(
        SUM(
            CASE
                WHEN disbursement_received_flag = 1
                 AND completed_flag = 0
                THEN 1
                ELSE 0
            END
        )
        / NULLIF(SUM(disbursement_received_flag), 0) * 100,
        2
    ) AS received_not_completed_rate

FROM stg_orders;

SELECT
    COUNT(acceptance_tat_clean) AS valid_acceptance_cases,

    ROUND(
        AVG(acceptance_tat_clean),
        2
    ) AS avg_acceptance_tat,

    ROUND(
        MIN(acceptance_tat_clean),
        2
    ) AS min_acceptance_tat,

    ROUND(
        MAX(acceptance_tat_clean),
        2
    ) AS max_acceptance_tat,

    ROUND(
        STDDEV(acceptance_tat_clean),
        2
    ) AS std_acceptance_tat

FROM stg_orders;

SELECT

    COUNT(*) AS valid_acceptance_cases,

    SUM(
        CASE
            WHEN acceptance_tat_clean >= 8
            THEN 1
            ELSE 0
        END
    ) AS slow_acceptance_cases,

    ROUND(
        SUM(
            CASE
                WHEN acceptance_tat_clean >= 8
                THEN 1
                ELSE 0
            END
        )
        / COUNT(*) * 100,
        2
    ) AS slow_acceptance_rate

FROM stg_orders

WHERE acceptance_tat_clean IS NOT NULL;

SELECT
    CASE
        WHEN acceptance_tat_clean BETWEEN 0 AND 1
            THEN '0-1 Day'

        WHEN acceptance_tat_clean BETWEEN 2 AND 3
            THEN '2-3 Days'

        WHEN acceptance_tat_clean BETWEEN 4 AND 7
            THEN '4-7 Days'

        WHEN acceptance_tat_clean >= 8
            THEN '8+ Days'
    END AS acceptance_tat_bucket,

    COUNT(*) AS cases

FROM stg_orders

WHERE acceptance_tat_clean IS NOT NULL

GROUP BY
    CASE
        WHEN acceptance_tat_clean BETWEEN 0 AND 1
            THEN '0-1 Day'
        WHEN acceptance_tat_clean BETWEEN 2 AND 3
            THEN '2-3 Days'
        WHEN acceptance_tat_clean BETWEEN 4 AND 7
            THEN '4-7 Days'
        WHEN acceptance_tat_clean >= 8
            THEN '8+ Days'
    END

ORDER BY
    MIN(acceptance_tat_clean);
    
SELECT
    COUNT(disbursement_tat_clean) AS valid_disbursement_cases,

    ROUND(
        AVG(disbursement_tat_clean),
        2
    ) AS avg_disbursement_tat,

    ROUND(
        MIN(disbursement_tat_clean),
        2
    ) AS min_disbursement_tat,

    ROUND(
        MAX(disbursement_tat_clean),
        2
    ) AS max_disbursement_tat,

    ROUND(
        STDDEV(disbursement_tat_clean),
        2
    ) AS std_disbursement_tat

FROM stg_orders;
  
SELECT
    COUNT(*) AS valid_disbursement_cases,

    SUM(
        CASE
            WHEN disbursement_tat_clean >= 8 THEN 1
            ELSE 0
        END
    ) AS slow_disbursement_cases,

    ROUND(
        SUM(
            CASE
                WHEN disbursement_tat_clean >= 8 THEN 1
                ELSE 0
            END
        )
        / COUNT(*) * 100,
        2
    ) AS slow_disbursement_rate

FROM stg_orders
WHERE disbursement_tat_clean IS NOT NULL;

SELECT
    CASE
        WHEN disbursement_tat_clean BETWEEN 0 AND 1
            THEN '0-1 Day'

        WHEN disbursement_tat_clean BETWEEN 2 AND 3
            THEN '2-3 Days'

        WHEN disbursement_tat_clean BETWEEN 4 AND 7
            THEN '4-7 Days'

        WHEN disbursement_tat_clean >= 8
            THEN '8+ Days'
    END AS disbursement_tat_bucket,

    COUNT(*) AS cases

FROM stg_orders
WHERE disbursement_tat_clean IS NOT NULL
GROUP BY
    CASE
        WHEN disbursement_tat_clean BETWEEN 0 AND 1
            THEN '0-1 Day'
        WHEN disbursement_tat_clean BETWEEN 2 AND 3
            THEN '2-3 Days'
        WHEN disbursement_tat_clean BETWEEN 4 AND 7
            THEN '4-7 Days'
        WHEN disbursement_tat_clean >= 8
            THEN '8+ Days'
    END
ORDER BY
    MIN(disbursement_tat_clean);