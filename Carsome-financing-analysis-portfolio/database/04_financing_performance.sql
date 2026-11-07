
-- ============================================================
-- 04_financing_performance.sql
-- Analysis 01: Financier Performance Overview
-- ============================================================

USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS financing_cases,

    SUM(COALESCE(approved_flag, 0)) AS approved_cases,

    SUM(COALESCE(accepted_flag, 0)) AS accepted_cases,

    SUM(
        COALESCE(disbursement_submitted_flag, 0)
    ) AS disbursement_submitted_cases,

    SUM(
        COALESCE(disbursement_received_flag, 0)
    ) AS disbursement_received_cases,

    ROUND(
        SUM(COALESCE(approved_flag, 0)) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS approval_rate_pct,

    ROUND(
        SUM(COALESCE(accepted_flag, 0)) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS accepted_rate_pct,

    ROUND(
        SUM(COALESCE(disbursement_received_flag, 0)) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS disbursement_received_rate_pct

FROM stg_orders

WHERE financing_case_flag = 1

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY financing_cases DESC;



USE carsome_orders_analysis;

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
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    ) AS disbursement_status,

    financing_case_flag,
    approved_flag,
    accepted_flag,
    disbursement_submitted_flag,
    disbursement_received_flag,

    COUNT(*) AS cases

FROM stg_orders

WHERE financing_case_flag = 1
  AND (
      final_financier IS NULL
      OR TRIM(final_financier) = ''
  )

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
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    ),
    financing_case_flag,
    approved_flag,
    accepted_flag,
    disbursement_submitted_flag,
    disbursement_received_flag

ORDER BY cases DESC;



USE carsome_orders_analysis;

SELECT
    order_status,
    final_loan_status,
    disbursement_status,

    financing_case_flag,
    approved_flag,
    accepted_flag,
    disbursement_submitted_flag,
    disbursement_received_flag,
    completed_flag,

    COUNT(*) AS cases

FROM stg_orders

WHERE financing_case_flag = 1
  AND (
      final_financier IS NULL
      OR TRIM(final_financier) = ''
  )
  AND TRIM(order_status) = 'Order Cancelled'

GROUP BY
    order_status,
    final_loan_status,
    disbursement_status,
    financing_case_flag,
    approved_flag,
    accepted_flag,
    disbursement_submitted_flag,
    disbursement_received_flag,
    completed_flag

ORDER BY cases DESC;



USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN final_financier IS NULL
              OR TRIM(final_financier) = ''
            THEN 1
            ELSE 0
        END
    ) AS missing_financier_orders,

    ROUND(
        SUM(
            CASE
                WHEN final_financier IS NULL
                  OR TRIM(final_financier) = ''
                THEN 1
                ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS missing_financier_rate_pct

FROM stg_orders

WHERE financing_case_flag = 1

GROUP BY
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    )

ORDER BY missing_financier_orders DESC;




USE carsome_orders_analysis;

SELECT
    TRIM(final_financier) AS financier,

    COUNT(*) AS total_orders,

    SUM(COALESCE(approved_flag, 0)) AS approved_orders,

    SUM(COALESCE(accepted_flag, 0)) AS accepted_orders,

    SUM(COALESCE(disbursement_submitted_flag, 0))
        AS disbursement_submitted_orders,

    SUM(COALESCE(disbursement_received_flag, 0))
        AS disbursement_received_orders,

    ROUND(
        SUM(COALESCE(accepted_flag, 0)) * 100.0
        / NULLIF(SUM(COALESCE(approved_flag, 0)), 0),
        2
    ) AS approval_to_acceptance_pct,

    ROUND(
        SUM(COALESCE(disbursement_received_flag, 0)) * 100.0
        / NULLIF(SUM(COALESCE(accepted_flag, 0)), 0),
        2
    ) AS acceptance_to_received_pct

FROM stg_orders

WHERE financing_case_flag = 1
  AND final_financier IS NOT NULL
  AND TRIM(final_financier) <> ''

GROUP BY TRIM(final_financier)

ORDER BY total_orders DESC;



USE carsome_orders_analysis;

SELECT
    TRIM(final_financier) AS financier,

    COUNT(*) AS accepted_orders,

    SUM(
        CASE
            WHEN COALESCE(disbursement_submitted_flag, 0) = 1
             AND COALESCE(disbursement_received_flag, 0) = 1
            THEN 1 ELSE 0
        END
    ) AS submitted_and_received_orders,

    SUM(
        CASE
            WHEN COALESCE(disbursement_submitted_flag, 0) = 1
             AND COALESCE(disbursement_received_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS submitted_not_received_orders,

    SUM(
        CASE
            WHEN COALESCE(disbursement_submitted_flag, 0) = 0
             AND COALESCE(disbursement_received_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS not_submitted_orders,

    ROUND(
        SUM(
            CASE
                WHEN COALESCE(disbursement_submitted_flag, 0) = 1
                 AND COALESCE(disbursement_received_flag, 0) = 0
                THEN 1 ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS submitted_not_received_pct

FROM stg_orders
WHERE financing_case_flag = 1
  AND accepted_flag = 1
  AND final_financier IS NOT NULL
  AND TRIM(final_financier) <> ''

GROUP BY TRIM(final_financier)
ORDER BY submitted_not_received_orders DESC;



USE carsome_orders_analysis;

WITH gap_cases AS (

    /* Stage 1: Submitted but not received */
    SELECT
        TRIM(final_financier) AS financier,
        'Submitted - Not Received' AS gap_stage,
        DATEDIFF(
            CURDATE(),
            DATE(disbursement_submit_date)
        ) AS waiting_days
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND accepted_flag = 1
      AND COALESCE(disbursement_submitted_flag, 0) = 1
      AND COALESCE(disbursement_received_flag, 0) = 0
      AND disbursement_submit_date IS NOT NULL
      AND final_financier IS NOT NULL
      AND TRIM(final_financier) <> ''

    UNION ALL

    /* Stage 2: Accepted but not submitted */
    SELECT
        TRIM(final_financier) AS financier,
        'Accepted - Not Submitted' AS gap_stage,
        DATEDIFF(
            CURDATE(),
            DATE(loan_acceptance_date)
        ) AS waiting_days
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND accepted_flag = 1
      AND COALESCE(disbursement_submitted_flag, 0) = 0
      AND COALESCE(disbursement_received_flag, 0) = 0
      AND loan_acceptance_date IS NOT NULL
      AND final_financier IS NOT NULL
      AND TRIM(final_financier) <> ''
)

SELECT
    financier,
    gap_stage,

    COUNT(*) AS gap_orders,

    SUM(CASE
        WHEN waiting_days BETWEEN 0 AND 3
        THEN 1 ELSE 0
    END) AS waiting_0_3_days,

    SUM(CASE
        WHEN waiting_days BETWEEN 4 AND 7
        THEN 1 ELSE 0
    END) AS waiting_4_7_days,

    SUM(CASE
        WHEN waiting_days BETWEEN 8 AND 14
        THEN 1 ELSE 0
    END) AS waiting_8_14_days,

    SUM(CASE
        WHEN waiting_days > 14
        THEN 1 ELSE 0
    END) AS waiting_over_14_days,

    SUM(CASE
        WHEN waiting_days < 0
        THEN 1 ELSE 0
    END) AS negative_waiting_days,

    ROUND(AVG(
        CASE WHEN waiting_days >= 0
             THEN waiting_days
        END
    ), 2) AS avg_waiting_days

FROM gap_cases
GROUP BY financier, gap_stage
ORDER BY gap_orders DESC, avg_waiting_days DESC;




USE carsome_orders_analysis;

WITH gap_cases AS (

    SELECT
        TRIM(final_financier) AS financier,
        'Submitted - Not Received' AS gap_stage,
        DATE(disbursement_submit_date) AS base_date,
        DATEDIFF(
            CURDATE(),
            DATE(disbursement_submit_date)
        ) AS waiting_days
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND accepted_flag = 1
      AND COALESCE(disbursement_submitted_flag, 0) = 1
      AND COALESCE(disbursement_received_flag, 0) = 0
      AND disbursement_submit_date IS NOT NULL
      AND final_financier IS NOT NULL
      AND TRIM(final_financier) <> ''

    UNION ALL

    SELECT
        TRIM(final_financier) AS financier,
        'Accepted - Not Submitted' AS gap_stage,
        DATE(loan_acceptance_date) AS base_date,
        DATEDIFF(
            CURDATE(),
            DATE(loan_acceptance_date)
        ) AS waiting_days
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND accepted_flag = 1
      AND COALESCE(disbursement_submitted_flag, 0) = 0
      AND COALESCE(disbursement_received_flag, 0) = 0
      AND loan_acceptance_date IS NOT NULL
      AND final_financier IS NOT NULL
      AND TRIM(final_financier) <> ''
)

SELECT
    gap_stage,
    COUNT(*) AS gap_orders,
    MIN(base_date) AS earliest_base_date,
    MAX(base_date) AS latest_base_date,
    MIN(waiting_days) AS min_waiting_days,
    ROUND(AVG(waiting_days), 2) AS avg_waiting_days,
    MAX(waiting_days) AS max_waiting_days,

    SUM(CASE WHEN waiting_days < 0 THEN 1 ELSE 0 END)
        AS negative_waiting_cases,

    SUM(CASE WHEN waiting_days BETWEEN 0 AND 7 THEN 1 ELSE 0 END)
        AS cases_0_7_days,

    SUM(CASE WHEN waiting_days BETWEEN 8 AND 14 THEN 1 ELSE 0 END)
        AS cases_8_14_days,

    SUM(CASE WHEN waiting_days > 14 THEN 1 ELSE 0 END)
        AS cases_over_14_days

FROM gap_cases
GROUP BY gap_stage;





USE carsome_orders_analysis;

WITH gap_cases AS (

    SELECT
        TRIM(final_financier) AS financier,
        'Submitted - Not Received' AS gap_stage,
        DATEDIFF(
            CURDATE(),
            DATE(disbursement_submit_date)
        ) AS waiting_days
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND accepted_flag = 1
      AND COALESCE(disbursement_submitted_flag, 0) = 1
      AND COALESCE(disbursement_received_flag, 0) = 0
      AND disbursement_submit_date IS NOT NULL
      AND final_financier IS NOT NULL
      AND TRIM(final_financier) <> ''

    UNION ALL

    SELECT
        TRIM(final_financier) AS financier,
        'Accepted - Not Submitted' AS gap_stage,
        DATEDIFF(
            CURDATE(),
            DATE(loan_acceptance_date)
        ) AS waiting_days
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND accepted_flag = 1
      AND COALESCE(disbursement_submitted_flag, 0) = 0
      AND COALESCE(disbursement_received_flag, 0) = 0
      AND loan_acceptance_date IS NOT NULL
      AND final_financier IS NOT NULL
      AND TRIM(final_financier) <> ''
)

SELECT
    financier,

    COUNT(*) AS total_gap_orders,

    SUM(CASE
        WHEN gap_stage = 'Submitted - Not Received'
        THEN 1 ELSE 0
    END) AS submitted_not_received_orders,

    SUM(CASE
        WHEN gap_stage = 'Accepted - Not Submitted'
        THEN 1 ELSE 0
    END) AS accepted_not_submitted_orders,

    SUM(CASE
        WHEN waiting_days > 14
        THEN 1 ELSE 0
    END) AS over_14_day_orders,

    ROUND(AVG(waiting_days), 2) AS avg_waiting_days,

    MAX(waiting_days) AS max_waiting_days

FROM gap_cases
GROUP BY financier
ORDER BY total_gap_orders DESC;



USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    ) AS store,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct,

    SUM(
        CASE
            WHEN financing_case_flag = 1
             AND accepted_flag = 1
             AND COALESCE(disbursement_submitted_flag, 0) = 0
             AND COALESCE(disbursement_received_flag, 0) = 0
             AND loan_acceptance_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS accepted_not_submitted_orders,

    SUM(
        CASE
            WHEN financing_case_flag = 1
             AND accepted_flag = 1
             AND COALESCE(disbursement_submitted_flag, 0) = 1
             AND COALESCE(disbursement_received_flag, 0) = 0
             AND disbursement_submit_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS submitted_not_received_orders

FROM stg_orders
GROUP BY
    COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    )
HAVING COUNT(*) >= 10
ORDER BY
    cancelled_orders DESC,
    submitted_not_received_orders DESC;


USE carsome_orders_analysis;

SELECT
    COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank') AS store,

    /* Accepted but not submitted */
    SUM(
        CASE
            WHEN accepted_not_disb_submitted_flag = 1
            THEN 1 ELSE 0
        END
    ) AS accepted_not_submitted_total,

    SUM(
        CASE
            WHEN accepted_not_disb_submitted_flag = 1
             AND TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS accepted_not_submitted_cancelled,

    SUM(
        CASE
            WHEN accepted_not_disb_submitted_flag = 1
             AND (
                 order_status IS NULL
                 OR TRIM(order_status) <> 'Order Cancelled'
             )
            THEN 1 ELSE 0
        END
    ) AS accepted_not_submitted_not_cancelled,

    /* Submitted but not received */
    SUM(
        CASE
            WHEN submitted_not_received_flag = 1
            THEN 1 ELSE 0
        END
    ) AS submitted_not_received_total,

    SUM(
        CASE
            WHEN submitted_not_received_flag = 1
             AND TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS submitted_not_received_cancelled,

    SUM(
        CASE
            WHEN submitted_not_received_flag = 1
             AND (
                 order_status IS NULL
                 OR TRIM(order_status) <> 'Order Cancelled'
             )
            THEN 1 ELSE 0
        END
    ) AS submitted_not_received_not_cancelled

FROM carsome_orders_analysis.stg_orders
GROUP BY
    COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank')
HAVING
    accepted_not_submitted_total > 0
    OR submitted_not_received_total > 0
ORDER BY
    accepted_not_submitted_not_cancelled
      + submitted_not_received_not_cancelled DESC;
      
      
      
SELECT
    TRIM(order_status) AS order_status,

    SUM(
        CASE
            WHEN accepted_not_disb_submitted_flag = 1
            THEN 1 ELSE 0
        END
    ) AS accepted_not_submitted_cases,

    SUM(
        CASE
            WHEN submitted_not_received_flag = 1
            THEN 1 ELSE 0
        END
    ) AS submitted_not_received_cases,

    COUNT(*) AS total_rows

FROM carsome_orders_analysis.stg_orders

WHERE accepted_not_disb_submitted_flag = 1
   OR submitted_not_received_flag = 1

GROUP BY TRIM(order_status)

ORDER BY
    accepted_not_submitted_cases
    + submitted_not_received_cases DESC;
    
    
    
USE carsome_orders_analysis;

SELECT
    TRIM(order_status) AS order_status,
    TRIM(final_loan_status) AS final_loan_status,
    TRIM(disbursement_status) AS disbursement_status,

    COUNT(*) AS total_cases,

    SUM(
        CASE
            WHEN accepted_not_disb_submitted_flag = 1
            THEN 1 ELSE 0
        END
    ) AS accepted_not_submitted_cases,

    SUM(
        CASE
            WHEN submitted_not_received_flag = 1
            THEN 1 ELSE 0
        END
    ) AS submitted_not_received_cases,

    SUM(
        CASE
            WHEN completed_flag = 1
            THEN 1 ELSE 0
        END
    ) AS completed_flag_cases

FROM carsome_orders_analysis.stg_orders

WHERE accepted_not_disb_submitted_flag = 1
   OR submitted_not_received_flag = 1

GROUP BY
    TRIM(order_status),
    TRIM(final_loan_status),
    TRIM(disbursement_status)

ORDER BY
    total_cases DESC;
    
    
USE carsome_orders_analysis;

SELECT
    CASE
        WHEN TRIM(order_status) = 'Order Completed'
            THEN 'Completed - Reconciliation Required'

        WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 'Cancelled - Exclude from Active Queue'

        WHEN TRIM(order_status) = 'Order Closed'
            THEN 'Closed - Reconciliation Required'

        ELSE 'Active Financing Gap - Review Required'
    END AS gap_review_category,

    SUM(
        CASE
            WHEN accepted_not_disb_submitted_flag = 1
            THEN 1 ELSE 0
        END
    ) AS accepted_not_submitted_cases,

    SUM(
        CASE
            WHEN submitted_not_received_flag = 1
            THEN 1 ELSE 0
        END
    ) AS submitted_not_received_cases,

    COUNT(*) AS total_gap_rows

FROM carsome_orders_analysis.stg_orders

WHERE accepted_not_disb_submitted_flag = 1
   OR submitted_not_received_flag = 1

GROUP BY gap_review_category

ORDER BY total_gap_rows DESC;





USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    ) AS store,

    CASE
        WHEN accepted_not_disb_submitted_flag = 1
            THEN 'Accepted - Not Submitted'
        WHEN submitted_not_received_flag = 1
            THEN 'Submitted - Not Received'
    END AS gap_stage,

    TRIM(order_status) AS order_status,

    COUNT(*) AS gap_cases

FROM carsome_orders_analysis.stg_orders

WHERE
    (
        accepted_not_disb_submitted_flag = 1
        OR submitted_not_received_flag = 1
    )
    AND COALESCE(TRIM(order_status), '') NOT IN (
        'Order Completed',
        'Order Cancelled',
        'Order Closed'
    )

GROUP BY
    COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank'),
    CASE
        WHEN accepted_not_disb_submitted_flag = 1
            THEN 'Accepted - Not Submitted'
        WHEN submitted_not_received_flag = 1
            THEN 'Submitted - Not Received'
    END,
    TRIM(order_status)

ORDER BY
    gap_cases DESC,
    store;
    
 USE carsome_orders_analysis;

SELECT
    CASE
        WHEN accepted_not_disb_submitted_flag = 1
            THEN 'Accepted - Not Submitted'
        WHEN submitted_not_received_flag = 1
            THEN 'Submitted - Not Received'
    END AS gap_stage,

    COUNT(*) AS total_cases,

    MIN(
        DATEDIFF(
            CURRENT_DATE(),
            CASE
                WHEN accepted_not_disb_submitted_flag = 1
                    THEN loan_acceptance_date
                WHEN submitted_not_received_flag = 1
                    THEN disbursement_submit_date
            END
        )
    ) AS min_waiting_days,

    ROUND(
        AVG(
            DATEDIFF(
                CURRENT_DATE(),
                CASE
                    WHEN accepted_not_disb_submitted_flag = 1
                        THEN loan_acceptance_date
                    WHEN submitted_not_received_flag = 1
                        THEN disbursement_submit_date
                END
            )
        ),
        2
    ) AS avg_waiting_days,

    MAX(
        DATEDIFF(
            CURRENT_DATE(),
            CASE
                WHEN accepted_not_disb_submitted_flag = 1
                    THEN loan_acceptance_date
                WHEN submitted_not_received_flag = 1
                    THEN disbursement_submit_date
            END
        )
    ) AS max_waiting_days

FROM carsome_orders_analysis.stg_orders

WHERE
    (
        accepted_not_disb_submitted_flag = 1
        OR submitted_not_received_flag = 1
    )
    AND COALESCE(TRIM(order_status), '') NOT IN (
        'Order Completed',
        'Order Cancelled',
        'Order Closed'
    )

GROUP BY gap_stage
ORDER BY total_cases DESC;   
    
USE carsome_orders_analysis;

WITH store_metrics AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(store), ''),
            'Missing / Blank'
        ) AS store_name,

        COUNT(*) AS total_orders,

        SUM(
            CASE WHEN TRIM(order_status) = 'Order Cancelled'
                 THEN 1 ELSE 0 END
        ) AS cancelled_orders,

        SUM(
            CASE WHEN accepted_not_disb_submitted_flag = 1
                 AND COALESCE(TRIM(order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 THEN 1 ELSE 0 END
        ) AS accepted_not_submitted_cases,

        SUM(
            CASE WHEN submitted_not_received_flag = 1
                 AND COALESCE(TRIM(order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 THEN 1 ELSE 0 END
        ) AS submitted_not_received_cases,

        AVG(
            CASE
                WHEN accepted_not_disb_submitted_flag = 1
                 AND COALESCE(TRIM(order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                THEN DATEDIFF(CURRENT_DATE(), loan_acceptance_date)

                WHEN submitted_not_received_flag = 1
                 AND COALESCE(TRIM(order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                THEN DATEDIFF(CURRENT_DATE(), disbursement_submit_date)
            END
        ) AS avg_gap_waiting_days,

        MAX(
            CASE
                WHEN accepted_not_disb_submitted_flag = 1
                 AND COALESCE(TRIM(order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                THEN DATEDIFF(CURRENT_DATE(), loan_acceptance_date)

                WHEN submitted_not_received_flag = 1
                 AND COALESCE(TRIM(order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                THEN DATEDIFF(CURRENT_DATE(), disbursement_submit_date)
            END
        ) AS max_gap_waiting_days

    FROM stg_orders
    GROUP BY COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    )
)

SELECT
    store_name,
    total_orders,
    cancelled_orders,
    ROUND(
        100.0 * cancelled_orders / NULLIF(total_orders, 0),
        2
    ) AS cancellation_rate_pct,
    accepted_not_submitted_cases,
    submitted_not_received_cases,
    ROUND(avg_gap_waiting_days, 2) AS avg_gap_waiting_days,
    max_gap_waiting_days,
    CASE
        WHEN accepted_not_submitted_cases
             + submitted_not_received_cases >= 5
          OR max_gap_waiting_days >= 30
        THEN 'P1 - Investigate First'

        WHEN accepted_not_submitted_cases
             + submitted_not_received_cases >= 2
          OR max_gap_waiting_days >= 14
        THEN 'P2 - Review'

        ELSE 'P3 - Monitor'
    END AS investigation_priority

FROM store_metrics
ORDER BY
    CASE
        WHEN accepted_not_submitted_cases
             + submitted_not_received_cases >= 5
          OR max_gap_waiting_days >= 30
        THEN 1
        WHEN accepted_not_submitted_cases
             + submitted_not_received_cases >= 2
          OR max_gap_waiting_days >= 14
        THEN 2
        ELSE 3
    END,
    accepted_not_submitted_cases
        + submitted_not_received_cases DESC,
    max_gap_waiting_days DESC;    
 
 


USE carsome_orders_analysis;

WITH params AS (
    SELECT DATE('2026-10-13') AS analysis_date
),

store_metrics AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(s.store), ''),
            'Missing / Blank'
        ) AS store_name,

        COUNT(*) AS total_orders,

        SUM(
            CASE
                WHEN TRIM(s.order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) AS cancelled_orders,

        SUM(
            CASE
                WHEN s.accepted_not_disb_submitted_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                THEN 1 ELSE 0
            END
        ) AS accepted_not_submitted_cases,

        SUM(
            CASE
                WHEN s.submitted_not_received_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                THEN 1 ELSE 0
            END
        ) AS submitted_not_received_cases,

        AVG(
            CASE
                WHEN s.accepted_not_disb_submitted_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 AND s.loan_acceptance_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     s.loan_acceptance_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    s.loan_acceptance_date
                )

                WHEN s.submitted_not_received_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 AND s.disbursement_submit_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     s.disbursement_submit_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    s.disbursement_submit_date
                )
            END
        ) AS avg_gap_waiting_days,

        MAX(
            CASE
                WHEN s.accepted_not_disb_submitted_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 AND s.loan_acceptance_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     s.loan_acceptance_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    s.loan_acceptance_date
                )

                WHEN s.submitted_not_received_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 AND s.disbursement_submit_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     s.disbursement_submit_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    s.disbursement_submit_date
                )
            END
        ) AS max_gap_waiting_days

    FROM stg_orders s
    CROSS JOIN params p

    GROUP BY
        COALESCE(
            NULLIF(TRIM(s.store), ''),
            'Missing / Blank'
        )
),

scored AS (
    SELECT
        *,
        ROUND(
            100.0 * cancelled_orders
            / NULLIF(total_orders, 0),
            2
        ) AS cancellation_rate_pct,

        accepted_not_submitted_cases
        + submitted_not_received_cases AS total_active_gap_cases

    FROM store_metrics
),

ranked AS (
    SELECT
        *,

        CASE
            WHEN cancelled_orders >= 30
             AND cancellation_rate_pct >= 30
            THEN 'P1 - High Cancellation Risk'

            WHEN total_orders >= 30
             AND cancellation_rate_pct >= 40
            THEN 'P2 - Review Cancellation Risk'

            WHEN cancelled_orders >= 15
            THEN 'P2 - Review Cancellation Risk'

            ELSE 'P3 - Monitor Cancellation Risk'
        END AS cancellation_priority,

        CASE
            WHEN total_active_gap_cases >= 5
              OR max_gap_waiting_days >= 30
            THEN 'P1 - High Financing Backlog'

            WHEN total_active_gap_cases >= 2
              OR max_gap_waiting_days >= 14
            THEN 'P2 - Review Financing Backlog'

            ELSE 'P3 - Monitor Financing Backlog'
        END AS financing_backlog_priority

    FROM scored
)

SELECT
    store_name,
    total_orders,
    cancelled_orders,
    cancellation_rate_pct,

    accepted_not_submitted_cases,
    submitted_not_received_cases,
    total_active_gap_cases,

    ROUND(avg_gap_waiting_days, 2) AS avg_gap_waiting_days,
    max_gap_waiting_days,

    cancellation_priority,
    financing_backlog_priority,

    CASE
        WHEN cancellation_priority = 'P1 - High Cancellation Risk'
         AND financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 'Investigate Cancellation and Financing Together'

        WHEN cancellation_priority = 'P1 - High Cancellation Risk'
        THEN 'Investigate Cancellation Drivers'

        WHEN financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 'Investigate Financing Process Delays'

        WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
         AND financing_backlog_priority = 'P2 - Review Financing Backlog'
        THEN 'Review Both Risk Areas'

        WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
        THEN 'Review Cancellation Patterns'

        WHEN financing_backlog_priority = 'P2 - Review Financing Backlog'
        THEN 'Review Financing Backlog'

        ELSE 'Routine Monitoring'
    END AS investigation_action

FROM ranked

ORDER BY
    CASE
        WHEN cancelled_orders >= 30
         AND cancellation_rate_pct >= 30
        THEN 1

        WHEN total_orders >= 30
         AND cancellation_rate_pct >= 40
        THEN 2

        WHEN cancelled_orders >= 15
        THEN 2

        ELSE 3
    END,

    total_active_gap_cases DESC,
    max_gap_waiting_days DESC,
    cancelled_orders DESC;




USE carsome_orders_analysis;

WITH params AS (
    -- 固定分析快照日期
    SELECT DATE('2026-10-13') AS analysis_date
),

store_metrics AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(s.store), ''),
            'Missing / Blank'
        ) AS store_name,

        COUNT(*) AS total_orders,

        SUM(
            CASE
                WHEN TRIM(s.order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) AS cancelled_orders,

        -- 已接受，但尚未提交放款
        SUM(
            CASE
                WHEN s.accepted_not_disb_submitted_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                THEN 1 ELSE 0
            END
        ) AS accepted_not_submitted_cases,

        -- 已提交放款，但尚未收到款项
        SUM(
            CASE
                WHEN s.submitted_not_received_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                THEN 1 ELSE 0
            END
        ) AS submitted_not_received_cases,

        -- 平均融资待处理天数
        AVG(
            CASE
                WHEN s.accepted_not_disb_submitted_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 AND s.loan_acceptance_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     s.loan_acceptance_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    s.loan_acceptance_date
                )

                WHEN s.submitted_not_received_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 AND s.disbursement_submit_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     s.disbursement_submit_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    s.disbursement_submit_date
                )
            END
        ) AS avg_gap_waiting_days,

        -- 最大融资待处理天数
        MAX(
            CASE
                WHEN s.accepted_not_disb_submitted_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 AND s.loan_acceptance_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     s.loan_acceptance_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    s.loan_acceptance_date
                )

                WHEN s.submitted_not_received_flag = 1
                 AND COALESCE(TRIM(s.order_status), '') NOT IN (
                     'Order Completed',
                     'Order Cancelled',
                     'Order Closed'
                 )
                 AND s.disbursement_submit_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     s.disbursement_submit_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    s.disbursement_submit_date
                )
            END
        ) AS max_gap_waiting_days

    FROM stg_orders s
    CROSS JOIN params p

    GROUP BY
        COALESCE(
            NULLIF(TRIM(s.store), ''),
            'Missing / Blank'
        )
),

scored AS (
    SELECT
        *,
        ROUND(
            100.0 * cancelled_orders
            / NULLIF(total_orders, 0),
            2
        ) AS cancellation_rate_pct,

        accepted_not_submitted_cases
        + submitted_not_received_cases AS total_active_gap_cases

    FROM store_metrics
),

ranked AS (
    SELECT
        *,

        -- 原有取消风险规则：保持不变
        CASE
            WHEN cancelled_orders >= 30
             AND cancellation_rate_pct >= 30
            THEN 'P1 - High Cancellation Risk'

            WHEN total_orders >= 30
             AND cancellation_rate_pct >= 40
            THEN 'P2 - Review Cancellation Risk'

            WHEN cancelled_orders >= 15
            THEN 'P2 - Review Cancellation Risk'

            ELSE 'P3 - Monitor Cancellation Risk'
        END AS cancellation_priority,

        -- 原有融资积压风险规则：保持不变
        CASE
            WHEN total_active_gap_cases >= 5
              OR max_gap_waiting_days >= 30
            THEN 'P1 - High Financing Backlog'

            WHEN total_active_gap_cases >= 2
              OR max_gap_waiting_days >= 14
            THEN 'P2 - Review Financing Backlog'

            ELSE 'P3 - Monitor Financing Backlog'
        END AS financing_backlog_priority,

        -- 独立标记：不改变原有 P1/P2/P3
        CASE
            WHEN total_orders < 30
             AND cancellation_rate_pct >= 40
            THEN 1
            ELSE 0
        END AS small_sample_cancellation_flag

    FROM scored
)

SELECT
    store_name,
    total_orders,
    cancelled_orders,
    cancellation_rate_pct,

    accepted_not_submitted_cases,
    submitted_not_received_cases,
    total_active_gap_cases,

    -- 数值字段：没有有效等待天数时保留 NULL
    ROUND(avg_gap_waiting_days, 2) AS avg_gap_waiting_days,
    max_gap_waiting_days,

    cancellation_priority,
    financing_backlog_priority,

    small_sample_cancellation_flag,

    CASE
        WHEN small_sample_cancellation_flag = 1
        THEN 'Small Sample - High Cancellation Rate - Review Required'
        ELSE 'No Small Sample Alert'
    END AS small_sample_review_status,

    -- 展示字段：只把 NULL 转成 N/A，不修改数值字段
    CASE
        WHEN avg_gap_waiting_days IS NULL
        THEN 'N/A'
        ELSE CAST(
            ROUND(avg_gap_waiting_days, 2)
            AS CHAR
        )
    END AS avg_gap_waiting_days_display,

    CASE
        WHEN max_gap_waiting_days IS NULL
        THEN 'N/A'
        ELSE CAST(max_gap_waiting_days AS CHAR)
    END AS max_gap_waiting_days_display,

    -- 综合调查行动
   
    CASE
    
       WHEN small_sample_cancellation_flag = 1
       THEN 'Review Small-Sample High Cancellation Rate'

       WHEN cancellation_priority = 'P1 - High Cancellation Risk'
       AND financing_backlog_priority = 'P1 - High Financing Backlog'
       THEN 'Investigate Cancellation and Financing Together'

        WHEN cancellation_priority = 'P1 - High Cancellation Risk'
         AND financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 'Investigate Cancellation and Financing Together'

        WHEN cancellation_priority = 'P1 - High Cancellation Risk'
        THEN 'Investigate Cancellation Drivers'

        WHEN financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 'Investigate Financing Process Delays'

        WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
         AND financing_backlog_priority = 'P2 - Review Financing Backlog'
        THEN 'Review Both Risk Areas'

        WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
        THEN 'Review Cancellation Patterns'

        WHEN financing_backlog_priority = 'P2 - Review Financing Backlog'
        THEN 'Review Financing Backlog'

        ELSE 'Routine Monitoring'
    END AS investigation_action

FROM ranked

ORDER BY
    CASE
        WHEN cancelled_orders >= 30
         AND cancellation_rate_pct >= 30
        THEN 1

        WHEN total_orders >= 30
         AND cancellation_rate_pct >= 40
        THEN 2

        WHEN cancelled_orders >= 15
        THEN 2

        ELSE 3
    END,

    total_active_gap_cases DESC,
    max_gap_waiting_days DESC,
    cancelled_orders DESC;
    
    
    
    

USE carsome_orders_analysis;

SELECT
    COUNT(*) AS overlapping_gap_rows,

    COUNT(DISTINCT order_id) AS overlapping_distinct_orders

FROM stg_orders

WHERE accepted_not_disb_submitted_flag = 1
  AND submitted_not_received_flag = 1
  AND COALESCE(TRIM(order_status), '') NOT IN (
      'Order Completed',
      'Order Cancelled',
      'Order Closed'
  );

USE carsome_orders_analysis;

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS distinct_order_ids,
    COUNT(*) - COUNT(DISTINCT order_id) AS excess_rows,
    SUM(
        CASE
            WHEN order_id IS NULL THEN 1
            ELSE 0
        END
    ) AS null_order_id_rows
FROM stg_orders;


USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status,

    SUM(
        CASE
            WHEN accepted_not_disb_submitted_flag = 1
            THEN 1 ELSE 0
        END
    ) AS accepted_not_submitted_rows,

    SUM(
        CASE
            WHEN submitted_not_received_flag = 1
            THEN 1 ELSE 0
        END
    ) AS submitted_not_received_rows,

    COUNT(*) AS total_rows

FROM stg_orders

WHERE (
        accepted_not_disb_submitted_flag = 1
        OR submitted_not_received_flag = 1
      )

GROUP BY
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    )

ORDER BY total_rows DESC;


USE carsome_orders_analysis;

WITH params AS (
    SELECT DATE('2026-10-13') AS analysis_date
),

-- 第一步：保留源表记录及原始融资标记
tagged_rows AS (
    SELECT
        p.analysis_date,

        s.order_id,
        s.store,
        s.order_status,

        -- 原始融资标记：不覆盖、不修改
        s.accepted_not_disb_submitted_flag,
        s.submitted_not_received_flag,

        s.loan_acceptance_date,
        s.disbursement_submit_date,

        CASE
            WHEN COALESCE(s.accepted_not_disb_submitted_flag, 0) = 1
              OR COALESCE(s.submitted_not_received_flag, 0) = 1
            THEN 1
            ELSE 0
        END AS has_financing_gap_flag,

        CASE
            WHEN COALESCE(s.accepted_not_disb_submitted_flag, 0) = 1
             AND COALESCE(TRIM(s.order_status), '') NOT IN (
                 'Order Completed',
                 'Order Cancelled',
                 'Order Closed'
             )
            THEN DATEDIFF(
                p.analysis_date,
                s.loan_acceptance_date
            )

            WHEN COALESCE(s.submitted_not_received_flag, 0) = 1
             AND COALESCE(TRIM(s.order_status), '') NOT IN (
                 'Order Completed',
                 'Order Cancelled',
                 'Order Closed'
             )
            THEN DATEDIFF(
                p.analysis_date,
                s.disbursement_submit_date
            )

            ELSE NULL
        END AS raw_gap_waiting_days

    FROM stg_orders s
    CROSS JOIN params p
),

-- 第二步：按订单状态分配队列
classified_rows AS (
    SELECT
        *,

        CASE
            WHEN has_financing_gap_flag = 0
            THEN 'Not in Financing Gap Queue'

            WHEN TRIM(COALESCE(order_status, '')) IN (
                'Order Completed',
                'Order Cancelled',
                'Order Closed'
            )
            THEN 'Historical Reconciliation Queue'

            WHEN TRIM(COALESCE(order_status, '')) IN (
                'Pending E-hak Milik',
                'Pending Pay',
                'Pending Deliver'
            )
            THEN 'Active Financing Candidate Queue'

            ELSE 'Exception Review Queue'
        END AS financing_queue,

        CASE
            WHEN has_financing_gap_flag = 1
             AND TRIM(COALESCE(order_status, '')) IN (
                 'Pending E-hak Milik',
                 'Pending Pay',
                 'Pending Deliver'
             )
            THEN 'Candidate - Business Confirmation Required'

            WHEN has_financing_gap_flag = 1
             AND TRIM(COALESCE(order_status, '')) IN (
                 'Order Completed',
                 'Order Cancelled',
                 'Order Closed'
             )
            THEN 'Reconciliation Required'

            WHEN has_financing_gap_flag = 1
            THEN 'Manual Review Required'

            ELSE 'No Financing Gap Flag'
        END AS queue_review_status

    FROM tagged_rows
)

-- 第三步：输出队列与状态汇总
SELECT
    analysis_date,
    financing_queue,
    order_status,
    queue_review_status,

    COUNT(*) AS source_row_count,
    COUNT(DISTINCT order_id) AS distinct_order_count,

    SUM(
        COALESCE(accepted_not_disb_submitted_flag, 0) = 1
    ) AS accepted_not_submitted_count,

    SUM(
        COALESCE(submitted_not_received_flag, 0) = 1
    ) AS submitted_not_received_count,

    SUM(has_financing_gap_flag) AS financing_gap_flag_rows,

    ROUND(
        AVG(
            CASE
                WHEN raw_gap_waiting_days >= 0
                THEN raw_gap_waiting_days
                ELSE NULL
            END
        ),
        2
    ) AS avg_gap_waiting_days,

    MAX(
        CASE
            WHEN raw_gap_waiting_days >= 0
            THEN raw_gap_waiting_days
            ELSE NULL
        END
    ) AS max_gap_waiting_days

FROM classified_rows

WHERE has_financing_gap_flag = 1

GROUP BY
    analysis_date,
    financing_queue,
    order_status,
    queue_review_status

ORDER BY
    CASE financing_queue
        WHEN 'Active Financing Candidate Queue' THEN 1
        WHEN 'Historical Reconciliation Queue' THEN 2
        WHEN 'Exception Review Queue' THEN 3
        ELSE 4
    END,
    source_row_count DESC;





USE carsome_orders_analysis;

WITH params AS (
    SELECT DATE('2026-10-13') AS analysis_date
),

base AS (
    SELECT
        p.analysis_date,
        s.order_id,
        COALESCE(
            NULLIF(TRIM(s.store), ''),
            'Missing / Blank'
        ) AS store_name,
        TRIM(COALESCE(s.order_status, '')) AS order_status,

        COALESCE(s.accepted_not_disb_submitted_flag, 0)
            AS accepted_not_submitted_flag,

        COALESCE(s.submitted_not_received_flag, 0)
            AS submitted_not_received_flag,

        s.loan_acceptance_date,
        s.disbursement_submit_date,

        CASE
            WHEN TRIM(COALESCE(s.order_status, ''))
                = 'Order Cancelled'
            THEN 1 ELSE 0
        END AS cancelled_flag,

        CASE
            WHEN COALESCE(s.accepted_not_disb_submitted_flag, 0) = 1
              OR COALESCE(s.submitted_not_received_flag, 0) = 1
            THEN 1 ELSE 0
        END AS has_financing_gap_flag

    FROM stg_orders s
    CROSS JOIN params p
),

classified AS (
    SELECT
        *,

        CASE
            WHEN has_financing_gap_flag = 0
            THEN 'Not in Financing Gap Queue'

            WHEN order_status IN (
                'Order Completed',
                'Order Cancelled',
                'Order Closed'
            )
            THEN 'Historical Reconciliation Queue'

            WHEN order_status IN (
                'Pending E-hak Milik',
                'Pending Pay',
                'Pending Deliver'
            )
            THEN 'Active Financing Candidate Queue'

            ELSE 'Exception Review Queue'
        END AS financing_queue,

        CASE
            WHEN has_financing_gap_flag = 1
             AND order_status IN (
                 'Pending E-hak Milik',
                 'Pending Pay',
                 'Pending Deliver'
             )
            THEN
                CASE
                    WHEN accepted_not_submitted_flag = 1
                     AND loan_acceptance_date IS NOT NULL
                    THEN DATEDIFF(
                        analysis_date,
                        loan_acceptance_date
                    )

                    WHEN submitted_not_received_flag = 1
                     AND disbursement_submit_date IS NOT NULL
                    THEN DATEDIFF(
                        analysis_date,
                        disbursement_submit_date
                    )

                    ELSE NULL
                END

            ELSE NULL
        END AS active_waiting_days

    FROM base
),

store_metrics AS (
    SELECT
        store_name,

        COUNT(*) AS total_orders,

        SUM(cancelled_flag) AS cancelled_orders,

        ROUND(
            100.0 * SUM(cancelled_flag)
            / NULLIF(COUNT(*), 0),
            2
        ) AS cancellation_rate_pct,

        -- 活动融资候选队列
        SUM(
            CASE
                WHEN financing_queue = 'Active Financing Candidate Queue'
                THEN 1 ELSE 0
            END
        ) AS active_candidate_cases,

        SUM(
            CASE
                WHEN financing_queue = 'Active Financing Candidate Queue'
                 AND accepted_not_submitted_flag = 1
                THEN 1 ELSE 0
            END
        ) AS active_accepted_not_submitted_cases,

        SUM(
            CASE
                WHEN financing_queue = 'Active Financing Candidate Queue'
                 AND submitted_not_received_flag = 1
                THEN 1 ELSE 0
            END
        ) AS active_submitted_not_received_cases,

        ROUND(
            AVG(
                CASE
                    WHEN financing_queue = 'Active Financing Candidate Queue'
                     AND active_waiting_days >= 0
                    THEN active_waiting_days
                    ELSE NULL
                END
            ),
            2
        ) AS active_avg_waiting_days,

        MAX(
            CASE
                WHEN financing_queue = 'Active Financing Candidate Queue'
                 AND active_waiting_days >= 0
                THEN active_waiting_days
                ELSE NULL
            END
        ) AS active_max_waiting_days,

        -- 历史对账队列
        SUM(
            CASE
                WHEN financing_queue = 'Historical Reconciliation Queue'
                THEN 1 ELSE 0
            END
        ) AS historical_reconciliation_cases,

        -- 异常复核队列
        SUM(
            CASE
                WHEN financing_queue = 'Exception Review Queue'
                THEN 1 ELSE 0
            END
        ) AS exception_review_cases

    FROM classified
    GROUP BY store_name
),

ranked AS (
    SELECT
        *,

        -- 原有取消风险规则
        CASE
            WHEN cancelled_orders >= 30
             AND cancellation_rate_pct >= 30
            THEN 'P1 - High Cancellation Risk'

            WHEN total_orders >= 30
             AND cancellation_rate_pct >= 40
            THEN 'P2 - Review Cancellation Risk'

            WHEN cancelled_orders >= 15
            THEN 'P2 - Review Cancellation Risk'

            ELSE 'P3 - Monitor Cancellation Risk'
        END AS cancellation_priority,

        -- 新融资风险：只基于活动候选队列
        CASE
            WHEN active_candidate_cases >= 5
              OR active_max_waiting_days >= 30
            THEN 'P1 - High Financing Backlog'

            WHEN active_candidate_cases >= 2
              OR active_max_waiting_days >= 14
            THEN 'P2 - Review Financing Backlog'

            ELSE 'P3 - Monitor Financing Backlog'
        END AS financing_backlog_priority,

        -- 独立的小样本高取消率观察标记
        CASE
            WHEN total_orders < 30
             AND cancellation_rate_pct >= 40
            THEN 1
            ELSE 0
        END AS small_sample_cancellation_flag

    FROM store_metrics
)

SELECT
    store_name,
    total_orders,
    cancelled_orders,
    cancellation_rate_pct,

    active_candidate_cases,
    active_accepted_not_submitted_cases,
    active_submitted_not_received_cases,
    active_avg_waiting_days,
    active_max_waiting_days,

    historical_reconciliation_cases,
    exception_review_cases,

    cancellation_priority,
    financing_backlog_priority,

    small_sample_cancellation_flag,

    CASE
        WHEN active_avg_waiting_days IS NULL
        THEN 'N/A'
        ELSE CAST(active_avg_waiting_days AS CHAR)
    END AS active_avg_waiting_days_display,

    CASE
        WHEN active_max_waiting_days IS NULL
        THEN 'N/A'
        ELSE CAST(active_max_waiting_days AS CHAR)
    END AS active_max_waiting_days_display,

    CASE
        WHEN small_sample_cancellation_flag = 1
         AND financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 'Investigate Financing and Review Small-Sample Cancellation'

        WHEN small_sample_cancellation_flag = 1
        THEN 'Review Small-Sample High Cancellation Rate'

        WHEN cancellation_priority = 'P1 - High Cancellation Risk'
         AND financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 'Investigate Cancellation and Financing Together'

        WHEN cancellation_priority = 'P1 - High Cancellation Risk'
        THEN 'Investigate Cancellation Drivers'

        WHEN financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 'Investigate Active Financing Backlog'

        WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
         AND financing_backlog_priority = 'P2 - Review Financing Backlog'
        THEN 'Review Both Risk Areas'

        WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
        THEN 'Review Cancellation Patterns'

        WHEN financing_backlog_priority = 'P2 - Review Financing Backlog'
        THEN 'Review Active Financing Backlog'

        WHEN historical_reconciliation_cases > 0
          OR exception_review_cases > 0
        THEN 'Review Historical Reconciliation or Exceptions'

        ELSE 'Routine Monitoring'
    END AS investigation_action

FROM ranked

ORDER BY
    CASE
        WHEN cancellation_priority = 'P1 - High Cancellation Risk'
         AND financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 1

        WHEN cancellation_priority = 'P1 - High Cancellation Risk'
          OR financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 2

        WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
         AND financing_backlog_priority = 'P2 - Review Financing Backlog'
        THEN 3

        WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
          OR financing_backlog_priority = 'P2 - Review Financing Backlog'
        THEN 4

        WHEN small_sample_cancellation_flag = 1
        THEN 5

        ELSE 6
    END,

    active_candidate_cases DESC,
    active_max_waiting_days DESC,
    cancelled_orders DESC;




USE carsome_orders_analysis;

WITH classified AS (
    SELECT
        order_id,
        TRIM(COALESCE(order_status, '')) AS order_status,

        CASE
            WHEN COALESCE(accepted_not_disb_submitted_flag, 0) = 1
              OR COALESCE(submitted_not_received_flag, 0) = 1
            THEN 1
            ELSE 0
        END AS has_financing_gap_flag

    FROM stg_orders
)

SELECT
    CASE
        WHEN order_status IN (
            'Order Completed',
            'Order Cancelled',
            'Order Closed'
        )
        THEN 'Historical Reconciliation Queue'

        WHEN order_status IN (
            'Pending E-hak Milik',
            'Pending Pay',
            'Pending Deliver'
        )
        THEN 'Active Financing Candidate Queue'

        ELSE 'Exception Review Queue'
    END AS financing_queue,

    COUNT(*) AS source_rows,
    COUNT(DISTINCT order_id) AS distinct_orders

FROM classified

WHERE has_financing_gap_flag = 1

GROUP BY financing_queue

ORDER BY financing_queue;








USE carsome_orders_analysis;

WITH params AS (
    SELECT DATE('2026-10-13') AS analysis_date
),

-- =========================================================
-- 1. Base: 保留原始订单字段与融资标记
-- =========================================================
base AS (
    SELECT
        p.analysis_date,
        s.order_id,

        COALESCE(
            NULLIF(TRIM(s.store), ''),
            'Missing / Blank'
        ) AS store_name,

        TRIM(COALESCE(s.order_status, '')) AS order_status,

        COALESCE(
            s.accepted_not_disb_submitted_flag,
            0
        ) AS accepted_not_submitted_flag,

        COALESCE(
            s.submitted_not_received_flag,
            0
        ) AS submitted_not_received_flag,

        s.loan_acceptance_date,
        s.disbursement_submit_date,

        CASE
            WHEN TRIM(COALESCE(s.order_status, ''))
                 = 'Order Cancelled'
            THEN 1
            ELSE 0
        END AS cancelled_flag,

        CASE
            WHEN COALESCE(
                     s.accepted_not_disb_submitted_flag,
                     0
                 ) = 1
              OR COALESCE(
                     s.submitted_not_received_flag,
                     0
                 ) = 1
            THEN 1
            ELSE 0
        END AS has_financing_gap_flag

    FROM stg_orders s
    CROSS JOIN params p
),

-- =========================================================
-- 2. Classified: 每条融资标记记录只分配一个队列
-- =========================================================
classified AS (
    SELECT
        *,

        CASE
            WHEN has_financing_gap_flag = 0
            THEN 'Not in Financing Gap Queue'

            WHEN order_status IN (
                'Order Completed',
                'Order Cancelled',
                'Order Closed'
            )
            THEN 'Historical Reconciliation Queue'

            WHEN order_status IN (
                'Pending E-hak Milik',
                'Pending Pay',
                'Pending Deliver'
            )
            THEN 'Active Financing Candidate Queue'

            ELSE 'Exception Review Queue'
        END AS financing_queue,

        CASE
            WHEN has_financing_gap_flag = 1
             AND order_status IN (
                 'Pending E-hak Milik',
                 'Pending Pay',
                 'Pending Deliver'
             )
            THEN
                CASE
                    WHEN accepted_not_submitted_flag = 1
                     AND loan_acceptance_date IS NOT NULL
                    THEN DATEDIFF(
                        analysis_date,
                        loan_acceptance_date
                    )

                    WHEN submitted_not_received_flag = 1
                     AND disbursement_submit_date IS NOT NULL
                    THEN DATEDIFF(
                        analysis_date,
                        disbursement_submit_date
                    )

                    ELSE NULL
                END

            ELSE NULL
        END AS active_waiting_days

    FROM base
),

-- =========================================================
-- 3. Store metrics: 按门店汇总三个队列
-- =========================================================
store_metrics AS (
    SELECT
        store_name,

        COUNT(*) AS total_orders,

        SUM(cancelled_flag) AS cancelled_orders,

        ROUND(
            100.0 * SUM(cancelled_flag)
            / NULLIF(COUNT(*), 0),
            2
        ) AS cancellation_rate_pct,

        -- 活动融资候选队列
        SUM(
            CASE
                WHEN financing_queue =
                     'Active Financing Candidate Queue'
                THEN 1 ELSE 0
            END
        ) AS active_candidate_cases,

        SUM(
            CASE
                WHEN financing_queue =
                     'Active Financing Candidate Queue'
                 AND accepted_not_submitted_flag = 1
                THEN 1 ELSE 0
            END
        ) AS active_accepted_not_submitted_cases,

        SUM(
            CASE
                WHEN financing_queue =
                     'Active Financing Candidate Queue'
                 AND submitted_not_received_flag = 1
                THEN 1 ELSE 0
            END
        ) AS active_submitted_not_received_cases,

        ROUND(
            AVG(
                CASE
                    WHEN financing_queue =
                         'Active Financing Candidate Queue'
                     AND active_waiting_days >= 0
                    THEN active_waiting_days
                    ELSE NULL
                END
            ),
            2
        ) AS active_avg_waiting_days,

        MAX(
            CASE
                WHEN financing_queue =
                     'Active Financing Candidate Queue'
                 AND active_waiting_days >= 0
                THEN active_waiting_days
                ELSE NULL
            END
        ) AS active_max_waiting_days,

        -- 历史对账队列
        SUM(
            CASE
                WHEN financing_queue =
                     'Historical Reconciliation Queue'
                THEN 1 ELSE 0
            END
        ) AS historical_reconciliation_cases,

        -- 异常复核队列：包含 Money Back 和未识别状态
        SUM(
            CASE
                WHEN financing_queue =
                     'Exception Review Queue'
                THEN 1 ELSE 0
            END
        ) AS exception_review_cases

    FROM classified
    GROUP BY store_name
),

-- =========================================================
-- 4. Ranked: 计算取消风险、活动融资风险和小样本标记
-- =========================================================
ranked AS (
    SELECT
        *,

        -- 保留原有取消风险规则
        CASE
            WHEN cancelled_orders >= 30
             AND cancellation_rate_pct >= 30
            THEN 'P1 - High Cancellation Risk'

            WHEN total_orders >= 30
             AND cancellation_rate_pct >= 40
            THEN 'P2 - Review Cancellation Risk'

            WHEN cancelled_orders >= 15
            THEN 'P2 - Review Cancellation Risk'

            ELSE 'P3 - Monitor Cancellation Risk'
        END AS cancellation_priority,

        -- 融资风险仅基于活动候选队列
        CASE
            WHEN active_candidate_cases >= 5
              OR active_max_waiting_days >= 30
            THEN 'P1 - High Financing Backlog'

            WHEN active_candidate_cases >= 2
              OR active_max_waiting_days >= 14
            THEN 'P2 - Review Financing Backlog'

            ELSE 'P3 - Monitor Financing Backlog'
        END AS financing_backlog_priority,

        -- 独立的小样本高取消率观察标记
        CASE
            WHEN total_orders < 30
             AND cancellation_rate_pct >= 40
            THEN 1
            ELSE 0
        END AS small_sample_cancellation_flag

    FROM store_metrics
)

-- =========================================================
-- 5. Final output: 门店级综合风险和调查行动
-- =========================================================
SELECT
    store_name,
    total_orders,
    cancelled_orders,
    cancellation_rate_pct,

    active_candidate_cases,
    active_accepted_not_submitted_cases,
    active_submitted_not_received_cases,

    active_avg_waiting_days,
    active_max_waiting_days,

    historical_reconciliation_cases,
    exception_review_cases,

    cancellation_priority,
    financing_backlog_priority,

    small_sample_cancellation_flag,

    CASE
        WHEN active_avg_waiting_days IS NULL
        THEN 'N/A'
        ELSE CAST(active_avg_waiting_days AS CHAR)
    END AS active_avg_waiting_days_display,

    CASE
        WHEN active_max_waiting_days IS NULL
        THEN 'N/A'
        ELSE CAST(active_max_waiting_days AS CHAR)
    END AS active_max_waiting_days_display,

    CASE
        WHEN small_sample_cancellation_flag = 1
         AND financing_backlog_priority =
             'P1 - High Financing Backlog'
        THEN
            'Investigate Financing and Review Small-Sample Cancellation'

        WHEN small_sample_cancellation_flag = 1
        THEN
            'Review Small-Sample High Cancellation Rate'

        WHEN cancellation_priority =
             'P1 - High Cancellation Risk'
         AND financing_backlog_priority =
             'P1 - High Financing Backlog'
        THEN
            'Investigate Cancellation and Financing Together'

        WHEN cancellation_priority =
             'P1 - High Cancellation Risk'
        THEN
            'Investigate Cancellation Drivers'

        WHEN financing_backlog_priority =
             'P1 - High Financing Backlog'
        THEN
            'Investigate Active Financing Backlog'

        WHEN cancellation_priority =
             'P2 - Review Cancellation Risk'
         AND financing_backlog_priority =
             'P2 - Review Financing Backlog'
        THEN
            'Review Both Risk Areas'

        WHEN cancellation_priority =
             'P2 - Review Cancellation Risk'
        THEN
            'Review Cancellation Patterns'

        WHEN financing_backlog_priority =
             'P2 - Review Financing Backlog'
        THEN
            'Review Active Financing Backlog'

        WHEN historical_reconciliation_cases > 0
          OR exception_review_cases > 0
        THEN
            'Review Historical Reconciliation or Exceptions'

        ELSE 'Routine Monitoring'
    END AS investigation_action

FROM ranked

ORDER BY
    CASE
        WHEN cancellation_priority =
             'P1 - High Cancellation Risk'
         AND financing_backlog_priority =
             'P1 - High Financing Backlog'
        THEN 1

        WHEN cancellation_priority =
             'P1 - High Cancellation Risk'
          OR financing_backlog_priority =
             'P1 - High Financing Backlog'
        THEN 2

        WHEN cancellation_priority =
             'P2 - Review Cancellation Risk'
         AND financing_backlog_priority =
             'P2 - Review Financing Backlog'
        THEN 3

        WHEN cancellation_priority =
             'P2 - Review Cancellation Risk'
          OR financing_backlog_priority =
             'P2 - Review Financing Backlog'
        THEN 4

        WHEN small_sample_cancellation_flag = 1
        THEN 5

        ELSE 6
    END,

    active_candidate_cases DESC,
    active_max_waiting_days DESC,
    cancelled_orders DESC;


USE carsome_orders_analysis;

SELECT
    order_id,
    store,
    order_status,
    accepted_not_disb_submitted_flag,
    submitted_not_received_flag,
    loan_acceptance_date,
    disbursement_submit_date
FROM stg_orders
WHERE COALESCE(accepted_not_disb_submitted_flag, 0) = 1
   OR COALESCE(submitted_not_received_flag, 0) = 1
ORDER BY
    CASE WHEN TRIM(COALESCE(order_status, '')) = 'Money Back'
         THEN 0 ELSE 1 END,
    store,
    order_id;
    
    
    
    SELECT
    order_id,
    store,
    order_status,
    accepted_not_disb_submitted_flag,
    submitted_not_received_flag
FROM stg_orders
WHERE TRIM(COALESCE(order_status, '')) = 'Money Back';





USE carsome_orders_analysis;

WITH
params AS (
    SELECT DATE('2026-10-13') AS analysis_date
),

/* 1. Preserve original flags and assign each flagged row to one queue */
financing_classified AS (
    SELECT
        s.order_id,
        COALESCE(NULLIF(TRIM(s.store), ''), 'Missing / Blank') AS store_name,
        TRIM(COALESCE(s.order_status, '')) AS order_status,

        /* Original flags: retain without modification */
        COALESCE(s.accepted_not_disb_submitted_flag, 0)
            AS accepted_not_disb_submitted_flag,
        COALESCE(s.submitted_not_received_flag, 0)
            AS submitted_not_received_flag,

        s.loan_acceptance_date,
        s.disbursement_submit_date,

        CASE
            WHEN TRIM(COALESCE(s.order_status, '')) = 'Money Back'
             AND (
                 COALESCE(s.accepted_not_disb_submitted_flag, 0) = 1
                 OR COALESCE(s.submitted_not_received_flag, 0) = 1
             )
                THEN 'Exception Review Queue'

            WHEN TRIM(COALESCE(s.order_status, '')) IN (
                'Order Completed',
                'Order Cancelled',
                'Order Closed'
            )
             AND (
                 COALESCE(s.accepted_not_disb_submitted_flag, 0) = 1
                 OR COALESCE(s.submitted_not_received_flag, 0) = 1
             )
                THEN 'Historical Reconciliation Queue'

            WHEN TRIM(COALESCE(s.order_status, '')) IN (
                'Pending E-hak Milik',
                'Pending Pay',
                'Pending Deliver'
            )
             AND (
                 COALESCE(s.accepted_not_disb_submitted_flag, 0) = 1
                 OR COALESCE(s.submitted_not_received_flag, 0) = 1
             )
                THEN 'Active Financing Candidate Queue'

            WHEN (
                 COALESCE(s.accepted_not_disb_submitted_flag, 0) = 1
                 OR COALESCE(s.submitted_not_received_flag, 0) = 1
            )
                THEN 'Unclassified Financing Exception'

            ELSE NULL
        END AS financing_queue

    FROM stg_orders s
),

/* 2. Calculate waiting days only for active candidate rows */
active_queue_metrics AS (
    SELECT
        f.store_name,

        COUNT(*) AS active_candidate_cases,

        SUM(
            CASE
                WHEN f.accepted_not_disb_submitted_flag = 1
                THEN 1 ELSE 0
            END
        ) AS active_accepted_not_submitted_cases,

        SUM(
            CASE
                WHEN f.submitted_not_received_flag = 1
                THEN 1 ELSE 0
            END
        ) AS active_submitted_not_received_cases,

        AVG(
            CASE
                WHEN f.accepted_not_disb_submitted_flag = 1
                 AND f.loan_acceptance_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     f.loan_acceptance_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    f.loan_acceptance_date
                )

                WHEN f.submitted_not_received_flag = 1
                 AND f.disbursement_submit_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     f.disbursement_submit_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    f.disbursement_submit_date
                )

                ELSE NULL
            END
        ) AS avg_active_waiting_days,

        MAX(
            CASE
                WHEN f.accepted_not_disb_submitted_flag = 1
                 AND f.loan_acceptance_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     f.loan_acceptance_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    f.loan_acceptance_date
                )

                WHEN f.submitted_not_received_flag = 1
                 AND f.disbursement_submit_date IS NOT NULL
                 AND DATEDIFF(
                     p.analysis_date,
                     f.disbursement_submit_date
                 ) >= 0
                THEN DATEDIFF(
                    p.analysis_date,
                    f.disbursement_submit_date
                )

                ELSE NULL
            END
        ) AS max_active_waiting_days

    FROM financing_classified f
    CROSS JOIN params p
    WHERE f.financing_queue = 'Active Financing Candidate Queue'
    GROUP BY f.store_name
),

/* 3. Count the three queues separately by store */
queue_counts AS (
    SELECT
        store_name,

        SUM(
            CASE
                WHEN financing_queue = 'Active Financing Candidate Queue'
                THEN 1 ELSE 0
            END
        ) AS active_candidate_queue_cases,

        SUM(
            CASE
                WHEN financing_queue = 'Historical Reconciliation Queue'
                THEN 1 ELSE 0
            END
        ) AS historical_reconciliation_cases,

        SUM(
            CASE
                WHEN financing_queue = 'Exception Review Queue'
                THEN 1 ELSE 0
            END
        ) AS exception_review_cases,

        SUM(
            CASE
                WHEN financing_queue = 'Unclassified Financing Exception'
                THEN 1 ELSE 0
            END
        ) AS unclassified_financing_exception_cases

    FROM financing_classified
    GROUP BY store_name
),

/* 4. Store-level business metrics; cancellation rate uses all orders */
store_metrics AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(s.store), ''),
            'Missing / Blank'
        ) AS store_name,

        COUNT(*) AS total_orders,

        SUM(
            CASE
                WHEN TRIM(COALESCE(s.order_status, ''))
                     = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) AS cancelled_orders

    FROM stg_orders s
    GROUP BY
        COALESCE(
            NULLIF(TRIM(s.store), ''),
            'Missing / Blank'
        )
),

/* 5. Combine store, queue, and waiting-time metrics */
combined_metrics AS (
    SELECT
        p.analysis_date,
        sm.store_name,
        sm.total_orders,
        sm.cancelled_orders,

        ROUND(
            100.0 * sm.cancelled_orders
            / NULLIF(sm.total_orders, 0),
            2
        ) AS cancellation_rate_pct,

        COALESCE(qc.active_candidate_queue_cases, 0)
            AS active_candidate_queue_cases,

        COALESCE(aq.active_accepted_not_submitted_cases, 0)
            AS active_accepted_not_submitted_cases,

        COALESCE(aq.active_submitted_not_received_cases, 0)
            AS active_submitted_not_received_cases,

        COALESCE(qc.historical_reconciliation_cases, 0)
            AS historical_reconciliation_cases,

        COALESCE(qc.exception_review_cases, 0)
            AS exception_review_cases,

        COALESCE(qc.unclassified_financing_exception_cases, 0)
            AS unclassified_financing_exception_cases,

        ROUND(aq.avg_active_waiting_days, 2)
            AS avg_active_waiting_days,

        aq.max_active_waiting_days

    FROM store_metrics sm
    CROSS JOIN params p
    LEFT JOIN queue_counts qc
        ON sm.store_name = qc.store_name
    LEFT JOIN active_queue_metrics aq
        ON sm.store_name = aq.store_name
),

/* 6. Apply cancellation risk, financing risk, and small-sample alert */
risk_scored AS (
    SELECT
        cm.*,

        CASE
            WHEN cancelled_orders >= 30
             AND cancellation_rate_pct >= 30
                THEN 'P1 - High Cancellation Risk'

            WHEN total_orders >= 30
             AND cancellation_rate_pct >= 40
                THEN 'P2 - Review Cancellation Risk'

            WHEN cancelled_orders >= 15
                THEN 'P2 - Review Cancellation Risk'

            ELSE 'P3 - Monitor Cancellation Risk'
        END AS cancellation_priority,

        CASE
            WHEN active_candidate_queue_cases >= 5
              OR max_active_waiting_days >= 30
                THEN 'P1 - High Financing Backlog'

            WHEN active_candidate_queue_cases >= 2
              OR max_active_waiting_days >= 14
                THEN 'P2 - Review Financing Backlog'

            ELSE 'P3 - Monitor Financing Backlog'
        END AS financing_backlog_priority,

        CASE
            WHEN total_orders < 30
             AND cancellation_rate_pct >= 40
                THEN 1
            ELSE 0
        END AS small_sample_high_cancellation_alert

    FROM combined_metrics cm
),

/* 7. Create a combined action recommendation */
final_scored AS (
    SELECT
        rs.*,

        
CASE
    WHEN small_sample_high_cancellation_alert = 1
     AND active_candidate_queue_cases >= 5
     AND exception_review_cases > 0
    THEN 'Investigate Active Financing, Exception and Small-Sample Cancellation'

    WHEN small_sample_high_cancellation_alert = 1
    THEN 'Review Small-Sample High Cancellation Rate'

    WHEN active_candidate_queue_cases >= 5
     AND exception_review_cases > 0
    THEN 'Investigate Active Financing Backlog and Exception'

    WHEN cancellation_priority = 'P1 - High Cancellation Risk'
     AND financing_backlog_priority = 'P1 - High Financing Backlog'
    THEN 'Investigate Cancellation and Financing Together'

    WHEN cancellation_priority = 'P1 - High Cancellation Risk'
    THEN 'Investigate Cancellation Drivers'

    WHEN financing_backlog_priority = 'P1 - High Financing Backlog'
     AND exception_review_cases > 0
    THEN 'Investigate Active Financing Backlog and Exception'

    WHEN financing_backlog_priority = 'P1 - High Financing Backlog'
    THEN 'Investigate Active Financing Backlog'

    WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
     AND financing_backlog_priority = 'P2 - Review Financing Backlog'
    THEN 'Review Both Risk Areas'

    WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
    THEN 'Review Cancellation Patterns'

    WHEN financing_backlog_priority = 'P2 - Review Financing Backlog'
    THEN 'Review Active Financing Backlog'

    WHEN exception_review_cases > 0
    THEN 'Review Financing Exceptions'

    WHEN historical_reconciliation_cases > 0
    THEN 'Review Historical Reconciliation'

    ELSE 'Routine Monitoring'
    
END AS investigation_action


    FROM risk_scored rs
)

/* 8. Final store-level report */
SELECT
    analysis_date,
    store_name,
    total_orders,
    cancelled_orders,
    cancellation_rate_pct,

    active_candidate_queue_cases,
    active_accepted_not_submitted_cases,
    active_submitted_not_received_cases,

    historical_reconciliation_cases,
    exception_review_cases,
    unclassified_financing_exception_cases,

    avg_active_waiting_days,
    max_active_waiting_days,

    cancellation_priority,
    financing_backlog_priority,

    small_sample_high_cancellation_alert,

    CASE
        WHEN avg_active_waiting_days IS NULL THEN 'N/A'
        ELSE CAST(avg_active_waiting_days AS CHAR)
    END AS avg_active_waiting_days_display,

    CASE
        WHEN max_active_waiting_days IS NULL THEN 'N/A'
        ELSE CAST(max_active_waiting_days AS CHAR)
    END AS max_active_waiting_days_display,

    investigation_action

FROM final_scored

ORDER BY
    CASE
        WHEN cancellation_priority = 'P1 - High Cancellation Risk'
        THEN 1
        WHEN cancellation_priority = 'P2 - Review Cancellation Risk'
        THEN 2
        ELSE 3
    END,

    CASE
        WHEN financing_backlog_priority = 'P1 - High Financing Backlog'
        THEN 1
        WHEN financing_backlog_priority = 'P2 - Review Financing Backlog'
        THEN 2
        ELSE 3
    END,

    active_candidate_queue_cases DESC,
    max_active_waiting_days DESC,
    cancelled_orders DESC;
    
    
    
    
    
    
USE carsome_orders_analysis;

WITH financing_classified AS (
    SELECT
        order_id,
        COALESCE(accepted_not_disb_submitted_flag, 0)
            AS accepted_not_disb_submitted_flag,
        COALESCE(submitted_not_received_flag, 0)
            AS submitted_not_received_flag,
        TRIM(COALESCE(order_status, '')) AS order_status,

        CASE
            WHEN TRIM(COALESCE(order_status, '')) = 'Money Back'
             AND (
                 COALESCE(accepted_not_disb_submitted_flag, 0) = 1
                 OR COALESCE(submitted_not_received_flag, 0) = 1
             )
                THEN 'Exception Review Queue'

            WHEN TRIM(COALESCE(order_status, '')) IN (
                'Order Completed',
                'Order Cancelled',
                'Order Closed'
            )
             AND (
                 COALESCE(accepted_not_disb_submitted_flag, 0) = 1
                 OR COALESCE(submitted_not_received_flag, 0) = 1
             )
                THEN 'Historical Reconciliation Queue'

            WHEN TRIM(COALESCE(order_status, '')) IN (
                'Pending E-hak Milik',
                'Pending Pay',
                'Pending Deliver'
            )
             AND (
                 COALESCE(accepted_not_disb_submitted_flag, 0) = 1
                 OR COALESCE(submitted_not_received_flag, 0) = 1
             )
                THEN 'Active Financing Candidate Queue'

            WHEN (
                 COALESCE(accepted_not_disb_submitted_flag, 0) = 1
                 OR COALESCE(submitted_not_received_flag, 0) = 1
            )
                THEN 'Unclassified Financing Exception'

            ELSE NULL
        END AS financing_queue

    FROM stg_orders
)

SELECT
    financing_queue,
    COUNT(*) AS source_rows,
    COUNT(DISTINCT order_id) AS distinct_orders
FROM financing_classified
WHERE financing_queue IS NOT NULL
GROUP BY financing_queue
ORDER BY financing_queue;


