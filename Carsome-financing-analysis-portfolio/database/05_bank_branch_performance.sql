
USE carsome_orders_analysis;

SELECT
    ORDINAL_POSITION,
    COLUMN_NAME,
    DATA_TYPE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'carsome_orders_analysis'
  AND TABLE_NAME = 'stg_orders'
  AND (
      LOWER(COLUMN_NAME) LIKE '%bank%'
      OR LOWER(COLUMN_NAME) LIKE '%branch%'
      OR LOWER(COLUMN_NAME) LIKE '%financier%'
      OR LOWER(COLUMN_NAME) LIKE '%finance%'
      OR LOWER(COLUMN_NAME) LIKE '%loan%'
      OR LOWER(COLUMN_NAME) LIKE '%disbursement%'
      OR LOWER(COLUMN_NAME) LIKE '%store%'
      OR LOWER(COLUMN_NAME) LIKE '%order_status%'
  )
ORDER BY ORDINAL_POSITION;





USE carsome_orders_analysis;

/* ============================================================
   05_bank_branch_performance.sql

   Analysis scope:
   1. Overall financier performance
   2. Financier x CARSOME store performance
   3. Financing stage conversion
   4. Disbursement waiting time

   Fixed snapshot date: 2026-10-13
   Source table: stg_orders

   Important:
   - Use original financing flags.
   - Do not treat CARSOME stores as bank branches.
   - This is descriptive analysis, not a causal assessment.
   ============================================================ */


/* ============================================================
   RESULT SET 1
   Overall performance by financier
   ============================================================ */

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS total_orders,

    SUM(CASE
        WHEN COALESCE(financing_case_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS financing_cases,

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
    END) AS disbursement_submitted_cases,

    SUM(CASE
        WHEN COALESCE(disbursement_received_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS disbursement_received_cases,

    SUM(CASE
        WHEN COALESCE(completed_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS completed_cases,

    ROUND(
        100.0 * SUM(CASE
            WHEN COALESCE(approved_flag, 0) = 1
            THEN 1 ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN COALESCE(financing_case_flag, 0) = 1
                THEN 1 ELSE 0
            END),
            0
        ),
        2
    ) AS approval_rate_pct,

    ROUND(
        100.0 * SUM(CASE
            WHEN COALESCE(accepted_flag, 0) = 1
            THEN 1 ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN COALESCE(approved_flag, 0) = 1
                THEN 1 ELSE 0
            END),
            0
        ),
        2
    ) AS acceptance_rate_pct,

    ROUND(
        100.0 * SUM(CASE
            WHEN COALESCE(disbursement_received_flag, 0) = 1
            THEN 1 ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN COALESCE(disbursement_submitted_flag, 0) = 1
                THEN 1 ELSE 0
            END),
            0
        ),
        2
    ) AS submission_to_received_rate_pct

FROM stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY financing_cases DESC;


/* ============================================================
   RESULT SET 2
   Financier x CARSOME store performance

   Store is the CARSOME sales/store dimension,
   not a bank branch dimension.
   ============================================================ */

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

    SUM(CASE
        WHEN COALESCE(financing_case_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS financing_cases,

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

    ROUND(
        100.0 * SUM(CASE
            WHEN COALESCE(disbursement_received_flag, 0) = 1
            THEN 1 ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN COALESCE(disbursement_submitted_flag, 0) = 1
                THEN 1 ELSE 0
            END),
            0
        ),
        2
    ) AS submission_to_received_rate_pct

FROM stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ),
    COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    )

ORDER BY
    financing_cases DESC,
    financier,
    carsome_store;


/* ============================================================
   RESULT SET 3
   Stage conversion by financier

   Conversion rates use the preceding stage as denominator.
   ============================================================ */

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    SUM(CASE
        WHEN COALESCE(financing_case_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS financing_cases,

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

    ROUND(
        100.0 * SUM(CASE
            WHEN COALESCE(approved_flag, 0) = 1
            THEN 1 ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN COALESCE(financing_case_flag, 0) = 1
                THEN 1 ELSE 0
            END),
            0
        ),
        2
    ) AS financing_to_approval_pct,

    ROUND(
        100.0 * SUM(CASE
            WHEN COALESCE(accepted_flag, 0) = 1
            THEN 1 ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN COALESCE(approved_flag, 0) = 1
                THEN 1 ELSE 0
            END),
            0
        ),
        2
    ) AS approval_to_acceptance_pct,

    ROUND(
        100.0 * SUM(CASE
            WHEN COALESCE(disbursement_submitted_flag, 0) = 1
            THEN 1 ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN COALESCE(accepted_flag, 0) = 1
                THEN 1 ELSE 0
            END),
            0
        ),
        2
    ) AS acceptance_to_submission_pct,

    ROUND(
        100.0 * SUM(CASE
            WHEN COALESCE(disbursement_received_flag, 0) = 1
            THEN 1 ELSE 0
        END)
        / NULLIF(
            SUM(CASE
                WHEN COALESCE(disbursement_submitted_flag, 0) = 1
                THEN 1 ELSE 0
            END),
            0
        ),
        2
    ) AS submission_to_received_pct

FROM stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY financing_cases DESC;


/* ============================================================
   RESULT SET 4
   Disbursement waiting time by financier

   Only cases with submitted flag = 1 and received flag = 0.
   Waiting days are calculated as of 2026-10-13.

   This is a reconciliation indicator, not confirmed SLA breach.
   ============================================================ */

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS submitted_not_received_cases,

    SUM(CASE
        WHEN disbursement_submit_date IS NOT NULL
        THEN 1 ELSE 0
    END) AS cases_with_submission_date,

    SUM(CASE
        WHEN disbursement_submit_date IS NULL
        THEN 1 ELSE 0
    END) AS cases_missing_submission_date,

    ROUND(
        AVG(
            CASE
                WHEN disbursement_submit_date IS NOT NULL
                 AND DATEDIFF(
                     DATE('2026-10-13'),
                     DATE(disbursement_submit_date)
                 ) >= 0
                THEN DATEDIFF(
                    DATE('2026-10-13'),
                    DATE(disbursement_submit_date)
                )
            END
        ),
        2
    ) AS avg_wait_days,

    MAX(
        CASE
            WHEN disbursement_submit_date IS NOT NULL
             AND DATEDIFF(
                 DATE('2026-10-13'),
                 DATE(disbursement_submit_date)
             ) >= 0
            THEN DATEDIFF(
                DATE('2026-10-13'),
                DATE(disbursement_submit_date)
            )
        END
    ) AS max_wait_days,

    SUM(CASE
        WHEN disbursement_submit_date IS NOT NULL
         AND DATEDIFF(
             DATE('2026-10-13'),
             DATE(disbursement_submit_date)
         ) BETWEEN 0 AND 7
        THEN 1 ELSE 0
    END) AS wait_0_to_7_days,

    SUM(CASE
        WHEN disbursement_submit_date IS NOT NULL
         AND DATEDIFF(
             DATE('2026-10-13'),
             DATE(disbursement_submit_date)
         ) BETWEEN 8 AND 14
        THEN 1 ELSE 0
    END) AS wait_8_to_14_days,

    SUM(CASE
        WHEN disbursement_submit_date IS NOT NULL
         AND DATEDIFF(
             DATE('2026-10-13'),
             DATE(disbursement_submit_date)
         ) BETWEEN 15 AND 30
        THEN 1 ELSE 0
    END) AS wait_15_to_30_days,

    SUM(CASE
        WHEN disbursement_submit_date IS NOT NULL
         AND DATEDIFF(
             DATE('2026-10-13'),
             DATE(disbursement_submit_date)
         ) > 30
        THEN 1 ELSE 0
    END) AS wait_over_30_days

FROM stg_orders

WHERE COALESCE(disbursement_submitted_flag, 0) = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY
    submitted_not_received_cases DESC,
    max_wait_days DESC;




USE carsome_orders_analysis;

SELECT
    CASE
        WHEN final_financier IS NULL
          OR TRIM(final_financier) = ''
        THEN 'Missing / Blank'
        ELSE 'Financier Identified'
    END AS financier_field_status,

    COUNT(*) AS total_orders,

    SUM(CASE WHEN COALESCE(financing_case_flag, 0) = 1
        THEN 1 ELSE 0 END) AS financing_cases,

    SUM(CASE WHEN COALESCE(approved_flag, 0) = 1
        THEN 1 ELSE 0 END) AS approved_cases,

    SUM(CASE WHEN COALESCE(accepted_flag, 0) = 1
        THEN 1 ELSE 0 END) AS accepted_cases,

    SUM(CASE WHEN COALESCE(disbursement_submitted_flag, 0) = 1
        THEN 1 ELSE 0 END) AS submitted_cases,

    SUM(CASE WHEN COALESCE(disbursement_received_flag, 0) = 1
        THEN 1 ELSE 0 END) AS received_cases,

    SUM(CASE WHEN COALESCE(completed_flag, 0) = 1
        THEN 1 ELSE 0 END) AS completed_cases

FROM stg_orders

GROUP BY
    CASE
        WHEN final_financier IS NULL
          OR TRIM(final_financier) = ''
        THEN 'Missing / Blank'
        ELSE 'Financier Identified'
    END

ORDER BY financier_field_status;
);



USE carsome_orders_analysis;

SELECT
    order_status,

    CASE
        WHEN final_financier IS NULL
          OR TRIM(final_financier) = ''
        THEN 'Missing / Blank'
        ELSE final_financier
    END AS financier_status,

    COALESCE(financing_case_flag, 0) AS financing_case_flag,
    COALESCE(approved_flag, 0) AS approved_flag,
    COALESCE(accepted_flag, 0) AS accepted_flag,
    COALESCE(disbursement_submitted_flag, 0)
        AS disbursement_submitted_flag,
    COALESCE(disbursement_received_flag, 0)
        AS disbursement_received_flag,
    COALESCE(completed_flag, 0) AS completed_flag,

    COUNT(*) AS order_count

FROM stg_orders

WHERE
    COALESCE(completed_flag, 0) = 1
    AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    order_status,
    CASE
        WHEN final_financier IS NULL
          OR TRIM(final_financier) = ''
        THEN 'Missing / Blank'
        ELSE final_financier
    END,
    COALESCE(financing_case_flag, 0),
    COALESCE(approved_flag, 0),
    COALESCE(accepted_flag, 0),
    COALESCE(disbursement_submitted_flag, 0),
    COALESCE(disbursement_received_flag, 0),
    COALESCE(completed_flag, 0)

ORDER BY order_count DESC;


USE carsome_orders_analysis;

SELECT
    order_status,

    CASE
        WHEN final_financier IS NULL
          OR TRIM(final_financier) = ''
        THEN 'Missing / Blank'
        ELSE final_financier
    END AS financier_status,

    COALESCE(disbursement_submitted_flag, 0)
        AS disbursement_submitted_flag,

    COALESCE(disbursement_received_flag, 0)
        AS disbursement_received_flag,

    COALESCE(completed_flag, 0)
        AS completed_flag,

    COUNT(*) AS order_count,

    SUM(
        CASE
            WHEN disbursement_submit_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_submission_date,

    SUM(
        CASE
            WHEN disbursement_slip_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_disbursement_slip_date,

    SUM(
        CASE
            WHEN disbursement_receive_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_receive_date

FROM stg_orders

WHERE COALESCE(completed_flag, 0) = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    order_status,

    CASE
        WHEN final_financier IS NULL
          OR TRIM(final_financier) = ''
        THEN 'Missing / Blank'
        ELSE final_financier
    END,

    COALESCE(disbursement_submitted_flag, 0),
    COALESCE(disbursement_received_flag, 0),
    COALESCE(completed_flag, 0)

ORDER BY order_count DESC;



USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS completed_without_received_cases,

    SUM(
        CASE
            WHEN disbursement_submit_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_submission_date,

    SUM(
        CASE
            WHEN disbursement_submit_date IS NULL
            THEN 1 ELSE 0
        END
    ) AS missing_submission_date,

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

    MIN(disbursement_submit_date) AS earliest_submission_date,

    MAX(disbursement_submit_date) AS latest_submission_date

FROM stg_orders

WHERE COALESCE(completed_flag, 0) = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY completed_without_received_cases DESC;





USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    order_status,

    COALESCE(financing_case_flag, 0)
        AS financing_case_flag,

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

    COUNT(*) AS case_count,

    SUM(
        CASE
            WHEN disbursement_submit_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_submission_date,

    SUM(
        CASE
            WHEN disbursement_receive_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_receive_date

FROM stg_orders

WHERE
    (
        COALESCE(completed_flag, 0) = 1
        AND COALESCE(disbursement_received_flag, 0) = 0
    )
    OR
    (
        COALESCE(disbursement_submitted_flag, 0) = 1
        AND COALESCE(disbursement_received_flag, 0) = 0
    )

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ),
    order_status,
    COALESCE(financing_case_flag, 0),
    COALESCE(approved_flag, 0),
    COALESCE(accepted_flag, 0),
    COALESCE(disbursement_submitted_flag, 0),
    COALESCE(disbursement_received_flag, 0),
    COALESCE(completed_flag, 0)

ORDER BY
    case_count DESC,
    financier,
    order_status;



USE carsome_orders_analysis;

/* ============================================================
   05_bank_branch_performance.sql
   Fixed snapshot date: 2026-10-13
   Source: stg_orders

   Scope:
   1. Overall financier performance
   2. Financier x CARSOME store performance
   3. Financing stage conversion
   4. Historical reconciliation queue
   5. Exception review queue

   Important:
   - Original flags are not modified.
   - CARSOME store is not a bank branch.
   - Completion status is not equivalent to disbursement receipt.
   - Rates are descriptive and require business interpretation.
   ============================================================ */


/* ============================================================
   RESULT 1: Overall financier performance
   ============================================================ */

SELECT
    '2026-10-13' AS snapshot_date,

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

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
        AS completed_cases,

    ROUND(
        100.0 * SUM(COALESCE(approved_flag, 0))
        / NULLIF(SUM(COALESCE(financing_case_flag, 0)), 0),
        2
    ) AS financing_to_approval_pct,

    ROUND(
        100.0 * SUM(COALESCE(accepted_flag, 0))
        / NULLIF(SUM(COALESCE(approved_flag, 0)), 0),
        2
    ) AS approval_to_acceptance_pct,

    ROUND(
        100.0 * SUM(COALESCE(disbursement_received_flag, 0))
        / NULLIF(SUM(COALESCE(disbursement_submitted_flag, 0)), 0),
        2
    ) AS submission_to_received_pct,

    SUM(
        CASE
            WHEN COALESCE(completed_flag, 0) = 1
             AND COALESCE(disbursement_received_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS completed_without_received_flag,

    'Descriptive only; financier assignment may be stage-dependent'
        AS interpretation_note

FROM stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY financing_cases DESC;


/* ============================================================
   RESULT 2: Financier x CARSOME store performance
   Store is not a bank branch.
   ============================================================ */

SELECT
    '2026-10-13' AS snapshot_date,

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    ) AS carsome_store,

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

    ROUND(
        100.0 * SUM(COALESCE(disbursement_received_flag, 0))
        / NULLIF(SUM(COALESCE(disbursement_submitted_flag, 0)), 0),
        2
    ) AS submission_to_received_pct

FROM stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ),
    COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    )

ORDER BY financing_cases DESC, financier, carsome_store;


/* ============================================================
   RESULT 3: Financing stage conversion
   Ratios are flag-based, not necessarily cohort conversion rates.
   ============================================================ */

SELECT
    '2026-10-13' AS snapshot_date,

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

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

    ROUND(
        100.0 * SUM(COALESCE(approved_flag, 0))
        / NULLIF(SUM(COALESCE(financing_case_flag, 0)), 0),
        2
    ) AS financing_to_approval_pct,

    ROUND(
        100.0 * SUM(COALESCE(accepted_flag, 0))
        / NULLIF(SUM(COALESCE(approved_flag, 0)), 0),
        2
    ) AS approval_to_acceptance_pct,

    ROUND(
        100.0 * SUM(COALESCE(disbursement_submitted_flag, 0))
        / NULLIF(SUM(COALESCE(accepted_flag, 0)), 0),
        2
    ) AS acceptance_to_submission_pct,

    ROUND(
        100.0 * SUM(COALESCE(disbursement_received_flag, 0))
        / NULLIF(SUM(COALESCE(disbursement_submitted_flag, 0)), 0),
        2
    ) AS submission_to_received_pct

FROM stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY financing_cases DESC;


/* ============================================================
   RESULT 4: Historical reconciliation queue
   Queue definition:
   Completed OR Closed, with no received flag.
   This is a review queue, not confirmed bank failure.
   ============================================================ */

SELECT
    '2026-10-13' AS snapshot_date,

    'Historical Reconciliation Queue' AS queue_type,

    order_status,

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    ) AS loan_type,

    COUNT(*) AS case_count,

    SUM(COALESCE(financing_case_flag, 0))
        AS financing_cases,

    SUM(COALESCE(approved_flag, 0))
        AS approved_cases,

    SUM(COALESCE(accepted_flag, 0))
        AS accepted_cases,

    SUM(COALESCE(disbursement_submitted_flag, 0))
        AS submitted_cases,

    SUM(
        CASE
            WHEN disbursement_submit_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_submission_date,

    SUM(
        CASE
            WHEN disbursement_receive_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_receive_date,

    MIN(disbursement_submit_date)
        AS earliest_submission_date,

    MAX(disbursement_submit_date)
        AS latest_submission_date,

    'Reconcile status and source records; do not infer bank failure'
        AS review_note

FROM stg_orders

WHERE TRIM(COALESCE(order_status, '')) IN (
    'Order Completed',
    'Order Closed'
)
AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    order_status,

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ),

    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    )

ORDER BY case_count DESC, financier;


/* ============================================================
   RESULT 5: Exception review queue
   Exception statuses are separated from historical queues.
   ============================================================ */

SELECT
    '2026-10-13' AS snapshot_date,

    'Exception Review Queue' AS queue_type,

    order_status,

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    ) AS loan_type,

    COUNT(*) AS case_count,

    SUM(COALESCE(financing_case_flag, 0))
        AS financing_cases,

    SUM(COALESCE(approved_flag, 0))
        AS approved_cases,

    SUM(COALESCE(accepted_flag, 0))
        AS accepted_cases,

    SUM(COALESCE(disbursement_submitted_flag, 0))
        AS submitted_cases,

    SUM(
        CASE
            WHEN disbursement_submit_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_submission_date,

    SUM(
        CASE
            WHEN disbursement_receive_date IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS has_receive_date,

    'Manual business review required'
        AS review_note

FROM stg_orders

WHERE TRIM(COALESCE(order_status, '')) IN (
    'Money Back',
    'Pending Deliver'
)
AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    order_status,

    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ),

    COALESCE(
        NULLIF(TRIM(final_loan_type), ''),
        'Missing / Blank'
    )

ORDER BY case_count DESC, financier;





USE carsome_orders_analysis;

-- =========================================================
-- 05A. Global Consistency Audit
-- Purpose: Audit order statuses, financing flags,
--          disbursement flags and missing financier values.
-- Read-only; does not modify stg_orders.
-- =========================================================


-- RESULT 1: Overall order status distribution
-- Check the relationship between business status and flags.

SELECT
    TRIM(COALESCE(order_status, 'Missing / Blank')) AS order_status,
    COUNT(*) AS total_records,

    SUM(CASE
        WHEN COALESCE(financing_case_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS financing_cases,

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

FROM stg_orders
GROUP BY TRIM(COALESCE(order_status, 'Missing / Blank'))
ORDER BY total_records DESC;


-- RESULT 2: Completed orders without received flag
-- Determine whether completed status and disbursement
-- receipt indicators disagree.

SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,

    COALESCE(NULLIF(TRIM(final_loan_type), ''),
             'Missing / Blank') AS loan_type,

    COUNT(*) AS case_count,

    SUM(CASE
        WHEN disbursement_submit_date IS NOT NULL
        THEN 1 ELSE 0
    END) AS has_submission_date,

    SUM(CASE
        WHEN disbursement_receive_date IS NOT NULL
        THEN 1 ELSE 0
    END) AS has_receive_date,

    SUM(CASE
        WHEN disbursement_slip_date IS NOT NULL
        THEN 1 ELSE 0
    END) AS has_slip_date,

    SUM(CASE
        WHEN COALESCE(disbursement_submitted_flag, 0) = 1
         AND disbursement_submit_date IS NULL
        THEN 1 ELSE 0
    END) AS submitted_flag_without_date,

    SUM(CASE
        WHEN COALESCE(disbursement_received_flag, 0) = 1
         AND disbursement_receive_date IS NULL
        THEN 1 ELSE 0
    END) AS received_flag_without_date

FROM stg_orders
WHERE TRIM(COALESCE(order_status, '')) = 'Order Completed'
  AND COALESCE(completed_flag, 0) = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank'),
    COALESCE(NULLIF(TRIM(final_loan_type), ''),
             'Missing / Blank')

ORDER BY case_count DESC, financier;


-- RESULT 3: Missing financier breakdown
-- Distinguish different order stages among records
-- whose final_financier is missing or blank.

SELECT
    TRIM(COALESCE(order_status, 'Missing / Blank'))
        AS order_status,

    COUNT(*) AS total_records,

    SUM(CASE
        WHEN COALESCE(financing_case_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS financing_cases,

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

FROM stg_orders
WHERE final_financier IS NULL
   OR TRIM(final_financier) = ''

GROUP BY TRIM(COALESCE(order_status, 'Missing / Blank'))
ORDER BY total_records DESC;


-- RESULT 4: Date and flag inconsistencies
-- Check whether a flag is set without its corresponding date,
-- or a date exists while the corresponding flag is zero.

SELECT
    'Submitted flag = 1 but submission date is NULL'
        AS audit_issue,
    COUNT(*) AS case_count
FROM stg_orders
WHERE COALESCE(disbursement_submitted_flag, 0) = 1
  AND disbursement_submit_date IS NULL

UNION ALL

SELECT
    'Submission date exists but submitted flag = 0',
    COUNT(*)
FROM stg_orders
WHERE disbursement_submit_date IS NOT NULL
  AND COALESCE(disbursement_submitted_flag, 0) = 0

UNION ALL

SELECT
    'Received flag = 1 but receive date is NULL',
    COUNT(*)
FROM stg_orders
WHERE COALESCE(disbursement_received_flag, 0) = 1
  AND disbursement_receive_date IS NULL

UNION ALL

SELECT
    'Receive date exists but received flag = 0',
    COUNT(*)
FROM stg_orders
WHERE disbursement_receive_date IS NOT NULL
  AND COALESCE(disbursement_received_flag, 0) = 0

UNION ALL

SELECT
    'Completed flag = 1 but order status is not Order Completed',
    COUNT(*)
FROM stg_orders
WHERE COALESCE(completed_flag, 0) = 1
  AND TRIM(COALESCE(order_status, '')) <> 'Order Completed'

UNION ALL

SELECT
    'Order Completed but completed flag = 0',
    COUNT(*)
FROM stg_orders
WHERE TRIM(COALESCE(order_status, '')) = 'Order Completed'
  AND COALESCE(completed_flag, 0) = 0;


-- RESULT 5: Detailed completed-order exceptions
-- Retain case-level identifiers for internal investigation.
-- Do not share identifiable records in a public portfolio.

SELECT
    order_id,
    summarised_order_id,
    order_status,

    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,

    COALESCE(NULLIF(TRIM(final_loan_type), ''),
             'Missing / Blank') AS loan_type,

    financing_case_flag,
    approved_flag,
    accepted_flag,
    disbursement_submitted_flag,
    disbursement_received_flag,
    completed_flag,

    disbursement_submit_date,
    disbursement_slip_date,
    disbursement_receive_date

FROM stg_orders
WHERE TRIM(COALESCE(order_status, '')) = 'Order Completed'
  AND COALESCE(completed_flag, 0) = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

ORDER BY
    final_financier,
    disbursement_submit_date;





USE carsome_orders_analysis;

-- Audit A: Received flag = 1 but receive date is NULL
SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,
    COALESCE(NULLIF(TRIM(final_loan_type), ''),
             'Missing / Blank') AS loan_type,
    TRIM(COALESCE(order_status, 'Missing / Blank'))
        AS order_status,
    COUNT(*) AS case_count,
    SUM(CASE
        WHEN COALESCE(completed_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS completed_cases,
    SUM(CASE
        WHEN COALESCE(disbursement_submitted_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS submitted_cases,
    SUM(CASE
        WHEN disbursement_submit_date IS NOT NULL
        THEN 1 ELSE 0
    END) AS has_submission_date
FROM stg_orders
WHERE COALESCE(disbursement_received_flag, 0) = 1
  AND disbursement_receive_date IS NULL
GROUP BY
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank'),
    COALESCE(NULLIF(TRIM(final_loan_type), ''),
             'Missing / Blank'),
    TRIM(COALESCE(order_status, 'Missing / Blank'))
ORDER BY case_count DESC, financier;


-- Audit B: Submitted flag = 1 but submission date is NULL
SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,
    COALESCE(NULLIF(TRIM(final_loan_type), ''),
             'Missing / Blank') AS loan_type,
    TRIM(COALESCE(order_status, 'Missing / Blank'))
        AS order_status,
    COUNT(*) AS case_count,
    SUM(CASE
        WHEN COALESCE(disbursement_received_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS received_cases,
    SUM(CASE
        WHEN COALESCE(completed_flag, 0) = 1
        THEN 1 ELSE 0
    END) AS completed_cases
FROM stg_orders
WHERE COALESCE(disbursement_submitted_flag, 0) = 1
  AND disbursement_submit_date IS NULL
GROUP BY
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank'),
    COALESCE(NULLIF(TRIM(final_loan_type), ''),
             'Missing / Blank'),
    TRIM(COALESCE(order_status, 'Missing / Blank'))
ORDER BY case_count DESC, financier;
