
USE carsome_orders_analysis;

-- ============================================================
-- 07.1 — Overall Business Performance
-- STEP 1: Overall KPI Summary & Data Validation
-- Source: stg_orders
-- ============================================================

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_records,

    SUM(CASE
        WHEN order_id IS NULL THEN 1
        ELSE 0
    END) AS null_order_id_records,

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
        AS completed_cases,

    ROUND(
        100.0 * SUM(COALESCE(financing_case_flag, 0))
        / NULLIF(COUNT(*), 0),
        2
    ) AS financing_rate_pct,

    ROUND(
        100.0 * SUM(COALESCE(approved_flag, 0))
        / NULLIF(SUM(COALESCE(financing_case_flag, 0)), 0),
        2
    ) AS approval_rate_pct,

    ROUND(
        100.0 * SUM(COALESCE(accepted_flag, 0))
        / NULLIF(SUM(COALESCE(financing_case_flag, 0)), 0),
        2
    ) AS accepted_vs_financing_pct,

    ROUND(
        100.0 * SUM(COALESCE(completed_flag, 0))
        / NULLIF(COUNT(*), 0),
        2
    ) AS overall_completion_rate_pct

FROM stg_orders;




USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status,

    COUNT(*) AS order_count,

    ROUND(
        COUNT(*) * 100.0 /
        NULLIF((SELECT COUNT(*) FROM stg_orders), 0),
        2
    ) AS percentage

FROM stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    )

ORDER BY order_count DESC;




USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(final_loan_status), ''),
        'Missing / Blank'
    ) AS final_loan_status,

    COUNT(*) AS case_count,

    ROUND(
        COUNT(*) * 100.0 /
        NULLIF(
            (SELECT COUNT(*) FROM stg_orders
             WHERE COALESCE(financing_case_flag, 0) = 1),
            0
        ),
        2
    ) AS percentage_of_financing_cases

FROM stg_orders

WHERE COALESCE(financing_case_flag, 0) = 1

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_loan_status), ''),
        'Missing / Blank'
    )

ORDER BY case_count DESC;


USE carsome_orders_analysis;

-- 07.1.8 — Completed vs Disbursement Received Validation

SELECT
    COUNT(*) AS total_orders,

    SUM(
        CASE WHEN completed_flag = 1
        THEN 1 ELSE 0 END
    ) AS completed_cases,

    SUM(
        CASE WHEN disbursement_received_flag = 1
        THEN 1 ELSE 0 END
    ) AS received_cases,

    SUM(
        CASE
            WHEN completed_flag = 1
             AND disbursement_received_flag = 1
            THEN 1 ELSE 0
        END
    ) AS completed_and_received,

    SUM(
        CASE
            WHEN completed_flag = 1
             AND COALESCE(disbursement_received_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS completed_without_received,

    SUM(
        CASE
            WHEN disbursement_received_flag = 1
             AND COALESCE(completed_flag, 0) = 0
            THEN 1 ELSE 0
        END
    ) AS received_without_completed

FROM stg_orders;


-- Inspect individual completed orders without received flag

SELECT
    order_id,
    order_status,
    final_financier,
    final_loan_status,
    disbursement_status,
    disbursement_submit_date,
    disbursement_receive_date,
    completed_flag,
    disbursement_received_flag

FROM stg_orders

WHERE completed_flag = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

ORDER BY order_id;


USE carsome_orders_analysis;

SELECT
    order_status,
    final_loan_status,
    disbursement_status,
    COUNT(*) AS order_count

FROM stg_orders

WHERE disbursement_received_flag = 1
  AND COALESCE(completed_flag, 0) = 0

GROUP BY
    order_status,
    final_loan_status,
    disbursement_status

ORDER BY order_count DESC;


SELECT
    order_id,
    order_status,
    final_financier,
    final_loan_status,
    disbursement_status,
    disbursement_submit_date,
    disbursement_receive_date,
    completed_flag,
    disbursement_received_flag

FROM stg_orders

WHERE disbursement_received_flag = 1
  AND COALESCE(completed_flag, 0) = 0

ORDER BY order_id;


SELECT
    completed_flag,
    disbursement_received_flag,
    order_status,
    COUNT(*) AS order_count

FROM stg_orders

GROUP BY
    completed_flag,
    disbursement_received_flag,
    order_status

ORDER BY
    completed_flag DESC,
    disbursement_received_flag DESC,
    order_count DESC;
    
    
    
USE carsome_orders_analysis;

-- ============================================================
-- 07.2.1 — Financing Stage Flag Validation
-- STEP 1: Stage Counts within Financing Cases
-- ============================================================

SELECT
    COUNT(*) AS financing_cases,

    SUM(CASE WHEN approved_flag = 1
        THEN 1 ELSE 0 END) AS approved_cases,

    SUM(CASE WHEN accepted_flag = 1
        THEN 1 ELSE 0 END) AS accepted_cases,

    SUM(CASE WHEN disbursement_submitted_flag = 1
        THEN 1 ELSE 0 END) AS disbursement_submitted_cases,

    SUM(CASE WHEN disbursement_received_flag = 1
        THEN 1 ELSE 0 END) AS disbursement_received_cases,

    ROUND(
        100.0 * SUM(CASE WHEN approved_flag = 1
            THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS approval_rate_pct,

    ROUND(
        100.0 * SUM(CASE WHEN accepted_flag = 1
            THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS accepted_rate_pct,

    ROUND(
        100.0 * SUM(CASE WHEN disbursement_submitted_flag = 1
            THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS submitted_rate_pct,

    ROUND(
        100.0 * SUM(CASE WHEN disbursement_received_flag = 1
            THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS received_rate_pct

FROM stg_orders
WHERE financing_case_flag = 1;


-- ============================================================
-- STEP 2: Pairwise Stage Overlap Validation
-- ============================================================

SELECT
    COUNT(*) AS financing_cases,

    SUM(CASE
        WHEN approved_flag = 1
         AND accepted_flag = 1
        THEN 1 ELSE 0
    END) AS approved_and_accepted,

    SUM(CASE
        WHEN approved_flag = 1
         AND accepted_flag = 0
        THEN 1 ELSE 0
    END) AS approved_not_accepted,

    SUM(CASE
        WHEN accepted_flag = 1
         AND disbursement_submitted_flag = 1
        THEN 1 ELSE 0
    END) AS accepted_and_submitted,

    SUM(CASE
        WHEN accepted_flag = 1
         AND disbursement_submitted_flag = 0
        THEN 1 ELSE 0
    END) AS accepted_not_submitted,

    SUM(CASE
        WHEN disbursement_submitted_flag = 1
         AND disbursement_received_flag = 1
        THEN 1 ELSE 0
    END) AS submitted_and_received,

    SUM(CASE
        WHEN disbursement_submitted_flag = 1
         AND disbursement_received_flag = 0
        THEN 1 ELSE 0
    END) AS submitted_not_received

FROM stg_orders
WHERE financing_case_flag = 1;



-- ============================================================
-- STEP 3: Reverse Stage Flag Validation
-- ============================================================

SELECT
    COUNT(*) AS financing_cases,

    SUM(CASE
        WHEN accepted_flag = 1
         AND COALESCE(approved_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS accepted_without_approved,

    SUM(CASE
        WHEN disbursement_submitted_flag = 1
         AND COALESCE(accepted_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS submitted_without_accepted,

    SUM(CASE
        WHEN disbursement_received_flag = 1
         AND COALESCE(disbursement_submitted_flag, 0) = 0
        THEN 1 ELSE 0
    END) AS received_without_submitted

FROM stg_orders
WHERE financing_case_flag = 1;


-- ============================================================
-- STEP 4: Identify Reverse-Stage Orders
-- ============================================================

SELECT
    order_id,
    order_status,
    final_financier,
    final_loan_status,

    financing_case_flag,
    approved_flag,
    accepted_flag,
    disbursement_submitted_flag,
    disbursement_received_flag,

    loan_acceptance_date,
    disbursement_submit_date,
    disbursement_receive_date

FROM stg_orders

WHERE financing_case_flag = 1
  AND (
       (accepted_flag = 1
        AND COALESCE(approved_flag, 0) = 0)

    OR (disbursement_submitted_flag = 1
        AND COALESCE(accepted_flag, 0) = 0)

    OR (disbursement_received_flag = 1
        AND COALESCE(disbursement_submitted_flag, 0) = 0)
  )

ORDER BY order_id;


USE carsome_orders_analysis;

-- ============================================================
-- 07.2.2 — Stage Conversion Analysis
-- ============================================================

WITH stage_counts AS (

    SELECT
        COUNT(*) AS financing_cases,

        SUM(CASE WHEN approved_flag = 1
            THEN 1 ELSE 0 END) AS approved_cases,

        SUM(CASE WHEN accepted_flag = 1
            THEN 1 ELSE 0 END) AS accepted_cases,

        SUM(CASE WHEN disbursement_submitted_flag = 1
            THEN 1 ELSE 0 END) AS submitted_cases,

        SUM(CASE WHEN disbursement_received_flag = 1
            THEN 1 ELSE 0 END) AS received_cases

    FROM stg_orders
    WHERE financing_case_flag = 1
),

funnel AS (

    SELECT
        1 AS stage_order,
        'Financing → Approved' AS conversion_stage,
        financing_cases AS previous_stage_cases,
        approved_cases AS current_stage_cases
    FROM stage_counts

    UNION ALL

    SELECT
        2,
        'Approved → Accepted',
        approved_cases,
        accepted_cases
    FROM stage_counts

    UNION ALL

    SELECT
        3,
        'Accepted → Disbursement Submitted',
        accepted_cases,
        submitted_cases
    FROM stage_counts

    UNION ALL

    SELECT
        4,
        'Disbursement Submitted → Received',
        submitted_cases,
        received_cases
    FROM stage_counts
)

SELECT
    conversion_stage,

    previous_stage_cases,

    current_stage_cases,

    previous_stage_cases - current_stage_cases
        AS drop_off_cases,

    ROUND(
        current_stage_cases * 100.0 /
        NULLIF(previous_stage_cases, 0),
        2
    ) AS conversion_rate_pct,

    ROUND(
        (previous_stage_cases - current_stage_cases)
        * 100.0 /
        NULLIF(previous_stage_cases, 0),
        2
    ) AS drop_off_rate_pct

FROM funnel
ORDER BY stage_order;


SELECT

    COUNT(*) AS financing_cases,

    SUM(CASE WHEN approved_flag = 1
        THEN 1 ELSE 0 END) AS approved_cases,

    SUM(CASE WHEN disbursement_received_flag = 1
        THEN 1 ELSE 0 END) AS received_cases,

    ROUND(
        SUM(CASE WHEN disbursement_received_flag = 1
            THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(COUNT(*), 0),
        2
    ) AS financing_to_received_rate_pct,

    ROUND(
        SUM(CASE WHEN disbursement_received_flag = 1
            THEN 1 ELSE 0 END) * 100.0 /
        NULLIF(
            SUM(CASE WHEN approved_flag = 1
                THEN 1 ELSE 0 END), 0
        ),
        2
    ) AS approved_to_received_rate_pct

FROM stg_orders
WHERE financing_case_flag = 1;



USE carsome_orders_analysis;

-- ============================================================
-- 07.2.3 — Financing Drop-off Analysis
-- STEP 1: Drop-off Distribution by Financier
-- ============================================================

WITH dropoff_cases AS (

    -- Financing but not Approved
    SELECT
        order_id,
        COALESCE(final_financier, 'Missing / Blank') AS financier,
        'Financing → Approved' AS dropoff_stage
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND COALESCE(approved_flag, 0) = 0

    UNION ALL

    -- Approved but not Accepted
    SELECT
        order_id,
        COALESCE(final_financier, 'Missing / Blank'),
        'Approved → Accepted'
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND approved_flag = 1
      AND COALESCE(accepted_flag, 0) = 0

    UNION ALL

    -- Accepted but not Submitted
    SELECT
        order_id,
        COALESCE(final_financier, 'Missing / Blank'),
        'Accepted → Submitted'
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND accepted_flag = 1
      AND COALESCE(disbursement_submitted_flag, 0) = 0

    UNION ALL

    -- Submitted but not Received
    SELECT
        order_id,
        COALESCE(final_financier, 'Missing / Blank'),
        'Submitted → Received'
    FROM stg_orders
    WHERE financing_case_flag = 1
      AND disbursement_submitted_flag = 1
      AND COALESCE(disbursement_received_flag, 0) = 0
)

SELECT
    dropoff_stage,
    financier,
    COUNT(*) AS dropoff_cases

FROM dropoff_cases

GROUP BY
    dropoff_stage,
    financier

ORDER BY
    dropoff_stage,
    dropoff_cases DESC;
    
    
-- ============================================================
-- STEP 2: Submitted but Not Received
-- Distribution by Order Status
-- ============================================================

SELECT
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ) AS order_status,

    COALESCE(
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    ) AS disbursement_status,

    COUNT(*) AS order_count,

    ROUND(
        COUNT(*) * 100.0 /
        NULLIF((
            SELECT COUNT(*)
            FROM stg_orders
            WHERE financing_case_flag = 1
              AND disbursement_submitted_flag = 1
              AND COALESCE(disbursement_received_flag, 0) = 0
        ), 0),
        2
    ) AS percentage

FROM stg_orders

WHERE financing_case_flag = 1
  AND disbursement_submitted_flag = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

GROUP BY
    COALESCE(
        NULLIF(TRIM(order_status), ''),
        'Missing / Blank'
    ),
    COALESCE(
        NULLIF(TRIM(disbursement_status), ''),
        'Missing / Blank'
    )

ORDER BY order_count DESC;



-- ============================================================
-- STEP 3: TAT Profile of Submitted but Not Received
-- ============================================================

SELECT
    COUNT(*) AS submitted_not_received_cases,

    COUNT(disbursement_tat_days) AS records_with_tat,

    COUNT(disbursement_tat_clean) AS records_with_clean_tat,

    ROUND(AVG(disbursement_tat_days), 2)
        AS avg_raw_tat_days,

    ROUND(AVG(disbursement_tat_clean), 2)
        AS avg_clean_tat_days,

    MAX(disbursement_tat_days)
        AS max_raw_tat_days,

    SUM(CASE
        WHEN disbursement_tat_clean > 7
        THEN 1 ELSE 0
    END) AS clean_tat_over_7_days

FROM stg_orders

WHERE financing_case_flag = 1
  AND disbursement_submitted_flag = 1
  AND COALESCE(disbursement_received_flag, 0) = 0;
  
  
  

USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS submitted_cases,

    SUM(
        CASE WHEN disbursement_received_flag = 1
        THEN 1 ELSE 0 END
    ) AS received_cases,

    SUM(
        CASE WHEN COALESCE(disbursement_received_flag, 0) = 0
        THEN 1 ELSE 0 END
    ) AS submitted_not_received_cases,

    ROUND(
        100.0 * SUM(
            CASE WHEN disbursement_received_flag = 1
            THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS received_conversion_rate_pct,

    ROUND(
        100.0 * SUM(
            CASE WHEN COALESCE(disbursement_received_flag, 0) = 0
            THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS not_received_rate_pct

FROM stg_orders

WHERE financing_case_flag = 1
  AND disbursement_submitted_flag = 1

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    )

ORDER BY submitted_cases DESC;




USE carsome_orders_analysis;

SELECT
    COUNT(*) AS total_cases,

    COUNT(disbursement_submit_date)
        AS cases_with_submit_date,

    SUM(
        CASE WHEN disbursement_submit_date IS NULL
        THEN 1 ELSE 0 END
    ) AS missing_submit_date_cases,

    MIN(disbursement_submit_date)
        AS earliest_submit_date,

    MAX(disbursement_submit_date)
        AS latest_submit_date,

    MIN(created_time)
        AS earliest_order_created,

    MAX(created_time)
        AS latest_order_created,

    SUM(
        CASE WHEN completed_flag = 1
        THEN 1 ELSE 0 END
    ) AS completed_but_not_received

FROM stg_orders

WHERE financing_case_flag = 1
  AND disbursement_submitted_flag = 1
  AND COALESCE(disbursement_received_flag, 0) = 0;
  
  
  


USE carsome_orders_analysis;

WITH waiting_cases AS (
    SELECT
        order_id,
        final_financier,
        order_status,
        disbursement_submit_date,

        DATEDIFF(
            '2026-10-06',
            DATE(disbursement_submit_date)
        ) AS waiting_days

    FROM stg_orders

    WHERE financing_case_flag = 1
      AND disbursement_submitted_flag = 1
      AND COALESCE(disbursement_received_flag, 0) = 0

      AND created_time >= '2026-09-01'
      AND created_time < '2026-10-01'

      AND disbursement_submit_date IS NOT NULL
)

SELECT
    COUNT(*) AS total_cases,
    ROUND(AVG(waiting_days), 2) AS avg_waiting_days,
    MIN(waiting_days) AS min_waiting_days,
    MAX(waiting_days) AS max_waiting_days,

    SUM(CASE WHEN waiting_days > 7
        THEN 1 ELSE 0 END) AS over_7_days,

    SUM(CASE WHEN waiting_days > 14
        THEN 1 ELSE 0 END) AS over_14_days,

    SUM(CASE WHEN waiting_days > 30
        THEN 1 ELSE 0 END) AS over_30_days

FROM waiting_cases;


USE carsome_orders_analysis;

WITH waiting_cases AS (
    SELECT
        order_id,

        DATEDIFF(
            '2026-10-06',
            DATE(disbursement_submit_date)
        ) AS waiting_days

    FROM stg_orders

    WHERE financing_case_flag = 1
      AND disbursement_submitted_flag = 1
      AND COALESCE(disbursement_received_flag, 0) = 0

      AND created_time >= '2026-09-01'
      AND created_time < '2026-10-01'

      AND disbursement_submit_date IS NOT NULL
),

grouped_cases AS (
    SELECT
        CASE
            WHEN waiting_days <= 3 THEN '0-3 Days'
            WHEN waiting_days <= 7 THEN '4-7 Days'
            WHEN waiting_days <= 14 THEN '8-14 Days'
            WHEN waiting_days <= 30 THEN '15-30 Days'
            ELSE '30+ Days'
        END AS waiting_time_group,

        CASE
            WHEN waiting_days <= 3 THEN 1
            WHEN waiting_days <= 7 THEN 2
            WHEN waiting_days <= 14 THEN 3
            WHEN waiting_days <= 30 THEN 4
            ELSE 5
        END AS sort_order

    FROM waiting_cases
)

SELECT
    waiting_time_group,
    COUNT(*) AS order_count,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*) FROM waiting_cases),
        2
    ) AS percentage

FROM grouped_cases

GROUP BY
    waiting_time_group,
    sort_order

ORDER BY sort_order;



SELECT
    COUNT(*) AS total_records,

    MIN(created_time) AS earliest_created_time,

    MAX(created_time) AS latest_created_time,

    COUNT(
        CASE
            WHEN created_time >= '2026-09-01'
             AND created_time < '2026-10-01'
            THEN 1
        END
    ) AS september_records

FROM stg_orders;




USE carsome_orders_analysis;

WITH waiting_cases AS (
    SELECT
        order_id,

        COALESCE(
            NULLIF(TRIM(final_financier), ''),
            'Missing / Blank'
        ) AS financier,

        order_status,

        completed_flag,

        DATEDIFF(
            '2026-10-06',
            DATE(disbursement_submit_date)
        ) AS waiting_days

    FROM stg_orders

    WHERE financing_case_flag = 1
      AND disbursement_submitted_flag = 1
      AND COALESCE(disbursement_received_flag, 0) = 0

      AND created_time >= '2026-09-01'
      AND created_time < '2026-10-01'

      AND disbursement_submit_date IS NOT NULL
)

SELECT
    financier,

    COUNT(*) AS not_received_cases,

    SUM(
        CASE WHEN waiting_days > 7
        THEN 1 ELSE 0 END
    ) AS over_7_days_cases,

    ROUND(AVG(waiting_days), 2)
        AS avg_waiting_days,

    MIN(waiting_days)
        AS min_waiting_days,

    MAX(waiting_days)
        AS max_waiting_days,

    ROUND(
        SUM(
            CASE WHEN waiting_days > 7
            THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*),
        2
    ) AS over_7_days_pct,

    SUM(
        CASE WHEN completed_flag = 1
        THEN 1 ELSE 0 END
    ) AS completed_but_not_received

FROM waiting_cases

GROUP BY financier

ORDER BY
    avg_waiting_days DESC,
    not_received_cases DESC;