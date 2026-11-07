
-- ============================================================
-- File: 03_cancellation_analysis.sql
-- Purpose: Cancellation Analysis
-- Source: stg_orders_v2
-- ============================================================

USE carsome_orders_analysis;


-- Query 1A: Cancellation Overview

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct,

    SUM(
        CASE
            WHEN TRIM(order_status) <> 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS non_cancelled_orders

FROM stg_orders_v2;


-- Query 1B: Cancellation by Financing Case Flag

SELECT
    CASE
        WHEN financing_case_flag = 1
            THEN 'Financing Case'
        WHEN financing_case_flag = 0
            THEN 'Non-financing Case'
        ELSE 'Unknown'
    END AS financing_group,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM stg_orders_v2

GROUP BY
    CASE
        WHEN financing_case_flag = 1
            THEN 'Financing Case'
        WHEN financing_case_flag = 0
            THEN 'Non-financing Case'
        ELSE 'Unknown'
    END

ORDER BY total_orders DESC;
);




-- Query 2A: Overall order status distribution

SELECT
    order_status,
    COUNT(*) AS total_cases,
    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM stg_orders_v2),
        2
    ) AS pct_of_all_orders
FROM stg_orders_v2
GROUP BY order_status
ORDER BY total_cases DESC;


-- Query 2B: Financing status among cancelled orders

SELECT
    COALESCE(final_loan_status, 'Missing / Blank')
        AS final_loan_status,
    COALESCE(disbursement_status, 'Missing / Blank')
        AS disbursement_status,
    COUNT(*) AS cancelled_cases,
    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM stg_orders_v2
            WHERE TRIM(order_status) = 'Order Cancelled'
        ),
        2
    ) AS pct_of_cancelled_orders
FROM stg_orders_v2
WHERE TRIM(order_status) = 'Order Cancelled'
GROUP BY
    COALESCE(final_loan_status, 'Missing / Blank'),
    COALESCE(disbursement_status, 'Missing / Blank')
ORDER BY cancelled_cases DESC;


-- Query 3A: Cancelled orders by final financier

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS cancelled_cases,

    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM stg_orders_v2
            WHERE TRIM(order_status) = 'Order Cancelled'
        ),
        2
    ) AS pct_of_cancelled_orders

FROM stg_orders_v2
WHERE TRIM(order_status) = 'Order Cancelled'

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY cancelled_cases DESC;


-- Query 3B: Cancellation rate by final financier

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_cases,

    ROUND(
        SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM stg_orders_v2

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY cancelled_cases DESC;


USE carsome_orders_analysis;

-- Query 4A: Inspect the columns available in stg_orders_v2

SHOW COLUMNS FROM stg_orders_v2;


-- Query 4B: Inspect the columns available in the original staging table

SHOW COLUMNS FROM stg_orders;


USE carsome_orders_analysis;

-- Query 4A: Validate cancellation counts in the original staging table

SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_order_ids,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    COUNT(
        DISTINCT CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN order_id
        END
    ) AS unique_cancelled_orders

FROM stg_orders;


-- Query 4B: Cancellation volume and rate by store

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
    ) AS cancellation_rate_pct

FROM stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(store), ''),
        'Missing / Blank'
    )

ORDER BY cancelled_orders DESC
LIMIT 20;


-- Query 4C: Inspect remarks among cancelled orders

SELECT
    COALESCE(
        NULLIF(TRIM(final_status_remark), ''),
        'Missing / Blank'
    ) AS final_status_remark,

    COUNT(*) AS cancelled_cases

FROM stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_status_remark), ''),
        'Missing / Blank'
    )

ORDER BY cancelled_cases DESC
LIMIT 30;



USE carsome_orders_analysis;

-- Query 5A: Financing and disbursement status
-- among cancelled orders at high-volume / high-rate stores

SELECT
    store,
    COALESCE(final_loan_status, 'Missing / Blank')
        AS final_loan_status,
    COALESCE(disbursement_status, 'Missing / Blank')
        AS disbursement_status,
    COUNT(*) AS cancelled_cases

FROM stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'
  AND store IN (
      'CARSOME PJ Automall',
      'CARSOME Showroom Kuching',
      'CARSOME Showroom Sunsuria Setia Alam',
      'CARSOME Showroom AEON BiG Kepong',
      'CARSOME Showroom Bukit Tinggi Klang'
  )

GROUP BY
    store,
    COALESCE(final_loan_status, 'Missing / Blank'),
    COALESCE(disbursement_status, 'Missing / Blank')

ORDER BY store, cancelled_cases DESC;


-- Query 5B: Most frequent non-empty remarks
-- among cancelled orders

SELECT
    TRIM(final_status_remark) AS remark,
    COUNT(*) AS cancelled_cases

FROM stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'
  AND NULLIF(TRIM(final_status_remark), '') IS NOT NULL

GROUP BY TRIM(final_status_remark)

ORDER BY cancelled_cases DESC
LIMIT 30;


USE carsome_orders_analysis;

SHOW COLUMNS FROM stg_orders_v2;



USE carsome_orders_analysis;

SELECT
    CASE
        WHEN financing_case_flag = 1
            THEN 'Financing Case'
        ELSE 'Non-financing Case'
    END AS financing_group,

    COALESCE(final_loan_status, 'Missing / Blank')
        AS final_loan_status,

    COALESCE(disbursement_status, 'Missing / Blank')
        AS disbursement_status,

    COUNT(*) AS cancelled_cases,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_cancelled_orders

FROM stg_orders_v2
WHERE TRIM(order_status) = 'Order Cancelled'

GROUP BY
    financing_group,
    COALESCE(final_loan_status, 'Missing / Blank'),
    COALESCE(disbursement_status, 'Missing / Blank')

ORDER BY cancelled_cases DESC;



-- 03. Store-level cancellation analysis

SELECT
    COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank')
        AS store,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1
            ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM carsome_orders_analysis.stg_orders

GROUP BY
    COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank')

HAVING COUNT(*) >= 20

ORDER BY
    cancellation_rate_pct DESC,
    cancelled_orders DESC;



-- 03. Bank-level cancellation analysis

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1
            ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1
                ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM carsome_orders_analysis.stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

HAVING COUNT(*) >= 10

ORDER BY
    cancellation_rate_pct DESC,
    cancelled_orders DESC;


-- 03. Cancellation remark overview

SELECT
    CASE
        WHEN final_status_remark IS NULL
             OR TRIM(final_status_remark) = ''
        THEN 'Missing / Blank'
        ELSE 'Has Remark'
    END AS remark_status,

    COUNT(*) AS cancelled_cases,

    ROUND(
        100.0 * COUNT(*) /
        (SELECT COUNT(*)
         FROM carsome_orders_analysis.stg_orders
         WHERE TRIM(order_status) = 'Order Cancelled'),
        2
    ) AS pct_of_cancelled_orders

FROM carsome_orders_analysis.stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'

GROUP BY
    CASE
        WHEN final_status_remark IS NULL
             OR TRIM(final_status_remark) = ''
        THEN 'Missing / Blank'
        ELSE 'Has Remark'
    END

ORDER BY cancelled_cases DESC;

)

-- Most frequent cancellation remarks

SELECT
    TRIM(final_status_remark) AS remark,
    COUNT(*) AS cancelled_cases

FROM carsome_orders_analysis.stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'
  AND final_status_remark IS NOT NULL
  AND TRIM(final_status_remark) <> ''

GROUP BY TRIM(final_status_remark)

ORDER BY cancelled_cases DESC

LIMIT 30;


-- Check whether historical status fields exist
SHOW COLUMNS
FROM carsome_orders_analysis.stg_orders;



-- 03. Cancellation analysis: financing stage

SELECT
    CASE
        WHEN COALESCE(financing_case_flag, 0) = 0
            THEN 'Non-financing Case'

        WHEN COALESCE(approved_flag, 0) = 1
             AND COALESCE(accepted_flag, 0) = 0
            THEN 'Approved but Not Accepted'

        WHEN COALESCE(accepted_flag, 0) = 1
             AND COALESCE(disbursement_submitted_flag, 0) = 0
            THEN 'Accepted but Not Submitted'

        WHEN COALESCE(disbursement_submitted_flag, 0) = 1
             AND COALESCE(disbursement_received_flag, 0) = 0
            THEN 'Submitted but Not Received'

        WHEN COALESCE(disbursement_received_flag, 0) = 1
            THEN 'Disbursement Received'

        ELSE 'Financing Case - Other Stage'
    END AS financing_stage,

    COUNT(*) AS cancelled_orders,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_cancelled_orders

FROM carsome_orders_analysis.stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'

GROUP BY financing_stage

ORDER BY cancelled_orders DESC;



-- 03. Cancellation analysis
-- Investigate the "Other Stage" group

SELECT
    COALESCE(NULLIF(TRIM(order_status), ''), 'Missing / Blank')
        AS order_status,

    COALESCE(NULLIF(TRIM(final_loan_status), ''), 'Missing / Blank')
        AS final_loan_status,

    COALESCE(NULLIF(TRIM(disbursement_status), ''), 'Missing / Blank')
        AS disbursement_status,

    COUNT(*) AS cancelled_orders

FROM carsome_orders_analysis.stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'

  AND COALESCE(financing_case_flag, 0) = 1

  AND COALESCE(approved_flag, 0) = 0
  AND COALESCE(accepted_flag, 0) = 0
  AND COALESCE(disbursement_submitted_flag, 0) = 0
  AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    order_status,
    final_loan_status,
    disbursement_status

ORDER BY cancelled_orders DESC;



SELECT
    COUNT(*) AS cancelled_financing_orders,

    SUM(
        CASE
            WHEN loan_submission_date1 IS NOT NULL
              OR loan_submission_date2 IS NOT NULL
              OR loan_submission_date3 IS NOT NULL
              OR loan_submission_date4 IS NOT NULL
              OR loan_submission_date5 IS NOT NULL
            THEN 1 ELSE 0
        END
    ) AS with_submission_date,

    SUM(
        CASE
            WHEN loan_submission_date1 IS NULL
             AND loan_submission_date2 IS NULL
             AND loan_submission_date3 IS NULL
             AND loan_submission_date4 IS NULL
             AND loan_submission_date5 IS NULL
            THEN 1 ELSE 0
        END
    ) AS without_submission_date,

    SUM(CASE WHEN approved_flag = 1 THEN 1 ELSE 0 END)
        AS approved_flag_cases,

    SUM(CASE WHEN accepted_flag = 1 THEN 1 ELSE 0 END)
        AS accepted_flag_cases

FROM carsome_orders_analysis.stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'
  AND COALESCE(financing_case_flag, 0) = 1
  AND COALESCE(approved_flag, 0) = 0
  AND COALESCE(accepted_flag, 0) = 0
  AND COALESCE(disbursement_submitted_flag, 0) = 0
  AND COALESCE(disbursement_received_flag, 0) = 0;



SELECT
    submission_round_count,
    final_loan_status,
    disbursement_status,
    COUNT(*) AS cancelled_cases
FROM carsome_orders_analysis.stg_orders_v2
WHERE TRIM(order_status) = 'Order Cancelled'
  AND COALESCE(financing_case_flag, 0) = 1
GROUP BY
    submission_round_count,
    final_loan_status,
    disbursement_status
ORDER BY cancelled_cases DESC;


SELECT
    COALESCE(CAST(submission_round_count AS CHAR), 'Unknown')
        AS submission_round,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS cancellation_rate_pct

FROM carsome_orders_analysis.stg_orders_v2

GROUP BY submission_round_count
ORDER BY submission_round_count;



SELECT
    TRIM(order_status) AS order_status,
    COALESCE(
        NULLIF(TRIM(final_loan_status), ''),
        'Missing / Blank'
    ) AS final_loan_status,
    COALESCE(
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    ) AS disbursement_status,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders
FROM carsome_orders_analysis.stg_orders_v2
WHERE COALESCE(submission_round_count, 0) = 0
GROUP BY
    TRIM(order_status),
    COALESCE(
        NULLIF(TRIM(final_loan_status), ''),
        'Missing / Blank'
    ),
    COALESCE(
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    )
ORDER BY total_orders DESC;



SELECT
    CASE
        WHEN final_status_remark IS NULL
          OR TRIM(final_status_remark) = ''
        THEN 'Missing / Blank'
        ELSE 'Has Remark'
    END AS remark_status,

    COUNT(*) AS cancelled_orders,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_cancelled_orders

FROM carsome_orders_analysis.stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'

GROUP BY
    CASE
        WHEN final_status_remark IS NULL
          OR TRIM(final_status_remark) = ''
        THEN 'Missing / Blank'
        ELSE 'Has Remark'
    END

ORDER BY cancelled_orders DESC;


SELECT
    store,
    final_loan_status,
    disbursement_status,
    final_status_remark
FROM carsome_orders_analysis.stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'
  AND final_status_remark IS NOT NULL
  AND TRIM(final_status_remark) <> ''
ORDER BY store;


SHOW COLUMNS
FROM carsome_orders_analysis.stg_orders;


USE carsome_orders_analysis;

SELECT
    COUNT(*) AS total_orders,

    COUNT(loan_amount) AS loan_amount_non_null,
    COUNT(DISTINCT loan_amount) AS loan_amount_distinct_values,
    MIN(loan_amount) AS loan_amount_min,
    MAX(loan_amount) AS loan_amount_max,
    ROUND(AVG(loan_amount), 2) AS loan_amount_avg,

    COUNT(fis___loan) AS fis_loan_non_null,
    COUNT(DISTINCT fis___loan) AS fis_loan_distinct_values,
    MIN(fis___loan) AS fis_loan_min,
    MAX(fis___loan) AS fis_loan_max,
    ROUND(AVG(fis___loan), 2) AS fis_loan_avg

FROM stg_orders;


SELECT
    order_status,
    final_loan_status,
    COUNT(*) AS total_cases,
    COUNT(fis___loan) AS non_null_fis_loan,
    MIN(fis___loan) AS min_fis_loan,
    MAX(fis___loan) AS max_fis_loan,
    COUNT(DISTINCT fis___loan) AS distinct_fis_loan_values
FROM carsome_orders_analysis.stg_orders
GROUP BY
    order_status,
    final_loan_status
ORDER BY total_cases DESC;



SELECT
    CASE
        WHEN loan_amount IS NULL THEN 'Missing Loan Amount'
        ELSE 'Has Loan Amount'
    END AS loan_amount_group,

    CASE
        WHEN final_status_remark IS NULL
          OR TRIM(final_status_remark) = ''
            THEN 'Missing / Blank Remark'
        ELSE 'Has Remark'
    END AS remark_group,

    COUNT(*) AS total_cases

FROM carsome_orders_analysis.stg_orders
GROUP BY
    loan_amount_group,
    remark_group
ORDER BY total_cases DESC;



USE carsome_orders_analysis;

SELECT
    submission_round,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct
FROM (
    SELECT
        order_status,
        CASE
            WHEN loan_submission_date5 IS NOT NULL THEN 5
            WHEN loan_submission_date4 IS NOT NULL THEN 4
            WHEN loan_submission_date3 IS NOT NULL THEN 3
            WHEN loan_submission_date2 IS NOT NULL THEN 2
            WHEN loan_submission_date1 IS NOT NULL THEN 1
            ELSE 0
        END AS submission_round
    FROM stg_orders
    WHERE financing_case_flag = 1
) AS order_rounds
GROUP BY submission_round
ORDER BY submission_round;


USE carsome_orders_analysis;

SELECT
    TRIM(final_financier) AS financier,
    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM stg_orders
WHERE final_financier IS NOT NULL
  AND TRIM(final_financier) <> ''
GROUP BY TRIM(final_financier)
ORDER BY cancellation_rate_pct DESC, total_orders DESC;


USE carsome_orders_analysis;

SELECT
    store,
    COUNT(*) AS cancelled_orders,

    SUM(
        CASE
            WHEN final_financier IS NOT NULL
             AND TRIM(final_financier) <> ''
            THEN 1 ELSE 0
        END
    ) AS with_financier,

    SUM(
        CASE
            WHEN final_financier IS NULL
              OR TRIM(final_financier) = ''
            THEN 1 ELSE 0
        END
    ) AS without_financier,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN final_financier IS NOT NULL
                 AND TRIM(final_financier) <> ''
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS financier_coverage_pct

FROM stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'
GROUP BY store
ORDER BY cancelled_orders DESC;



USE carsome_orders_analysis;

SELECT
    CASE
        WHEN final_loan_status = 'Accepted'
            THEN 'Accepted'
        WHEN final_loan_status IS NULL
          OR TRIM(final_loan_status) = ''
            THEN 'Missing / Blank'
        ELSE TRIM(final_loan_status)
    END AS final_loan_status,

    CASE
        WHEN final_status_remark IS NULL
          OR TRIM(final_status_remark) = ''
            THEN 'Missing / Blank'
        ELSE 'Has Remark'
    END AS remark_status,

    COUNT(*) AS cancelled_orders

FROM stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'
GROUP BY
    CASE
        WHEN final_loan_status = 'Accepted'
            THEN 'Accepted'
        WHEN final_loan_status IS NULL
          OR TRIM(final_loan_status) = ''
            THEN 'Missing / Blank'
        ELSE TRIM(final_loan_status)
    END,
    CASE
        WHEN final_status_remark IS NULL
          OR TRIM(final_status_remark) = ''
            THEN 'Missing / Blank'
        ELSE 'Has Remark'
    END
ORDER BY cancelled_orders DESC;
);



USE carsome_orders_analysis;

SELECT
    COUNT(*) AS cancelled_orders_with_remarks,

    SUM(
        CASE WHEN LOWER(final_status_remark) LIKE '%slash%'
        THEN 1 ELSE 0 END
    ) AS slash_keyword_cases,

    SUM(
        CASE
            WHEN LOWER(final_status_remark) LIKE '%interest rate%'
              OR LOWER(final_status_remark) LIKE '%ir %'
              OR LOWER(final_status_remark) LIKE '%eir%'
            THEN 1 ELSE 0
        END
    ) AS interest_rate_keyword_cases,

    SUM(
        CASE
            WHEN LOWER(final_status_remark) LIKE '%document%'
              OR LOWER(final_status_remark) LIKE '%provide%'
              OR LOWER(final_status_remark) LIKE '%verification%'
              OR LOWER(final_status_remark) LIKE '%ssm%'
              OR LOWER(final_status_remark) LIKE '%epf%'
            THEN 1 ELSE 0
        END
    ) AS document_or_verification_cases,

    SUM(
        CASE
            WHEN LOWER(final_status_remark) LIKE '%customer%'
            THEN 1 ELSE 0
        END
    ) AS customer_keyword_cases

FROM stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'
  AND final_status_remark IS NOT NULL
  AND TRIM(final_status_remark) <> '';



USE carsome_orders_analysis;

SELECT
    store,
    CASE
        WHEN COALESCE(financing_case_flag, 0) = 1
            THEN 'Financing Case'
        ELSE 'Non-financing Case'
    END AS financing_group,
    COUNT(*) AS total_orders,
    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,
    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct
FROM stg_orders
GROUP BY
    store,
    CASE
        WHEN COALESCE(financing_case_flag, 0) = 1
            THEN 'Financing Case'
        ELSE 'Non-financing Case'
    END
HAVING COUNT(*) >= 10
ORDER BY
    cancellation_rate_pct DESC,
    total_orders DESC;


USE carsome_orders_analysis;

SELECT
    CASE
        WHEN COALESCE(financing_case_flag, 0) = 0
            THEN 'Non-financing Case'

        WHEN COALESCE(approved_flag, 0) = 1
         AND COALESCE(accepted_flag, 0) = 0
            THEN 'Approved but Not Accepted'

        WHEN COALESCE(accepted_flag, 0) = 1
         AND COALESCE(disbursement_submitted_flag, 0) = 0
            THEN 'Accepted but Not Submitted'

        WHEN COALESCE(disbursement_submitted_flag, 0) = 1
         AND COALESCE(disbursement_received_flag, 0) = 0
            THEN 'Submitted but Not Received'

        WHEN COALESCE(disbursement_received_flag, 0) = 1
            THEN 'Disbursement Received'

        ELSE 'Financing Case - Other Stage'
    END AS cancellation_stage,

    COUNT(*) AS cancelled_orders,

    ROUND(
        100.0 * COUNT(*) /
        (
            SELECT COUNT(*)
            FROM stg_orders
            WHERE TRIM(order_status) = 'Order Cancelled'
        ),
        2
    ) AS pct_of_cancelled_orders

FROM stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'

GROUP BY cancellation_stage
ORDER BY cancelled_orders DESC;



USE carsome_orders_analysis;

SELECT
    COALESCE(NULLIF(TRIM(final_loan_status), ''),
             'Missing / Blank') AS final_loan_status,

    COALESCE(NULLIF(TRIM(disbursement_status), ''),
             'Missing / Blank') AS disbursement_status,

    COALESCE(financing_case_flag, 0) AS financing_case_flag,
    COALESCE(approved_flag, 0) AS approved_flag,
    COALESCE(accepted_flag, 0) AS accepted_flag,
    COALESCE(disbursement_submitted_flag, 0)
        AS disbursement_submitted_flag,
    COALESCE(disbursement_received_flag, 0)
        AS disbursement_received_flag,

    COUNT(*) AS cancelled_orders

FROM stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'
  AND COALESCE(financing_case_flag, 0) = 1
  AND COALESCE(approved_flag, 0) = 0
  AND COALESCE(accepted_flag, 0) = 0
  AND COALESCE(disbursement_submitted_flag, 0) = 0
  AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    final_loan_status,
    disbursement_status,
    financing_case_flag,
    approved_flag,
    accepted_flag,
    disbursement_submitted_flag,
    disbursement_received_flag

ORDER BY cancelled_orders DESC;



USE carsome_orders_analysis;

SELECT
    COUNT(*) AS cancelled_financing_cases,

    SUM(
        CASE WHEN loan_submission_date1 IS NOT NULL
               OR loan_submission_date2 IS NOT NULL
               OR loan_submission_date3 IS NOT NULL
               OR loan_submission_date4 IS NOT NULL
               OR loan_submission_date5 IS NOT NULL
             THEN 1 ELSE 0 END
    ) AS cases_with_submission_date,

    SUM(
        CASE WHEN loan_submission_date1 IS NULL
               AND loan_submission_date2 IS NULL
               AND loan_submission_date3 IS NULL
               AND loan_submission_date4 IS NULL
               AND loan_submission_date5 IS NULL
             THEN 1 ELSE 0 END
    ) AS cases_without_submission_date,

    SUM(
        CASE WHEN created_time IS NOT NULL
             THEN 1 ELSE 0 END
    ) AS cases_with_created_time,

    SUM(
        CASE WHEN final_status_remark IS NOT NULL
               AND TRIM(final_status_remark) <> ''
             THEN 1 ELSE 0 END
    ) AS cases_with_remark

FROM stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'
  AND COALESCE(financing_case_flag, 0) = 1
  AND COALESCE(approved_flag, 0) = 0
  AND COALESCE(accepted_flag, 0) = 0
  AND COALESCE(disbursement_submitted_flag, 0) = 0
  AND COALESCE(disbursement_received_flag, 0) = 0
  AND NULLIF(TRIM(final_loan_status), '') IS NULL
  AND NULLIF(TRIM(disbursement_status), '') IS NULL;



USE carsome_orders_analysis;

SELECT
    CASE
        WHEN loan_submission_date5 IS NOT NULL THEN 5
        WHEN loan_submission_date4 IS NOT NULL THEN 4
        WHEN loan_submission_date3 IS NOT NULL THEN 3
        WHEN loan_submission_date2 IS NOT NULL THEN 2
        WHEN loan_submission_date1 IS NOT NULL THEN 1
        ELSE 0
    END AS last_submission_round,

    COUNT(*) AS cancelled_orders,

    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM stg_orders
            WHERE TRIM(order_status) = 'Order Cancelled'
              AND COALESCE(financing_case_flag, 0) = 1
              AND COALESCE(approved_flag, 0) = 0
              AND COALESCE(accepted_flag, 0) = 0
              AND COALESCE(disbursement_submitted_flag, 0) = 0
              AND COALESCE(disbursement_received_flag, 0) = 0
              AND NULLIF(TRIM(final_loan_status), '') IS NULL
              AND NULLIF(TRIM(disbursement_status), '') IS NULL
        ),
        2
    ) AS pct_of_target_cases

FROM stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'
  AND COALESCE(financing_case_flag, 0) = 1
  AND COALESCE(approved_flag, 0) = 0
  AND COALESCE(accepted_flag, 0) = 0
  AND COALESCE(disbursement_submitted_flag, 0) = 0
  AND COALESCE(disbursement_received_flag, 0) = 0
  AND NULLIF(TRIM(final_loan_status), '') IS NULL
  AND NULLIF(TRIM(disbursement_status), '') IS NULL

GROUP BY last_submission_round
ORDER BY last_submission_round;



USE carsome_orders_analysis;

SELECT
    CASE
        WHEN loan_submission_date5 IS NOT NULL THEN 5
        WHEN loan_submission_date4 IS NOT NULL THEN 4
        WHEN loan_submission_date3 IS NOT NULL THEN 3
        WHEN loan_submission_date2 IS NOT NULL THEN 2
        WHEN loan_submission_date1 IS NOT NULL THEN 1
        ELSE 0
    END AS last_submission_round,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) / COUNT(*),
        2
    ) AS cancellation_rate_pct

FROM stg_orders
WHERE COALESCE(financing_case_flag, 0) = 1

GROUP BY last_submission_round
ORDER BY last_submission_round;



USE carsome_orders_analysis;

WITH store_base AS (
    SELECT
        COALESCE(
            NULLIF(TRIM(store), ''),
            'Missing / Blank'
        ) AS store_name,

        TRIM(order_status) AS order_status,

        CASE
            WHEN COALESCE(financing_case_flag, 0) = 1
                THEN 'Financing'
            ELSE 'Non-financing'
        END AS financing_type

    FROM stg_orders
),

store_metrics AS (
    SELECT
        store_name,

        COUNT(*) AS total_orders,

        SUM(
            CASE WHEN order_status = 'Order Cancelled'
                 THEN 1 ELSE 0 END
        ) AS cancelled_orders,

        SUM(
            CASE WHEN order_status = 'Order Cancelled'
                 THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*) AS cancellation_rate_pct,

        SUM(
            CASE WHEN financing_type = 'Financing'
                 THEN 1 ELSE 0 END
        ) AS financing_orders,

        SUM(
            CASE WHEN financing_type = 'Financing'
                  AND order_status = 'Order Cancelled'
                 THEN 1 ELSE 0 END
        ) AS financing_cancelled,

        100.0 * SUM(
            CASE WHEN financing_type = 'Financing'
                  AND order_status = 'Order Cancelled'
                 THEN 1 ELSE 0 END
        ) / NULLIF(
            SUM(CASE WHEN financing_type = 'Financing'
                     THEN 1 ELSE 0 END),
            0
        ) AS financing_cancellation_rate_pct,

        SUM(
            CASE WHEN financing_type = 'Non-financing'
                 THEN 1 ELSE 0 END
        ) AS non_financing_orders,

        SUM(
            CASE WHEN financing_type = 'Non-financing'
                  AND order_status = 'Order Cancelled'
                 THEN 1 ELSE 0 END
        ) AS non_financing_cancelled,

        100.0 * SUM(
            CASE WHEN financing_type = 'Non-financing'
                  AND order_status = 'Order Cancelled'
                 THEN 1 ELSE 0 END
        ) / NULLIF(
            SUM(CASE WHEN financing_type = 'Non-financing'
                     THEN 1 ELSE 0 END),
            0
        ) AS non_financing_cancellation_rate_pct

    FROM store_base
    GROUP BY store_name
)

SELECT
    store_name,
    total_orders,
    cancelled_orders,
    ROUND(cancellation_rate_pct, 2) AS cancellation_rate_pct,

    financing_orders,
    financing_cancelled,
    ROUND(financing_cancellation_rate_pct, 2)
        AS financing_cancellation_rate_pct,

    non_financing_orders,
    non_financing_cancelled,
    ROUND(non_financing_cancellation_rate_pct, 2)
        AS non_financing_cancellation_rate_pct

FROM store_metrics

ORDER BY
    cancelled_orders DESC,
    cancellation_rate_pct DESC;

SELECT
    TABLE_NAME,
    COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'carsome_orders_analysis'
  AND COLUMN_NAME IN (
      'store',
      'store_name',
      'financing_case_flag',
      'order_status'
  )
ORDER BY TABLE_NAME, ORDINAL_POSITION;



USE carsome_orders_analysis;

SELECT
    COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank') AS store,

    CASE
        WHEN financing_case_flag = 1 THEN 'Financing Case'
        WHEN financing_case_flag = 0 THEN 'Non-financing Case'
        ELSE 'Unknown'
    END AS financing_group,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
            THEN 1 ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        100.0 * SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM stg_orders

GROUP BY
    COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank'),
    CASE
        WHEN financing_case_flag = 1 THEN 'Financing Case'
        WHEN financing_case_flag = 0 THEN 'Non-financing Case'
        ELSE 'Unknown'
    END

ORDER BY store, financing_group;
);



USE carsome_orders_analysis;

WITH store_group_metrics AS (
    SELECT
        COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank') AS store,

        CASE
            WHEN financing_case_flag = 1 THEN 'Financing Case'
            WHEN financing_case_flag = 0 THEN 'Non-financing Case'
            ELSE 'Unknown'
        END AS financing_group,

        COUNT(*) AS total_orders,

        SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1 ELSE 0
            END
        ) AS cancelled_orders

    FROM stg_orders

    GROUP BY
        COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank'),
        CASE
            WHEN financing_case_flag = 1 THEN 'Financing Case'
            WHEN financing_case_flag = 0 THEN 'Non-financing Case'
            ELSE 'Unknown'
        END
),

store_comparison AS (
    SELECT
        store,

        SUM(total_orders) AS total_orders,
        SUM(cancelled_orders) AS cancelled_orders,

        ROUND(
            100.0 * SUM(cancelled_orders)
            / NULLIF(SUM(total_orders), 0),
            2
        ) AS overall_cancellation_rate_pct,

        SUM(CASE
            WHEN financing_group = 'Financing Case'
            THEN total_orders ELSE 0
        END) AS financing_orders,

        SUM(CASE
            WHEN financing_group = 'Financing Case'
            THEN cancelled_orders ELSE 0
        END) AS financing_cancelled_orders,

        ROUND(
            100.0 * SUM(CASE
                WHEN financing_group = 'Financing Case'
                THEN cancelled_orders ELSE 0
            END)
            / NULLIF(SUM(CASE
                WHEN financing_group = 'Financing Case'
                THEN total_orders ELSE 0
            END), 0),
            2
        ) AS financing_cancellation_rate_pct,

        SUM(CASE
            WHEN financing_group = 'Non-financing Case'
            THEN total_orders ELSE 0
        END) AS non_financing_orders,

        SUM(CASE
            WHEN financing_group = 'Non-financing Case'
            THEN cancelled_orders ELSE 0
        END) AS non_financing_cancelled_orders,

        ROUND(
            100.0 * SUM(CASE
                WHEN financing_group = 'Non-financing Case'
                THEN cancelled_orders ELSE 0
            END)
            / NULLIF(SUM(CASE
                WHEN financing_group = 'Non-financing Case'
                THEN total_orders ELSE 0
            END), 0),
            2
        ) AS non_financing_cancellation_rate_pct

    FROM store_group_metrics
    WHERE financing_group IN (
        'Financing Case',
        'Non-financing Case'
    )
    GROUP BY store
),

ranked_stores AS (
    SELECT
        *,
        ROUND(
            non_financing_cancellation_rate_pct
            - financing_cancellation_rate_pct,
            2
        ) AS cancellation_gap_pp
    FROM store_comparison
)

SELECT
    *,

    CASE
        WHEN financing_orders < 10
          OR non_financing_orders < 10
            THEN 'Low Group Volume - Monitor'

        WHEN cancelled_orders >= 25
         AND overall_cancellation_rate_pct > 34.91
            THEN 'P1 - High Business Impact'

        WHEN non_financing_cancellation_rate_pct
             - financing_cancellation_rate_pct >= 20
            THEN 'P2 - Large Cancellation Gap'

        ELSE 'P3 - Regular Monitoring'
    END AS investigation_priority

FROM ranked_stores

ORDER BY
    CASE
        WHEN financing_orders >= 10
         AND non_financing_orders >= 10
         AND cancelled_orders >= 25
         AND overall_cancellation_rate_pct > 34.91
            THEN 1

        WHEN financing_orders >= 10
         AND non_financing_orders >= 10
         AND non_financing_cancellation_rate_pct
             - financing_cancellation_rate_pct >= 20
            THEN 2

        WHEN financing_orders < 10
          OR non_financing_orders < 10
            THEN 4

        ELSE 3
    END,
    cancelled_orders DESC;



-- ============================================================
-- 03 Cancellation Analysis
-- Analysis: Cancellation by Financing Stage
-- ============================================================

USE carsome_orders_analysis;

SELECT
    CASE
        WHEN financing_case_flag = 0
            THEN 'Non-financing Case'

        WHEN financing_case_flag = 1
         AND COALESCE(TRIM(final_loan_status), '') = ''
         AND COALESCE(TRIM(disbursement_status), '') = ''
            THEN 'Financing - No Recorded Loan/Disbursement Status'

        WHEN financing_case_flag = 1
         AND TRIM(final_loan_status) = 'Accepted'
         AND COALESCE(TRIM(disbursement_status), '') = ''
            THEN 'Accepted - No Recorded Disbursement Status'

        WHEN financing_case_flag = 1
         AND TRIM(final_loan_status) = 'Accepted'
         AND TRIM(disbursement_status) = 'Pending Submission'
            THEN 'Accepted - Pending Submission'

        WHEN financing_case_flag = 1
         AND TRIM(disbursement_status) = 'Submitted'
            THEN 'Disbursement Submitted'

        WHEN financing_case_flag = 1
         AND TRIM(disbursement_status) = 'Received'
            THEN 'Disbursement Received'

        WHEN financing_case_flag = 1
            THEN 'Other Financing Stage'

        ELSE 'Unknown'
    END AS cancellation_stage,

    COUNT(*) AS cancelled_orders,

    ROUND(
        COUNT(*) * 100.0 /
        (
            SELECT COUNT(*)
            FROM stg_orders
            WHERE TRIM(order_status) = 'Order Cancelled'
        ),
        2
    ) AS pct_of_cancelled_orders

FROM stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'

GROUP BY cancellation_stage

ORDER BY cancelled_orders DESC;



-- ============================================================
-- Analysis: Submission rounds among cancelled financing cases
-- ============================================================

USE carsome_orders_analysis;

SELECT
    CASE
        WHEN loan_submission_date5 IS NOT NULL THEN 5
        WHEN loan_submission_date4 IS NOT NULL THEN 4
        WHEN loan_submission_date3 IS NOT NULL THEN 3
        WHEN loan_submission_date2 IS NOT NULL THEN 2
        WHEN loan_submission_date1 IS NOT NULL THEN 1
        ELSE 0
    END AS last_submission_round,

    COUNT(*) AS cancelled_orders,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS pct_of_cancelled_financing

FROM stg_orders

WHERE TRIM(order_status) = 'Order Cancelled'
  AND financing_case_flag = 1
  AND COALESCE(TRIM(final_loan_status), '') = ''
  AND COALESCE(TRIM(disbursement_status), '') = ''

GROUP BY last_submission_round

ORDER BY last_submission_round;



-- ============================================================
-- Analysis: Cancellation rate by submission round
-- Compare cancelled orders with all orders in each round
-- ============================================================

USE carsome_orders_analysis;

WITH order_round AS (
    SELECT
        order_status,
        CASE
            WHEN loan_submission_date5 IS NOT NULL THEN 5
            WHEN loan_submission_date4 IS NOT NULL THEN 4
            WHEN loan_submission_date3 IS NOT NULL THEN 3
            WHEN loan_submission_date2 IS NOT NULL THEN 2
            WHEN loan_submission_date1 IS NOT NULL THEN 1
            ELSE 0
        END AS submission_round
    FROM stg_orders
    WHERE financing_case_flag = 1
)

SELECT
    submission_round,
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
    ) AS cancellation_rate_pct

FROM order_round
GROUP BY submission_round
ORDER BY submission_round;



-- 03_cancellation_analysis.sql
-- Store cancellation performance by financing type

USE carsome_orders_analysis;

SELECT
    COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank') AS store,

    CASE
        WHEN financing_case_flag = 1
            THEN 'Financing Case'
        ELSE 'Non-financing Case'
    END AS financing_group,

    COUNT(*) AS total_orders,

    SUM(
        CASE
            WHEN TRIM(order_status) = 'Order Cancelled'
                THEN 1
            ELSE 0
        END
    ) AS cancelled_orders,

    ROUND(
        SUM(
            CASE
                WHEN TRIM(order_status) = 'Order Cancelled'
                    THEN 1
                ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_rate_pct

FROM stg_orders

GROUP BY
    COALESCE(NULLIF(TRIM(store), ''), 'Missing / Blank'),
    CASE
        WHEN financing_case_flag = 1
            THEN 'Financing Case'
        ELSE 'Non-financing Case'
    END

ORDER BY
    cancelled_orders DESC,
    cancellation_rate_pct DESC;



-- 03_cancellation_analysis.sql
-- Inspect available cancellation remarks
-- Do not expose individual records in public portfolio outputs.

USE carsome_orders_analysis;

SELECT
    final_loan_status,
    disbursement_status,
    COUNT(*) AS cancelled_orders_with_remark
FROM stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'
  AND final_status_remark IS NOT NULL
  AND TRIM(final_status_remark) <> ''
GROUP BY
    final_loan_status,
    disbursement_status
ORDER BY cancelled_orders_with_remark DESC;



-- 03_cancellation_analysis.sql
-- Explore potential themes in the 11 recorded cancellation remarks

USE carsome_orders_analysis;

SELECT
    COUNT(*) AS cancelled_orders_with_remark,

    SUM(
        CASE
            WHEN LOWER(final_status_remark) REGEXP
                 'slash|slashed|require sav|loan amount'
            THEN 1 ELSE 0
        END
    ) AS loan_amount_or_slashing_mentions,

    SUM(
        CASE
            WHEN LOWER(final_status_remark) REGEXP
                 'interest rate|equivalent|monthly instalment|monthly installment|eir'
            THEN 1 ELSE 0
        END
    ) AS loan_terms_mentions,

    SUM(
        CASE
            WHEN LOWER(final_status_remark) REGEXP
                 'document|provide|verification|epf|ssm|ic w/o'
            THEN 1 ELSE 0
        END
    ) AS document_or_verification_mentions,

    SUM(
        CASE
            WHEN LOWER(final_status_remark) REGEXP
                 'customer|guarantor|hirer'
            THEN 1 ELSE 0
        END
    ) AS customer_or_guarantor_mentions

FROM stg_orders
WHERE TRIM(order_status) = 'Order Cancelled'
  AND final_status_remark IS NOT NULL
  AND TRIM(final_status_remark) <> '';
