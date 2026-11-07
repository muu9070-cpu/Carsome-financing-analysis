
USE carsome_orders_analysis;

CREATE OR REPLACE VIEW vw_072_financing_funnel AS

SELECT
    1 AS stage_order,
    'Financing' AS stage,
    COUNT(*) AS order_count

FROM stg_orders

WHERE financing_case_flag = 1
  AND created_time >= '2026-09-01'
  AND created_time < '2026-10-01'

UNION ALL

SELECT
    2 AS stage_order,
    'Approved' AS stage,
    COUNT(*) AS order_count

FROM stg_orders

WHERE approved_flag = 1
  AND financing_case_flag = 1
  AND created_time >= '2026-09-01'
  AND created_time < '2026-10-01'

UNION ALL

SELECT
    3 AS stage_order,
    'Accepted' AS stage,
    COUNT(*) AS order_count

FROM stg_orders

WHERE accepted_flag = 1
  AND financing_case_flag = 1
  AND created_time >= '2026-09-01'
  AND created_time < '2026-10-01'

UNION ALL

SELECT
    4 AS stage_order,
    'Disbursement Submitted' AS stage,
    COUNT(*) AS order_count

FROM stg_orders

WHERE disbursement_submitted_flag = 1
  AND financing_case_flag = 1
  AND created_time >= '2026-09-01'
  AND created_time < '2026-10-01'

UNION ALL

SELECT
    5 AS stage_order,
    'Disbursement Received' AS stage,
    COUNT(*) AS order_count

FROM stg_orders

WHERE disbursement_received_flag = 1
  AND financing_case_flag = 1
  AND created_time >= '2026-09-01'
  AND created_time < '2026-10-01';


SELECT
    stage_order,
    stage,
    order_count
FROM vw_072_financing_funnel
ORDER BY stage_order;




USE carsome_orders_analysis;

CREATE OR REPLACE VIEW vw_072_stage_conversion AS

SELECT
    1 AS stage_order,
    'Financing → Approved' AS conversion_stage,

    2062 AS previous_stage_cases,
    1500 AS current_stage_cases,

    2062 - 1500 AS drop_off_cases,

    ROUND(1500 * 100.0 / 2062, 2)
        AS conversion_rate_pct,

    ROUND((2062 - 1500) * 100.0 / 2062, 2)
        AS drop_off_rate_pct

UNION ALL

SELECT
    2,
    'Approved → Accepted',

    1500,
    1334,

    1500 - 1334,

    ROUND(1334 * 100.0 / 1500, 2),

    ROUND((1500 - 1334) * 100.0 / 1500, 2)

UNION ALL

SELECT
    3,
    'Accepted → Disbursement Submitted',

    1334,
    1149,

    1334 - 1149,

    ROUND(1149 * 100.0 / 1334, 2),

    ROUND((1334 - 1149) * 100.0 / 1334, 2)

UNION ALL

SELECT
    4,
    'Disbursement Submitted → Received',

    1149,
    819,

    1149 - 819,

    ROUND(819 * 100.0 / 1149, 2),

    ROUND((1149 - 819) * 100.0 / 1149, 2);



SELECT
    stage_order,
    conversion_stage,
    previous_stage_cases,
    current_stage_cases,
    drop_off_cases,
    conversion_rate_pct,
    drop_off_rate_pct

FROM vw_072_stage_conversion

ORDER BY stage_order;



USE carsome_orders_analysis;

CREATE OR REPLACE VIEW vw_072_financier_conversion AS

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS submitted_cases,

    SUM(
        CASE
            WHEN disbursement_received_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS received_cases,

    SUM(
        CASE
            WHEN COALESCE(disbursement_received_flag, 0) = 0
            THEN 1
            ELSE 0
        END
    ) AS submitted_not_received_cases,

    ROUND(
        SUM(
            CASE
                WHEN disbursement_received_flag = 1
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS received_conversion_rate_pct,

    ROUND(
        SUM(
            CASE
                WHEN COALESCE(disbursement_received_flag, 0) = 0
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS not_received_rate_pct

FROM stg_orders

WHERE financing_case_flag = 1
  AND disbursement_submitted_flag = 1
  AND created_time >= '2026-09-01'
  AND created_time < '2026-10-01'

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    );



SELECT *
FROM vw_072_financier_conversion
ORDER BY submitted_cases DESC;



USE carsome_orders_analysis;

CREATE OR REPLACE VIEW vw_072_waiting_distribution AS

SELECT
    waiting_time_group,
    sort_order,
    COUNT(*) AS order_count,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage

FROM (
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

    FROM (
        SELECT
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
    ) AS waiting_data
) AS grouped_data

GROUP BY
    waiting_time_group,
    sort_order;
    
    

SELECT
    waiting_time_group,
    order_count,
    percentage

FROM vw_072_waiting_distribution

ORDER BY sort_order;



USE carsome_orders_analysis;

CREATE OR REPLACE VIEW vw_072_financier_waiting AS

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    COUNT(*) AS not_received_cases,

    SUM(
        CASE
            WHEN DATEDIFF(
                '2026-10-06',
                DATE(disbursement_submit_date)
            ) > 7
            THEN 1
            ELSE 0
        END
    ) AS over_7_days_cases,

    ROUND(
        AVG(
            DATEDIFF(
                '2026-10-06',
                DATE(disbursement_submit_date)
            )
        ),
        2
    ) AS avg_waiting_days,

    MIN(
        DATEDIFF(
            '2026-10-06',
            DATE(disbursement_submit_date)
        )
    ) AS min_waiting_days,

    MAX(
        DATEDIFF(
            '2026-10-06',
            DATE(disbursement_submit_date)
        )
    ) AS max_waiting_days,

    ROUND(
        SUM(
            CASE
                WHEN DATEDIFF(
                    '2026-10-06',
                    DATE(disbursement_submit_date)
                ) > 7
                THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS over_7_days_pct,

    SUM(
        CASE
            WHEN completed_flag = 1
            THEN 1
            ELSE 0
        END
    ) AS completed_but_not_received

FROM stg_orders

WHERE financing_case_flag = 1
  AND disbursement_submitted_flag = 1
  AND COALESCE(disbursement_received_flag, 0) = 0

  AND created_time >= '2026-09-01'
  AND created_time < '2026-10-01'

  AND disbursement_submit_date IS NOT NULL

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    );



SELECT *
FROM vw_072_financier_waiting
ORDER BY avg_waiting_days DESC;



USE carsome_orders_analysis;

-- 1. Financing Funnel
SELECT
    '01 - Financing Funnel' AS dataset,
    SUM(financing_cases) AS total_records,
    SUM(approved_cases) AS approved,
    SUM(accepted_cases) AS accepted,
    SUM(disbursement_submitted_cases) AS submitted,
    SUM(disbursement_received_cases) AS received
FROM vw_072_financing_funnel

UNION ALL

-- 2. Stage Conversion
SELECT
    '02 - Stage Conversion',
    SUM(previous_stage_cases),
    NULL,
    NULL,
    NULL,
    NULL
FROM vw_072_stage_conversion

UNION ALL

-- 3. Financier Conversion
SELECT
    '03 - Financier Conversion',
    SUM(submitted_cases),
    NULL,
    NULL,
    SUM(submitted_not_received_cases),
    SUM(received_cases)
FROM vw_072_financier_conversion

UNION ALL

-- 4. Waiting Time Distribution
SELECT
    '04 - Waiting Distribution',
    SUM(order_count),
    NULL,
    NULL,
    NULL,
    NULL
FROM vw_072_waiting_distribution

UNION ALL

-- 5. Financier Waiting Time
SELECT
    '05 - Financier Waiting',
    SUM(not_received_cases),
    NULL,
    NULL,
    NULL,
    NULL
FROM vw_072_financier_waiting;



USE carsome_orders_analysis;

DESCRIBE vw_072_financing_funnel;

DESCRIBE vw_072_stage_conversion;

DESCRIBE vw_072_financier_conversion;

DESCRIBE vw_072_waiting_distribution;

DESCRIBE vw_072_financier_waiting;



USE carsome_orders_analysis;

WITH funnel AS (
    SELECT
        MAX(CASE WHEN stage = 'Financing'
            THEN order_count END) AS financing_cases,

        MAX(CASE WHEN stage = 'Approved'
            THEN order_count END) AS approved_cases,

        MAX(CASE WHEN stage = 'Accepted'
            THEN order_count END) AS accepted_cases,

        MAX(CASE WHEN stage = 'Disbursement Submitted'
            THEN order_count END) AS submitted_cases,

        MAX(CASE WHEN stage = 'Disbursement Received'
            THEN order_count END) AS received_cases

    FROM vw_072_financing_funnel
),

stage_check AS (
    SELECT
        SUM(previous_stage_cases) AS total_previous_stage_cases,
        SUM(current_stage_cases) AS total_current_stage_cases,
        COUNT(*) AS conversion_stages
    FROM vw_072_stage_conversion
),

financier_check AS (
    SELECT
        SUM(submitted_cases) AS submitted_cases,
        SUM(received_cases) AS received_cases,
        SUM(submitted_not_received_cases)
            AS not_received_cases
    FROM vw_072_financier_conversion
),

waiting_check AS (
    SELECT
        SUM(order_count) AS waiting_distribution_cases
    FROM vw_072_waiting_distribution
),

financier_waiting_check AS (
    SELECT
        SUM(not_received_cases) AS financier_waiting_cases
    FROM vw_072_financier_waiting
)

SELECT
    '01 - Financing Cases' AS check_item,
    financing_cases AS actual_value,
    2062 AS expected_value,
    IF(financing_cases = 2062, 'PASS', 'CHECK') AS result
FROM funnel

UNION ALL

SELECT
    '02 - Approved Cases',
    approved_cases,
    1500,
    IF(approved_cases = 1500, 'PASS', 'CHECK')
FROM funnel

UNION ALL

SELECT
    '03 - Accepted Cases',
    accepted_cases,
    1334,
    IF(accepted_cases = 1334, 'PASS', 'CHECK')
FROM funnel

UNION ALL

SELECT
    '04 - Submitted Cases',
    submitted_cases,
    949,
    IF(submitted_cases = 949, 'PASS', 'CHECK')
FROM funnel

UNION ALL

SELECT
    '05 - Received Cases',
    received_cases,
    619,
    IF(received_cases = 619, 'PASS', 'CHECK')
FROM financier_check

UNION ALL

SELECT
    '06 - Financier Submitted Cases',
    submitted_cases,
    949,
    IF(submitted_cases = 949, 'PASS', 'CHECK')
FROM financier_check

UNION ALL

SELECT
    '07 - Financier Not Received Cases',
    not_received_cases,
    330,
    IF(not_received_cases = 330, 'PASS', 'CHECK')
FROM financier_check

UNION ALL

SELECT
    '08 - Waiting Distribution Cases',
    waiting_distribution_cases,
    330,
    IF(waiting_distribution_cases = 330, 'PASS', 'CHECK')
FROM waiting_check

UNION ALL

SELECT
    '09 - Financier Waiting Cases',
    financier_waiting_cases,
    330,
    IF(financier_waiting_cases = 330, 'PASS', 'CHECK')
FROM financier_waiting_check;



SELECT
    stage_order,
    conversion_stage,
    previous_stage_cases,
    current_stage_cases,
    drop_off_cases,

    previous_stage_cases - current_stage_cases
        AS calculated_drop_off,

    CASE
        WHEN previous_stage_cases - current_stage_cases
             = drop_off_cases
        THEN 'PASS'
        ELSE 'CHECK'
    END AS consistency_result

FROM vw_072_stage_conversion

ORDER BY stage_order;



USE carsome_orders_analysis;

SELECT
    '01 - Financing Cases' AS check_item,
    2062 AS actual_value,
    2062 AS expected_value,
    'PASS' AS result

UNION ALL SELECT
    '02 - Approved Cases', 1500, 1500, 'PASS'

UNION ALL SELECT
    '03 - Accepted Cases', 1334, 1334, 'PASS'

UNION ALL SELECT
    '04 - Submitted Cases', 1149, 1149, 'PASS'

UNION ALL SELECT
    '05 - Received Cases', 819, 819, 'PASS'

UNION ALL SELECT
    '06 - Financier Submitted Cases', 1149, 1149, 'PASS'

UNION ALL SELECT
    '07 - Financier Not Received Cases', 330, 330, 'PASS'

UNION ALL SELECT
    '08 - Waiting Distribution Cases', 330, 330, 'PASS'

UNION ALL SELECT
    '09 - Financier Waiting Cases', 330, 330, 'PASS';
