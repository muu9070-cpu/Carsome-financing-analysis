
USE carsome_orders_analysis;

-- =====================================================
-- 06. Loan Amount Analysis
-- STEP 1: Discover loan amount-related columns
-- =====================================================

-- RESULT 1: Identify relevant columns in stg_orders
SELECT
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    COLUMN_COMMENT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'carsome_orders_analysis'
  AND TABLE_NAME = 'stg_orders'
  AND (
       LOWER(COLUMN_NAME) LIKE '%loan%'
    OR LOWER(COLUMN_NAME) LIKE '%amount%'
    OR LOWER(COLUMN_NAME) LIKE '%slash%'
    OR LOWER(COLUMN_NAME) LIKE '%remark%'
    OR LOWER(COLUMN_NAME) LIKE '%status%'
    OR LOWER(COLUMN_NAME) LIKE '%financ%'
  )
ORDER BY ORDINAL_POSITION;


-- RESULT 2: Inspect existing loan amount field
SELECT
    COUNT(*) AS total_records,
    COUNT(loan_amount) AS non_null_loan_amount,
    SUM(CASE
        WHEN loan_amount IS NULL THEN 1 ELSE 0
    END) AS null_loan_amount,
    MIN(loan_amount) AS min_loan_amount,
    MAX(loan_amount) AS max_loan_amount,
    AVG(loan_amount) AS avg_loan_amount,
    SUM(CASE
        WHEN loan_amount <= 0 THEN 1 ELSE 0
    END) AS non_positive_amount_records
FROM stg_orders;



USE carsome_orders_analysis;

-- =====================================================
-- 06. Loan Amount Analysis
-- STEP 2: Validate amount field definitions
-- =====================================================


-- RESULT 1: Compare completeness of candidate amount fields

SELECT
    COUNT(*) AS total_records,

    SUM(CASE
        WHEN loan_amount IS NOT NULL
        THEN 1 ELSE 0
    END) AS loan_amount_records,

    SUM(CASE
        WHEN fis___loan IS NOT NULL
        THEN 1 ELSE 0
    END) AS fis_loan_records,

    SUM(CASE
        WHEN loan_amount IS NOT NULL
         AND fis___loan IS NOT NULL
        THEN 1 ELSE 0
    END) AS both_amounts_available,

    SUM(CASE
        WHEN loan_amount IS NOT NULL
         AND fis___loan IS NULL
        THEN 1 ELSE 0
    END) AS loan_amount_only,

    SUM(CASE
        WHEN loan_amount IS NULL
         AND fis___loan IS NOT NULL
        THEN 1 ELSE 0
    END) AS fis_loan_only,

    SUM(CASE
        WHEN loan_amount IS NULL
         AND fis___loan IS NULL
        THEN 1 ELSE 0
    END) AS both_amounts_missing

FROM stg_orders;


-- RESULT 2: Statistical comparison of both fields

SELECT
    'loan_amount' AS amount_field,
    COUNT(*) AS non_null_records,
    MIN(loan_amount) AS min_amount,
    MAX(loan_amount) AS max_amount,
    ROUND(AVG(loan_amount), 2) AS avg_amount,
    ROUND(SUM(loan_amount), 2) AS total_amount
FROM stg_orders
WHERE loan_amount IS NOT NULL

UNION ALL

SELECT
    'fis___loan',
    COUNT(*),
    MIN(fis___loan),
    MAX(fis___loan),
    ROUND(AVG(fis___loan), 2),
    ROUND(SUM(fis___loan), 2)
FROM stg_orders
WHERE fis___loan IS NOT NULL;


-- RESULT 3: Compare two amount fields by loan status

SELECT
    COALESCE(NULLIF(TRIM(final_loan_status), ''),
             'Missing / Blank') AS final_loan_status,

    COUNT(*) AS total_records,

    COUNT(loan_amount) AS loan_amount_records,

    COUNT(fis___loan) AS fis_loan_records,

    SUM(CASE
        WHEN loan_amount IS NOT NULL
         AND fis___loan IS NOT NULL
        THEN 1 ELSE 0
    END) AS both_amounts_available,

    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,

    ROUND(AVG(fis___loan), 2) AS avg_fis_loan

FROM stg_orders

GROUP BY
    COALESCE(NULLIF(TRIM(final_loan_status), ''),
             'Missing / Blank')

ORDER BY total_records DESC;


-- RESULT 4: Compare the two amounts at record level

SELECT
    CASE
        WHEN loan_amount IS NULL
             AND fis___loan IS NULL
            THEN 'Both Missing'

        WHEN loan_amount IS NOT NULL
             AND fis___loan IS NULL
            THEN 'Loan Amount Only'

        WHEN loan_amount IS NULL
             AND fis___loan IS NOT NULL
            THEN 'FIS Loan Only'

        WHEN loan_amount = fis___loan
            THEN 'Amounts Equal'

        WHEN fis___loan < loan_amount
            THEN 'FIS Loan Lower'

        WHEN fis___loan > loan_amount
            THEN 'FIS Loan Higher'
    END AS amount_relationship,

    COUNT(*) AS case_count

FROM stg_orders

GROUP BY amount_relationship

ORDER BY case_count DESC;


-- RESULT 5: Inspect financing status categories

SELECT
    COALESCE(NULLIF(TRIM(final_loan_status), ''),
             'Missing / Blank') AS final_loan_status,

    COALESCE(NULLIF(TRIM(final_status_remark), ''),
             'Missing / Blank') AS final_status_remark,

    COUNT(*) AS case_count

FROM stg_orders

GROUP BY
    COALESCE(NULLIF(TRIM(final_loan_status), ''),
             'Missing / Blank'),
    COALESCE(NULLIF(TRIM(final_status_remark), ''),
             'Missing / Blank')

ORDER BY case_count DESC;


USE carsome_orders_analysis;

-- =====================================================
-- 06. Loan Amount Analysis
-- STEP 3: Loan Amount Business Validation
-- =====================================================


-- RESULT 1: Loan amount by financing stage

SELECT
    CASE
        WHEN COALESCE(financing_case_flag, 0) = 1
            THEN 'Financing Case'
        ELSE 'Non-Financing Case'
    END AS financing_group,

    CASE
        WHEN COALESCE(approved_flag, 0) = 1
            THEN 'Approved'
        ELSE 'Not Approved'
    END AS approval_group,

    CASE
        WHEN COALESCE(accepted_flag, 0) = 1
            THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS acceptance_group,

    COUNT(*) AS total_records,
    COUNT(loan_amount) AS loan_amount_records,

    ROUND(MIN(loan_amount), 2) AS min_loan_amount,
    ROUND(MAX(loan_amount), 2) AS max_loan_amount,
    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,
    ROUND(SUM(loan_amount), 2) AS total_loan_amount

FROM stg_orders

GROUP BY
    financing_group,
    approval_group,
    acceptance_group

ORDER BY total_records DESC;


-- RESULT 2: Check distinct values of fis___loan

SELECT
    fis___loan,
    COUNT(*) AS case_count

FROM stg_orders

WHERE fis___loan IS NOT NULL

GROUP BY fis___loan

ORDER BY case_count DESC;


-- RESULT 3: Loan amount by final order status

SELECT
    COALESCE(NULLIF(TRIM(order_status), ''),
             'Missing / Blank') AS order_status,

    COUNT(*) AS total_records,
    COUNT(loan_amount) AS loan_amount_records,

    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,
    ROUND(MIN(loan_amount), 2) AS min_loan_amount,
    ROUND(MAX(loan_amount), 2) AS max_loan_amount

FROM stg_orders

GROUP BY
    COALESCE(NULLIF(TRIM(order_status), ''),
             'Missing / Blank')

ORDER BY total_records DESC;


-- RESULT 4: Identify remarks that mention loan reduction

SELECT
    CASE
        WHEN UPPER(final_status_remark) LIKE '%SLASH%'
            THEN 'Contains SLASH'

        WHEN UPPER(final_status_remark) LIKE '%REDUCE LOAN%'
            THEN 'Contains REDUCE LOAN'

        WHEN UPPER(final_status_remark) LIKE '%REDUCE LOAN AMOUNT%'
            THEN 'Contains REDUCE LOAN AMOUNT'

        WHEN UPPER(final_status_remark) LIKE '%APPROVED AMOUNT%'
            THEN 'Contains APPROVED AMOUNT'

        WHEN UPPER(final_status_remark) LIKE '%LOAN MATCH%'
            THEN 'Contains LOAN MATCH'

        ELSE 'Other Remarks'
    END AS remark_category,

    COUNT(*) AS case_count,

    SUM(CASE
        WHEN loan_amount IS NOT NULL
        THEN 1 ELSE 0
    END) AS records_with_loan_amount,

    SUM(CASE
        WHEN loan_amount IS NULL
        THEN 1 ELSE 0
    END) AS records_without_loan_amount

FROM stg_orders

GROUP BY remark_category

ORDER BY case_count DESC;


-- RESULT 5: Aggregate slash remark indicators

SELECT
    COUNT(*) AS total_records,

    SUM(CASE
        WHEN UPPER(final_status_remark) LIKE '%SLASH%'
        THEN 1 ELSE 0
    END) AS slash_mentioned_records,

    SUM(CASE
        WHEN UPPER(final_status_remark) LIKE '%REDUCE LOAN%'
        THEN 1 ELSE 0
    END) AS reduce_loan_mentioned_records,

    SUM(CASE
        WHEN UPPER(final_status_remark) LIKE '%APPROVED AMOUNT%'
        THEN 1 ELSE 0
    END) AS approved_amount_mentioned_records,

    SUM(CASE
        WHEN UPPER(final_status_remark) LIKE '%LOAN MATCH%'
        THEN 1 ELSE 0
    END) AS loan_match_mentioned_records

FROM stg_orders;




USE carsome_orders_analysis;

-- =====================================================
-- 06. Loan Amount Analysis
-- STEP 4: Loan Slash Case Distribution
-- =====================================================


-- RESULT 1: Slash cases by financier and order status

SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,

    COALESCE(NULLIF(TRIM(order_status), ''),
             'Missing / Blank') AS order_status,

    COUNT(*) AS slash_cases,

    SUM(CASE
        WHEN loan_amount IS NOT NULL
        THEN 1 ELSE 0
    END) AS with_loan_amount,

    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,

    ROUND(MIN(loan_amount), 2) AS min_loan_amount,

    ROUND(MAX(loan_amount), 2) AS max_loan_amount

FROM stg_orders

WHERE UPPER(COALESCE(final_status_remark, '')) LIKE '%SLASH%'

GROUP BY
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank'),
    COALESCE(NULLIF(TRIM(order_status), ''),
             'Missing / Blank')

ORDER BY slash_cases DESC;


-- RESULT 2: Slash cases by loan amount range

SELECT
    CASE
        WHEN loan_amount IS NULL
            THEN 'Missing Amount'
        WHEN loan_amount < 20000
            THEN 'Below RM20,000'
        WHEN loan_amount < 40000
            THEN 'RM20,000 - RM39,999'
        WHEN loan_amount < 60000
            THEN 'RM40,000 - RM59,999'
        WHEN loan_amount < 80000
            THEN 'RM60,000 - RM79,999'
        ELSE 'RM80,000 and Above'
    END AS loan_amount_band,

    COUNT(*) AS slash_cases,

    ROUND(AVG(loan_amount), 2) AS avg_loan_amount

FROM stg_orders

WHERE UPPER(COALESCE(final_status_remark, '')) LIKE '%SLASH%'

GROUP BY loan_amount_band

ORDER BY
    CASE loan_amount_band
        WHEN 'Below RM20,000' THEN 1
        WHEN 'RM20,000 - RM39,999' THEN 2
        WHEN 'RM40,000 - RM59,999' THEN 3
        WHEN 'RM60,000 - RM79,999' THEN 4
        WHEN 'RM80,000 and Above' THEN 5
        ELSE 6
    END;


-- RESULT 3: Compare slash-mentioned and non-slash cases

SELECT
    CASE
        WHEN UPPER(COALESCE(final_status_remark, ''))
             LIKE '%SLASH%'
            THEN 'Slash Mentioned'
        ELSE 'No Slash Mention'
    END AS slash_group,

    COUNT(*) AS total_records,

    COUNT(loan_amount) AS records_with_loan_amount,

    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,

    ROUND(MIN(loan_amount), 2) AS min_loan_amount,

    ROUND(MAX(loan_amount), 2) AS max_loan_amount

FROM stg_orders

GROUP BY slash_group

ORDER BY slash_group;



USE carsome_orders_analysis;

-- =====================================================
-- 06. Loan Amount Analysis
-- STEP 5: Extract Loan Slash Amount from Remarks
-- =====================================================

-- RESULT 1: Extraction coverage

WITH slash_records AS (
    SELECT
        final_status_remark,
        loan_amount,
        REGEXP_SUBSTR(
            UPPER(final_status_remark),
            '(SLASH|SLASHED)[^0-9]{0,30}RM[[:space:]]*[0-9,]+'
        ) AS slash_amount_text
    FROM stg_orders
    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
)
SELECT
    COUNT(*) AS total_slash_records,

    SUM(CASE
        WHEN slash_amount_text IS NOT NULL
        THEN 1 ELSE 0
    END) AS extracted_amount_records,

    SUM(CASE
        WHEN slash_amount_text IS NULL
        THEN 1 ELSE 0
    END) AS unextracted_records,

    ROUND(
        100.0 * SUM(
            CASE WHEN slash_amount_text IS NOT NULL
                 THEN 1 ELSE 0 END
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS extraction_rate_pct

FROM slash_records;


-- RESULT 2: Extracted slash amount distribution

WITH slash_records AS (
    SELECT
        REGEXP_SUBSTR(
            UPPER(final_status_remark),
            '(SLASH|SLASHED)[^0-9]{0,30}RM[[:space:]]*[0-9,]+'
        ) AS slash_amount_text
    FROM stg_orders
    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),
parsed AS (
    SELECT
        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    slash_amount_text,
                    '.*RM[[:space:]]*',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS slash_amount
    FROM slash_records
    WHERE slash_amount_text IS NOT NULL
)
SELECT
    COUNT(*) AS extracted_cases,
    ROUND(MIN(slash_amount), 2) AS min_slash_amount,
    ROUND(MAX(slash_amount), 2) AS max_slash_amount,
    ROUND(AVG(slash_amount), 2) AS avg_slash_amount,
    ROUND(SUM(slash_amount), 2) AS total_slash_amount
FROM parsed;


-- RESULT 3: Extracted slash amount frequency

WITH slash_records AS (
    SELECT
        REGEXP_SUBSTR(
            UPPER(final_status_remark),
            '(SLASH|SLASHED)[^0-9]{0,30}RM[[:space:]]*[0-9,]+'
        ) AS slash_amount_text
    FROM stg_orders
    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),
parsed AS (
    SELECT
        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    slash_amount_text,
                    '.*RM[[:space:]]*',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS slash_amount
    FROM slash_records
    WHERE slash_amount_text IS NOT NULL
)
SELECT
    slash_amount,
    COUNT(*) AS case_count
FROM parsed
GROUP BY slash_amount
ORDER BY case_count DESC, slash_amount;


-- RESULT 4: Inspect unextracted slash remarks
-- No order identifiers or customer details are selected.

SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,

    COALESCE(NULLIF(TRIM(order_status), ''),
             'Missing / Blank') AS order_status,

    loan_amount,

    LEFT(final_status_remark, 250) AS remark_sample

FROM stg_orders

WHERE UPPER(COALESCE(final_status_remark, ''))
      LIKE '%SLASH%'

AND REGEXP_SUBSTR(
        UPPER(final_status_remark),
        '(SLASH|SLASHED)[^0-9]{0,30}RM[[:space:]]*[0-9,]+'
    ) IS NULL

LIMIT 20;



USE carsome_orders_analysis;

-- =====================================================
-- 06 STEP 6: Improved Loan Amount Extraction
-- Purpose:
-- 1. Extract Approved Amount
-- 2. Extract Slash Amount
-- 3. Compare extracted Approved Amount with loan_amount
-- 4. Identify extraction coverage and exceptions
-- =====================================================

WITH extracted AS (
    SELECT
        order_status,
        final_financier,
        loan_amount,
        final_status_remark,

        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            'APPROVED[[:space:]]+(LOAN[[:space:]]+)?AMOUNT[[:space:]]*:?[[:space:]]*RM[[:space:]]*[0-9,]+(\\.[0-9]{1,2})?'
        ) AS approved_text,

        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            '(SLASHED|SLASH)[[:space:]]+(RM[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]{1,2})?(?![[:space:]]*(YEARS?|MONTHS?))'
        ) AS slash_text

    FROM stg_orders
    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),

parsed AS (
    SELECT
        order_status,
        final_financier,
        loan_amount,
        final_status_remark,

        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    approved_text,
                    '^.*RM[[:space:]]*',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS approved_amount_extracted,

        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    slash_text,
                    '^(SLASHED|SLASH)[[:space:]]*(RM[[:space:]]*)?',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS slash_amount_extracted

    FROM extracted
)

-- RESULT 1: Extraction coverage
SELECT
    COUNT(*) AS total_slash_records,

    SUM(CASE
        WHEN approved_amount_extracted IS NOT NULL
        THEN 1 ELSE 0
    END) AS approved_amount_extracted_cases,

    SUM(CASE
        WHEN slash_amount_extracted IS NOT NULL
        THEN 1 ELSE 0
    END) AS slash_amount_extracted_cases,

    SUM(CASE
        WHEN approved_amount_extracted IS NOT NULL
         AND slash_amount_extracted IS NOT NULL
        THEN 1 ELSE 0
    END) AS both_amounts_extracted,

    SUM(CASE
        WHEN slash_amount_extracted = 0
        THEN 1 ELSE 0
    END) AS zero_slash_amount_cases

FROM parsed;


-- RESULT 2: Compare approved amount with loan_amount
WITH extracted AS (
    SELECT
        loan_amount,
        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            'APPROVED[[:space:]]+(LOAN[[:space:]]+)?AMOUNT[[:space:]]*:?[[:space:]]*RM[[:space:]]*[0-9,]+(\\.[0-9]{1,2})?'
        ) AS approved_text
    FROM stg_orders
    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),
parsed AS (
    SELECT
        loan_amount,
        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    approved_text,
                    '^.*RM[[:space:]]*',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS approved_amount
    FROM extracted
)
SELECT
    COUNT(*) AS comparable_records,

    SUM(CASE
        WHEN loan_amount = approved_amount
        THEN 1 ELSE 0
    END) AS exact_match_cases,

    SUM(CASE
        WHEN loan_amount <> approved_amount
        THEN 1 ELSE 0
    END) AS mismatch_cases,

    ROUND(
        100.0 * SUM(CASE
            WHEN loan_amount = approved_amount
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS match_rate_pct

FROM parsed
WHERE loan_amount IS NOT NULL
  AND approved_amount IS NOT NULL;


-- RESULT 3: Extracted slash amount statistics
WITH extracted AS (
    SELECT
        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            '(SLASHED|SLASH)[[:space:]]+(RM[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]{1,2})?(?![[:space:]]*(YEARS?|MONTHS?))'
        ) AS slash_text
    FROM stg_orders
    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),
parsed AS (
    SELECT
        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    slash_text,
                    '^(SLASHED|SLASH)[[:space:]]*(RM[[:space:]]*)?',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS slash_amount
    FROM extracted
)
SELECT
    COUNT(slash_amount) AS extracted_cases,
    ROUND(MIN(slash_amount), 2) AS min_slash_amount,
    ROUND(MAX(slash_amount), 2) AS max_slash_amount,
    ROUND(AVG(slash_amount), 2) AS avg_slash_amount,
    ROUND(SUM(slash_amount), 2) AS total_slash_amount
FROM parsed;


-- RESULT 4: Review cases with both amounts extracted
WITH extracted AS (
    SELECT
        final_financier,
        order_status,
        loan_amount,
        final_status_remark,

        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            'APPROVED[[:space:]]+(LOAN[[:space:]]+)?AMOUNT[[:space:]]*:?[[:space:]]*RM[[:space:]]*[0-9,]+(\\.[0-9]{1,2})?'
        ) AS approved_text,

        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            '(SLASHED|SLASH)[[:space:]]+(RM[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]{1,2})?(?![[:space:]]*(YEARS?|MONTHS?))'
        ) AS slash_text

    FROM stg_orders
    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
)
SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,

    order_status,
    loan_amount,

    CAST(
        REPLACE(
            REGEXP_REPLACE(
                approved_text,
                '^.*RM[[:space:]]*',
                ''
            ),
            ',',
            ''
        ) AS DECIMAL(15,2)
    ) AS approved_amount_extracted,

    CAST(
        REPLACE(
            REGEXP_REPLACE(
                slash_text,
                '^(SLASHED|SLASH)[[:space:]]*(RM[[:space:]]*)?',
                ''
            ),
            ',',
            ''
        ) AS DECIMAL(15,2)
    ) AS slash_amount_extracted

FROM extracted

WHERE approved_text IS NOT NULL
  AND slash_text IS NOT NULL

LIMIT 30;



USE carsome_orders_analysis;

-- =====================================================
-- 06 STEP 7: Validate extracted slash amounts
-- Show raw matched text alongside parsed amount.
-- No customer identifiers are selected.
-- =====================================================

WITH extracted AS (
    SELECT
        final_financier,
        order_status,
        loan_amount,

        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            '(SLASHED|SLASH)[[:space:]]+(RM[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]{1,2})?(?![[:space:]]*(YEARS?|MONTHS?))'
        ) AS slash_text

    FROM stg_orders

    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),

parsed AS (
    SELECT
        final_financier,
        order_status,
        loan_amount,
        slash_text,

        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    slash_text,
                    '^(SLASHED|SLASH)[[:space:]]*(RM[[:space:]]*)?',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS parsed_slash_amount

    FROM extracted

    WHERE slash_text IS NOT NULL
)

SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,

    order_status,
    loan_amount,
    slash_text AS original_matched_text,
    parsed_slash_amount,

    CASE
        WHEN parsed_slash_amount IS NULL
            THEN 'Parse Failed'
        WHEN parsed_slash_amount = 0
            THEN 'Zero Amount - Review'
        WHEN parsed_slash_amount < 100
            THEN 'Small Amount - Review'
        ELSE 'Needs Confirmation'
    END AS audit_status

FROM parsed

ORDER BY parsed_slash_amount ASC;



USE carsome_orders_analysis;

-- =====================================================
-- 06 STEP 8: Slash Amount Exception Review
-- Focus on suspicious small amounts and comma truncation.
-- =====================================================

WITH extracted AS (
    SELECT
        final_financier,
        order_status,
        loan_amount,
        final_status_remark,

        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            '(SLASHED|SLASH)[[:space:]]+(RM[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]{1,2})?(?![[:space:]]*(YEARS?|MONTHS?))'
        ) AS slash_text

    FROM stg_orders

    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),

parsed AS (
    SELECT
        final_financier,
        order_status,
        loan_amount,
        final_status_remark,
        slash_text,

        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    slash_text,
                    '^(SLASHED|SLASH)[[:space:]]*(RM[[:space:]]*)?',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS parsed_slash_amount

    FROM extracted
    WHERE slash_text IS NOT NULL
)

SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,

    order_status,
    loan_amount,
    slash_text AS matched_text,
    parsed_slash_amount,

    CASE
        WHEN parsed_slash_amount < 100
            THEN 'Small amount review'
        WHEN slash_text REGEXP ',[0-9]{1,2}$'
            THEN 'Possible comma truncation'
        ELSE 'Other'
    END AS audit_reason

FROM parsed

WHERE parsed_slash_amount < 100
   OR slash_text REGEXP ',[0-9]{1,2}$'

ORDER BY parsed_slash_amount;



USE carsome_orders_analysis;

WITH extracted AS (
    SELECT
        final_financier,
        order_status,
        loan_amount,
        final_status_remark,

        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            '(SLASHED|SLASH)[[:space:]]+(RM[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]{1,2})?(?![[:space:]]*(YEARS?|MONTHS?))'
        ) AS slash_text

    FROM stg_orders

    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),

parsed AS (
    SELECT
        *,
        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    slash_text,
                    '^(SLASHED|SLASH)[[:space:]]*(RM[[:space:]]*)?',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS parsed_slash_amount

    FROM extracted

    WHERE slash_text IS NOT NULL
)

SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,

    order_status,
    loan_amount,
    slash_text AS matched_text,
    parsed_slash_amount,

    final_status_remark AS full_original_remark

FROM parsed

WHERE parsed_slash_amount < 100
   OR slash_text REGEXP ',[0-9]{1,2}$'

ORDER BY parsed_slash_amount;



USE carsome_orders_analysis;

-- ============================================================
-- 06 STEP 9: FULL LOAN SLASH AMOUNT RECONCILIATION
--
-- Source: stg_orders
-- Scope : All records containing SLASH in final_status_remark
--
-- Rules:
-- 1. Extract RM amounts, comma-separated amounts and K amounts.
-- 2. Reject slash followed by date-like values such as 22/9.
-- 3. Apply 9 manually validated overrides.
-- 4. Keep 1 ambiguous Ambank record unverified.
-- 5. Do not modify source data.
-- ============================================================

DROP TEMPORARY TABLE IF EXISTS tmp_06_slash_audit;

CREATE TEMPORARY TABLE tmp_06_slash_audit AS

WITH source_data AS (
    SELECT
        final_financier AS financier,
        order_status,
        loan_amount,
        final_status_remark,

        REGEXP_SUBSTR(
            UPPER(COALESCE(final_status_remark, '')),
            '(SLASHED?|LOAN[[:space:]]+SLASHED?)[[:space:]]*(RM[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]+)?[[:space:]]*(K)?(?![[:space:]]*/[[:space:]]*[0-9])'
        ) AS matched_text

    FROM stg_orders

    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),

parsed AS (
    SELECT
        financier,
        order_status,
        loan_amount,
        final_status_remark,
        matched_text,

        CAST(
            REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(
                        REGEXP_REPLACE(
                            matched_text,
                            '^(SLASHED?|LOAN[[:space:]]+SLASHED?)[[:space:]]*(RM[[:space:]]*)?',
                            ''
                        ),
                        '[[:space:]]*K$',
                        ''
                    ),
                    '[[:space:]]',
                    ''
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        ) AS raw_amount,

        CASE
            WHEN UPPER(TRIM(matched_text)) REGEXP 'K$'
                THEN 1000
            ELSE 1
        END AS amount_multiplier

    FROM source_data
),

calculated AS (
    SELECT
        financier,
        order_status,
        loan_amount,
        final_status_remark,
        matched_text,

        CASE
            WHEN raw_amount IS NOT NULL
            THEN raw_amount * amount_multiplier
            ELSE NULL
        END AS auto_slash_amount

    FROM parsed
),

finalized AS (
    SELECT
        financier,
        order_status,
        loan_amount,
        matched_text,
        auto_slash_amount,

        CASE

            -- Manual validation 1
            WHEN financier = 'Toyota Capital'
             AND order_status = 'Pending E-hak Milik'
             AND loan_amount = 56500
             AND final_status_remark LIKE '%LOAN SLASH RM2K%'
                THEN 2000

            -- Manual validation 2
            WHEN financier = 'Toyota Capital'
             AND order_status = 'Order Completed'
             AND loan_amount = 34000
             AND final_status_remark LIKE '%LOAN SLASH RM3.7K%'
                THEN 3700

            -- Manual validation 3
            WHEN financier = 'Public Bank Berhad'
             AND order_status = 'Order Completed'
             AND loan_amount = 73000
             AND final_status_remark LIKE '%LOAN SLASH RM4K%'
                THEN 4000

            -- Manual validation 4
            WHEN financier = 'Carsome Capital'
             AND order_status = 'Order Closed'
             AND loan_amount = 50000
             AND final_status_remark LIKE '%LOAN SLASH RM15K%'
                THEN 15000

            -- Manual validation 5: ambiguous, do not infer RM22K
            WHEN financier = 'Ambank'
             AND order_status = 'Order Completed'
             AND loan_amount = 50000
             AND final_status_remark LIKE '%AMBANK SLASH%'
             AND final_status_remark LIKE '%reduce loan amount to RM50k%'
                THEN NULL

            -- Manual validation 6
            WHEN financier = 'Carsome Capital'
             AND order_status = 'Order Completed'
             AND loan_amount = 13300
             AND final_status_remark LIKE '%loan slashed RM50%'
                THEN 50

            -- Manual validation 7
            WHEN financier = 'Ambank'
             AND order_status = 'Order Completed'
             AND loan_amount = 51000
             AND final_status_remark LIKE '%LOAN SLASH RM50%'
                THEN 50

            -- Manual validation 8
            WHEN financier = 'Affin Bank Berhad'
             AND order_status = 'Order Completed'
             AND loan_amount = 65700
             AND final_status_remark LIKE '%slashed 800%'
                THEN 800

            -- Manual validation 9
            WHEN financier = 'Maybank'
             AND order_status = 'Pending Deliver'
             AND loan_amount = 80100
             AND final_status_remark LIKE '%slashed 3,400%'
                THEN 3400

            -- Manual validation 10
            WHEN financier = 'Public Bank Berhad'
             AND order_status = 'Pending E-hak Milik'
             AND loan_amount = 50000
             AND final_status_remark LIKE '%slashed 11,200%'
                THEN 11200

            ELSE auto_slash_amount
        END AS final_slash_amount,

        CASE

            WHEN financier = 'Ambank'
             AND order_status = 'Order Completed'
             AND loan_amount = 50000
             AND final_status_remark LIKE '%AMBANK SLASH%'
             AND final_status_remark LIKE '%reduce loan amount to RM50k%'
                THEN 'Unable to Verify'

            WHEN financier = 'Toyota Capital'
             AND order_status = 'Pending E-hak Milik'
             AND loan_amount = 56500
             AND final_status_remark LIKE '%LOAN SLASH RM2K%'
                THEN 'Manually Verified'

            WHEN financier = 'Toyota Capital'
             AND order_status = 'Order Completed'
             AND loan_amount = 34000
             AND final_status_remark LIKE '%LOAN SLASH RM3.7K%'
                THEN 'Manually Verified'

            WHEN financier = 'Public Bank Berhad'
             AND order_status = 'Order Completed'
             AND loan_amount = 73000
             AND final_status_remark LIKE '%LOAN SLASH RM4K%'
                THEN 'Manually Verified'

            WHEN financier = 'Carsome Capital'
             AND order_status = 'Order Closed'
             AND loan_amount = 50000
             AND final_status_remark LIKE '%LOAN SLASH RM15K%'
                THEN 'Manually Verified'

            WHEN financier = 'Carsome Capital'
             AND order_status = 'Order Completed'
             AND loan_amount = 13300
             AND final_status_remark LIKE '%loan slashed RM50%'
                THEN 'Manually Verified'

            WHEN financier = 'Ambank'
             AND order_status = 'Order Completed'
             AND loan_amount = 51000
             AND final_status_remark LIKE '%LOAN SLASH RM50%'
                THEN 'Manually Verified'

            WHEN financier = 'Affin Bank Berhad'
             AND order_status = 'Order Completed'
             AND loan_amount = 65700
             AND final_status_remark LIKE '%slashed 800%'
                THEN 'Manually Verified'

            WHEN financier = 'Maybank'
             AND order_status = 'Pending Deliver'
             AND loan_amount = 80100
             AND final_status_remark LIKE '%slashed 3,400%'
                THEN 'Manually Verified'

            WHEN financier = 'Public Bank Berhad'
             AND order_status = 'Pending E-hak Milik'
             AND loan_amount = 50000
             AND final_status_remark LIKE '%slashed 11,200%'
                THEN 'Manually Verified'

            WHEN auto_slash_amount IS NULL
                THEN 'Unable to Extract'

            WHEN matched_text REGEXP ',[0-9]{1,2}$'
                THEN 'Possible Truncation - Review'

            WHEN auto_slash_amount < 100
                THEN 'Small Amount - Review'

            ELSE 'Auto Extracted - Pending Validation'

        END AS validation_status

    FROM calculated
)

SELECT
    COALESCE(NULLIF(TRIM(financier), ''),
             'Missing / Blank') AS financier,

    order_status,
    loan_amount,
    matched_text,
    auto_slash_amount,
    final_slash_amount,
    validation_status

FROM finalized;


-- ============================================================
-- RESULT 1: FULL CASE-LEVEL RECONCILIATION
-- ============================================================

SELECT
    financier,
    order_status,
    loan_amount,
    matched_text,
    auto_slash_amount,
    final_slash_amount,
    validation_status

FROM tmp_06_slash_audit

ORDER BY
    CASE validation_status
        WHEN 'Unable to Verify' THEN 1
        WHEN 'Unable to Extract' THEN 2
        WHEN 'Possible Truncation - Review' THEN 3
        WHEN 'Small Amount - Review' THEN 4
        WHEN 'Manually Verified' THEN 5
        ELSE 6
    END,
    financier;


-- ============================================================
-- RESULT 2: OVERALL RECONCILIATION SUMMARY
-- ============================================================

SELECT
    COUNT(*) AS total_slash_records,

    SUM(CASE
        WHEN final_slash_amount IS NOT NULL
        THEN 1 ELSE 0
    END) AS records_with_confirmed_candidate_amount,

    SUM(CASE
        WHEN validation_status = 'Manually Verified'
        THEN 1 ELSE 0
    END) AS manually_verified_records,

    SUM(CASE
        WHEN validation_status = 'Auto Extracted - Pending Validation'
        THEN 1 ELSE 0
    END) AS auto_extracted_pending_validation,

    SUM(CASE
        WHEN validation_status = 'Unable to Verify'
        THEN 1 ELSE 0
    END) AS unable_to_verify_records,

    SUM(CASE
        WHEN validation_status = 'Unable to Extract'
        THEN 1 ELSE 0
    END) AS unable_to_extract_records,

    SUM(CASE
        WHEN validation_status = 'Possible Truncation - Review'
        THEN 1 ELSE 0
    END) AS possible_truncation_records,

    SUM(CASE
        WHEN validation_status = 'Small Amount - Review'
        THEN 1 ELSE 0
    END) AS small_amount_review_records,

    ROUND(
        SUM(final_slash_amount),
        2
    ) AS total_candidate_slash_amount

FROM tmp_06_slash_audit;


-- ============================================================
-- RESULT 3: FINANCIER-LEVEL SLASH DISTRIBUTION
-- ============================================================

SELECT
    financier,

    COUNT(*) AS slash_cases,

    SUM(CASE
        WHEN final_slash_amount IS NOT NULL
        THEN 1 ELSE 0
    END) AS amount_available_cases,

    ROUND(
        SUM(final_slash_amount),
        2
    ) AS total_candidate_slash_amount,

    ROUND(
        AVG(final_slash_amount),
        2
    ) AS avg_candidate_slash_amount,

    SUM(CASE
        WHEN validation_status = 'Unable to Verify'
        THEN 1 ELSE 0
    END) AS unable_to_verify_cases

FROM tmp_06_slash_audit

GROUP BY financier

ORDER BY total_candidate_slash_amount DESC;


-- ============================================================
-- RESULT 4: UNRESOLVED CASES
-- ============================================================

SELECT
    financier,
    order_status,
    loan_amount,
    matched_text,
    auto_slash_amount,
    validation_status

FROM tmp_06_slash_audit

WHERE validation_status IN (
    'Unable to Verify',
    'Unable to Extract',
    'Possible Truncation - Review',
    'Small Amount - Review'
)

ORDER BY financier;



USE carsome_orders_analysis;

-- =====================================================
-- 06 STEP 9.1: INVESTIGATE UNEXTRACTED SLASH REMARKS
-- =====================================================

SELECT
    COALESCE(NULLIF(TRIM(final_financier), ''),
             'Missing / Blank') AS financier,

    order_status,
    loan_amount,

    final_status_remark AS full_remark,

    CASE
        WHEN UPPER(final_status_remark) REGEXP
             'SLASH[[:space:]]*$'
            THEN 'Slash mentioned without amount'

        WHEN UPPER(final_status_remark) REGEXP
             'SLASH[^0-9]*[0-9]+[[:space:]]*YEARS?'
            THEN 'Possible tenure instead of amount'

        WHEN UPPER(final_status_remark) LIKE '%APPROVED AMOUNT%'
            THEN 'Approved amount exists - slash amount unclear'

        WHEN UPPER(final_status_remark) LIKE '%REDUCE%'
            THEN 'Reduction wording - extraction rule missing'

        ELSE 'Other remark format - manual inspection'
    END AS investigation_category

FROM stg_orders

WHERE UPPER(COALESCE(final_status_remark, ''))
      LIKE '%SLASH%'

AND REGEXP_SUBSTR(
        UPPER(COALESCE(final_status_remark, '')),
        '(SLASHED?|LOAN[[:space:]]+SLASHED?)[[:space:]]*(RM[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]+)?[[:space:]]*(K)?(?![[:space:]]*/[[:space:]]*[0-9])'
    ) IS NULL

ORDER BY financier, order_status;




USE carsome_orders_analysis;

-- 06 Step 9.2
-- Identify Slash amounts missed by the previous extraction rules

SELECT
    final_financier AS financier,
    order_status,
    loan_amount,
    final_status_remark,

    REGEXP_SUBSTR(
        UPPER(final_status_remark),
        'SLASH(ED)?[^A-Z0-9]*RM[[:space:]]*[0-9,]+([.][0-9]+)?[[:space:]]*[K]?'
    ) AS matched_slash_text,

    CASE
        WHEN UPPER(final_status_remark) REGEXP
             'SLASH(ED)?[^A-Z0-9]*RM[[:space:]]*[0-9,]+[[:space:]]*K'
        THEN
            CAST(
                REPLACE(
                    REGEXP_SUBSTR(
                        UPPER(final_status_remark),
                        'SLASH(ED)?[^A-Z0-9]*RM[[:space:]]*[0-9,]+[[:space:]]*K'
                    ),
                    ',', ''
                ) AS CHAR
            )

        ELSE 'Review numeric extraction'
    END AS extraction_review

FROM stg_orders

WHERE UPPER(COALESCE(final_status_remark, '')) LIKE '%SLASH%'

AND (
    UPPER(final_status_remark) REGEXP
    'SLASH(ED)?[^A-Z0-9]*RM[[:space:]]*[0-9,]+([.][0-9]+)?[[:space:]]*[K]?'
)

ORDER BY final_financier, loan_amount;




USE carsome_orders_analysis;

-- =========================================================
-- 06 LOAN AMOUNT ANALYSIS
-- STEP 9: FULL LOAN SLASH AUDIT REBUILD
-- Source: stg_orders
-- No changes to original source data
-- MySQL 8.0+
-- =========================================================

DROP TEMPORARY TABLE IF EXISTS tmp_06_slash_audit;

CREATE TEMPORARY TABLE tmp_06_slash_audit AS

WITH source_data AS (
    SELECT
        order_id,
        summarised_order_id,
        final_financier,
        order_status,
        loan_amount,
        final_status_remark,

        UPPER(COALESCE(final_status_remark, '')) AS remark_upper

    FROM stg_orders

    WHERE UPPER(COALESCE(final_status_remark, ''))
          LIKE '%SLASH%'
),

matched_data AS (
    SELECT
        *,

        REGEXP_SUBSTR(
            remark_upper,
            'SLASH(ED)?[[:space:][:punct:]]{0,12}(RM[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]+)?[[:space:]]*K?'
        ) AS matched_text

    FROM source_data
),

parsed_data AS (
    SELECT
        *,

        CASE
            WHEN matched_text IS NOT NULL THEN
                REGEXP_REPLACE(
                    matched_text,
                    '^SLASH(ED)?[[:space:][:punct:]]{0,12}(RM[[:space:]]*)?',
                    ''
                )
            ELSE NULL
        END AS numeric_text

    FROM matched_data
),

cleaned_data AS (
    SELECT
        *,

        CASE
            WHEN numeric_text IS NOT NULL THEN
                REPLACE(
                    REPLACE(
                        REPLACE(
                            UPPER(numeric_text),
                            'K', ''
                        ),
                        ',', ''
                    ),
                    ' ', ''
                )
            ELSE NULL
        END AS clean_numeric_text

    FROM parsed_data
)

SELECT
    order_id,
    summarised_order_id,

    final_financier AS financier,
    order_status,
    loan_amount,
    final_status_remark AS full_remark,

    matched_text,
    clean_numeric_text,

    CASE
        WHEN matched_text IS NULL THEN NULL

        WHEN matched_text REGEXP 'K[[:space:]]*$'
        THEN CAST(clean_numeric_text AS DECIMAL(15,2)) * 1000

        ELSE CAST(clean_numeric_text AS DECIMAL(15,2))
    END AS auto_slash_amount,

    CAST(NULL AS DECIMAL(15,2)) AS manual_slash_amount,

    CAST(NULL AS DECIMAL(15,2)) AS final_slash_amount,

    CASE
        WHEN matched_text IS NULL
            THEN 'Unable to Extract'

        WHEN remark_upper REGEXP
             'SLASH(ED)?[[:space:][:punct:]]{0,12}[0-9]+[[:space:]]+YEARS?'
            THEN 'Unable to Extract'

        WHEN matched_text REGEXP
             '[0-9],[0-9]{1,2}([[:space:]]|$)'
            THEN 'Manual Review - Possible Comma Truncation'

        WHEN clean_numeric_text REGEXP '^[0-9]{1,2}$'
             AND matched_text NOT REGEXP 'RM'
             AND matched_text NOT REGEXP 'K[[:space:]]*$'
            THEN 'Manual Review - Small Amount'

        ELSE 'Auto Extracted - Pending Validation'
    END AS validation_status,

    CASE
        WHEN matched_text IS NULL
            THEN 'No directly identifiable numeric amount after Slash'

        WHEN remark_upper REGEXP
             'SLASH(ED)?[[:space:][:punct:]]{0,12}[0-9]+[[:space:]]+YEARS?'
            THEN 'Possible loan tenure, not a slash amount'

        WHEN matched_text REGEXP
             '[0-9],[0-9]{1,2}([[:space:]]|$)'
            THEN 'Possible incomplete comma-separated amount'

        WHEN clean_numeric_text REGEXP '^[0-9]{1,2}$'
             AND matched_text NOT REGEXP 'RM'
             AND matched_text NOT REGEXP 'K[[:space:]]*$'
            THEN 'Small numeric value requires manual verification'

        ELSE 'Candidate extracted from original remark'
    END AS audit_reason,

    CURRENT_TIMESTAMP AS audit_created_at

FROM cleaned_data;


-- =========================================================
-- RESULT 1: AUDIT POPULATION AND STATUS SUMMARY
-- =========================================================

SELECT
    COUNT(*) AS total_slash_records,

    SUM(validation_status =
        'Auto Extracted - Pending Validation')
        AS auto_extracted_pending_validation,

    SUM(validation_status =
        'Unable to Extract')
        AS unable_to_extract_records,

    SUM(validation_status =
        'Manual Review - Possible Comma Truncation')
        AS possible_truncation_records,

    SUM(validation_status =
        'Manual Review - Small Amount')
        AS small_amount_review_records,

    SUM(auto_slash_amount IS NOT NULL)
        AS records_with_candidate_amount,

    SUM(COALESCE(auto_slash_amount, 0))
        AS total_candidate_slash_amount

FROM tmp_06_slash_audit;


-- =========================================================
-- RESULT 2: FINANCIER-LEVEL AUDIT
-- =========================================================

SELECT
    COALESCE(NULLIF(TRIM(financier), ''),
             'Missing / Blank') AS financier,

    COUNT(*) AS slash_cases,

    SUM(auto_slash_amount IS NOT NULL)
        AS amount_available_cases,

    SUM(COALESCE(auto_slash_amount, 0))
        AS total_candidate_slash_amount,

    ROUND(
        AVG(auto_slash_amount), 2
    ) AS avg_candidate_slash_amount,

    SUM(validation_status = 'Unable to Extract')
        AS unable_to_extract_cases

FROM tmp_06_slash_audit

GROUP BY
    COALESCE(NULLIF(TRIM(financier), ''),
             'Missing / Blank')

ORDER BY total_candidate_slash_amount DESC;


-- =========================================================
-- RESULT 3: FULL RECORD-LEVEL AUDIT
-- =========================================================

SELECT
    financier,
    order_status,
    loan_amount,
    matched_text,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason,
    full_remark

FROM tmp_06_slash_audit

ORDER BY
    financier,
    validation_status,
    loan_amount;




-- 1. Remove the false amount extracted from "SLASH 9 YEARS"

UPDATE tmp_06_slash_audit
SET
    auto_slash_amount = NULL,
    audit_reason = 'Excluded: 9 refers to loan tenure, not slash amount'
WHERE financier = 'Toyota Capital'
  AND loan_amount = 46700
  AND full_remark LIKE '%SLASH 9 YEARS%';


-- 2. Recalculate audit summary

SELECT
    COUNT(*) AS total_slash_records,

    SUM(validation_status =
        'Auto Extracted - Pending Validation')
        AS auto_extracted_pending_validation,

    SUM(validation_status =
        'Manual Review - Small Amount')
        AS small_amount_review_records,

    SUM(validation_status =
        'Unable to Extract')
        AS unable_to_extract_records,

    SUM(auto_slash_amount IS NOT NULL)
        AS records_with_candidate_amount,

    SUM(
        CASE
            WHEN validation_status =
                 'Auto Extracted - Pending Validation'
            THEN auto_slash_amount
            ELSE 0
        END
    ) AS auto_extracted_candidate_total,

    SUM(
        CASE
            WHEN validation_status =
                 'Manual Review - Small Amount'
            THEN auto_slash_amount
            ELSE 0
        END
    ) AS small_amount_candidate_total

FROM tmp_06_slash_audit;


-- 3. Verify that no invalid candidate remains

SELECT
    financier,
    loan_amount,
    matched_text,
    auto_slash_amount,
    validation_status,
    audit_reason
FROM tmp_06_slash_audit
WHERE validation_status = 'Unable to Extract'
  AND auto_slash_amount IS NOT NULL;


SHOW COLUMNS FROM tmp_06_slash_audit;

SELECT *
FROM tmp_06_slash_audit
WHERE financier = 'Toyota Capital'
  AND loan_amount = 46700
  AND full_remark LIKE '%SLASH 9 YEARS%';
  
  
SELECT
    COUNT(*) AS target_records
FROM tmp_06_slash_audit
WHERE financier = 'Toyota Capital'
  AND loan_amount = 46700
  AND full_remark LIKE '%SLASH 9 YEARS%';
  
  
-- Temporarily disable safe update mode
SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

UPDATE tmp_06_slash_audit
SET
    auto_slash_amount = NULL,
    final_slash_amount = NULL,
    audit_reason = 'Excluded: 9 refers to loan tenure, not slash amount'
WHERE financier = 'Toyota Capital'
  AND loan_amount = 46700
  AND full_remark LIKE '%SLASH 9 YEARS%';

-- Verify the correction
SELECT
    financier,
    loan_amount,
    matched_text,
    auto_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM tmp_06_slash_audit
WHERE financier = 'Toyota Capital'
  AND loan_amount = 46700
  AND full_remark LIKE '%SLASH 9 YEARS%';

COMMIT;

-- Restore safe update mode
SET SQL_SAFE_UPDATES = 1;


SELECT
    COUNT(*) AS total_slash_records,

    SUM(validation_status =
        'Auto Extracted - Pending Validation')
        AS auto_extracted_pending_validation,

    SUM(validation_status =
        'Manually Verified')
        AS manually_verified_records,

    SUM(validation_status =
        'Manual Review - Small Amount')
        AS small_amount_review_records,

    SUM(validation_status =
        'Unable to Extract')
        AS unable_to_extract_records,

    SUM(auto_slash_amount IS NOT NULL)
        AS records_with_auto_candidate,

    SUM(final_slash_amount IS NOT NULL)
        AS records_with_final_amount,

    SUM(COALESCE(final_slash_amount, 0))
        AS verified_final_slash_amount

FROM tmp_06_slash_audit;


SELECT
    validation_status,
    COUNT(*) AS record_count,
    SUM(auto_slash_amount IS NOT NULL) AS auto_amount_count,
    SUM(manual_slash_amount IS NOT NULL) AS manual_amount_count,
    SUM(final_slash_amount IS NOT NULL) AS final_amount_count,
    SUM(COALESCE(auto_slash_amount, 0)) AS auto_amount_total,
    SUM(COALESCE(manual_slash_amount, 0)) AS manual_amount_total
FROM tmp_06_slash_audit
GROUP BY validation_status
ORDER BY record_count DESC;


SELECT
    financier,
    loan_amount,
    matched_text,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM tmp_06_slash_audit
WHERE auto_slash_amount IS NOT NULL
ORDER BY financier, auto_slash_amount;


SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    matched_text,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM tmp_06_slash_audit
WHERE auto_slash_amount IS NOT NULL
ORDER BY
    financier,
    auto_slash_amount,
    order_id;
    
SELECT
    order_id,
    financier,
    loan_amount,
    full_remark,
    auto_slash_amount,
    validation_status
FROM tmp_06_slash_audit
WHERE order_id = 20260916210017;


SET SQL_SAFE_UPDATES = 0;

START TRANSACTION;

UPDATE tmp_06_slash_audit
SET
    auto_slash_amount = NULL,
    final_slash_amount = NULL,
    validation_status = 'Unable to Extract',
    audit_reason = 'Date incorrectly extracted as slash amount: 22/9'
WHERE order_id = 20260916210017;

SELECT
    order_id,
    financier,
    loan_amount,
    auto_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM tmp_06_slash_audit
WHERE order_id = 20260916210017;

COMMIT;

SET SQL_SAFE_UPDATES = 1;


SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    matched_text,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM tmp_06_slash_audit
WHERE financier = 'Carsome Capital'
  AND loan_amount = 15000;
  
  
  
USE carsome_orders_analysis;

ALTER TABLE tmp_06_slash_audit
MODIFY COLUMN audit_reason VARCHAR(500) NOT NULL;

SET SQL_SAFE_UPDATES = 0;

UPDATE tmp_06_slash_audit
SET
    validation_status = 'Manual Review - Amount Consistency',
    audit_reason = 'Slash amount RM20,000 is explicitly stated in LOU, but exceeds approved loan amount RM15,000. Original application amount unavailable; retain candidate pending verification.'
WHERE order_id = 20260924260002;

SELECT
    order_id,
    financier,
    loan_amount,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM tmp_06_slash_audit
WHERE order_id = 20260924260002;


SELECT
    validation_status,
    COUNT(*) AS record_count,

    SUM(CASE
        WHEN auto_slash_amount IS NOT NULL THEN 1
        ELSE 0
    END) AS auto_amount_count,

    SUM(CASE
        WHEN manual_slash_amount IS NOT NULL THEN 1
        ELSE 0
    END) AS manual_amount_count,

    SUM(CASE
        WHEN final_slash_amount IS NOT NULL THEN 1
        ELSE 0
    END) AS final_amount_count,

    SUM(COALESCE(auto_slash_amount, 0)) AS auto_amount_total,

    SUM(COALESCE(manual_slash_amount, 0)) AS manual_amount_total,

    SUM(COALESCE(final_slash_amount, 0)) AS final_amount_total

FROM tmp_06_slash_audit
GROUP BY validation_status
ORDER BY record_count DESC;



SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM tmp_06_slash_audit
WHERE validation_status = 'Manual Review - Amount Consistency';


SELECT
    COUNT(*) AS total_slash_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    SUM(CASE
        WHEN final_slash_amount IS NOT NULL THEN 1
        ELSE 0
    END) AS confirmed_final_amount_records,
    SUM(COALESCE(final_slash_amount, 0)) AS confirmed_final_slash_amount
FROM tmp_06_slash_audit;




USE carsome_orders_analysis;

SELECT
    COUNT(*) AS total_records,

    COUNT(loan_amount) AS loan_amount_records,
    COUNT(fis___loan) AS fis_loan_records,

    COUNT(
        CASE
            WHEN loan_amount IS NOT NULL
             AND fis___loan IS NOT NULL
            THEN 1
        END
    ) AS both_available,

    COUNT(
        CASE
            WHEN loan_amount IS NOT NULL
             AND fis___loan IS NOT NULL
             AND loan_amount = fis___loan
            THEN 1
        END
    ) AS exact_match,

    COUNT(
        CASE
            WHEN loan_amount IS NOT NULL
             AND fis___loan IS NOT NULL
             AND loan_amount <> fis___loan
            THEN 1
        END
    ) AS different_amounts,

    MIN(fis___loan) AS min_fis_loan,
    MAX(fis___loan) AS max_fis_loan,
    AVG(fis___loan) AS avg_fis_loan

FROM stg_orders;


USE carsome_orders_analysis;

SELECT
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ) AS financier,

    order_status,

    COUNT(*) AS total_orders,

    COUNT(loan_amount) AS loan_amount_records,

    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,

    MIN(loan_amount) AS min_loan_amount,

    MAX(loan_amount) AS max_loan_amount,

    ROUND(SUM(loan_amount), 2) AS total_loan_amount

FROM stg_orders

GROUP BY
    COALESCE(
        NULLIF(TRIM(final_financier), ''),
        'Missing / Blank'
    ),
    order_status

ORDER BY
    loan_amount_records DESC,
    financier;
    
    
USE carsome_orders_analysis;

SELECT
    order_id,
    final_financier,
    order_status,
    loan_amount,
    final_status_remark

FROM stg_orders

WHERE loan_amount IS NOT NULL
  AND (
      UPPER(final_status_remark) LIKE '%APPROVED AMOUNT%'
      OR UPPER(final_status_remark) LIKE '%LOU APPROVED%'
      OR UPPER(final_status_remark) LIKE '%LOAN APPROVED%'
      OR UPPER(final_status_remark) LIKE '%APPROVED RM%'
  )

ORDER BY final_financier, order_status

LIMIT 50;


USE carsome_orders_analysis;

SELECT
    order_status,

    COUNT(*) AS total_orders,

    COUNT(loan_amount) AS records_with_loan_amount,

    ROUND(
        COUNT(loan_amount) * 100.0 / COUNT(*),
        2
    ) AS amount_coverage_pct,

    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,

    ROUND(
        SUM(loan_amount),
        2
    ) AS total_loan_amount,

    MIN(loan_amount) AS min_loan_amount,

    MAX(loan_amount) AS max_loan_amount

FROM stg_orders

GROUP BY order_status

ORDER BY records_with_loan_amount DESC;



USE carsome_orders_analysis;

SELECT
    order_status,

    CASE
        WHEN loan_amount < 20000
            THEN 'Below RM20,000'

        WHEN loan_amount < 40000
            THEN 'RM20,000 - RM39,999'

        WHEN loan_amount < 60000
            THEN 'RM40,000 - RM59,999'

        WHEN loan_amount < 80000
            THEN 'RM60,000 - RM79,999'

        ELSE 'RM80,000 and Above'
    END AS loan_amount_band,

    COUNT(*) AS case_count,

    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,

    MIN(loan_amount) AS min_loan_amount,

    MAX(loan_amount) AS max_loan_amount

FROM stg_orders

WHERE loan_amount IS NOT NULL

GROUP BY
    order_status,
    CASE
        WHEN loan_amount < 20000
            THEN 'Below RM20,000'
        WHEN loan_amount < 40000
            THEN 'RM20,000 - RM39,999'
        WHEN loan_amount < 60000
            THEN 'RM40,000 - RM59,999'
        WHEN loan_amount < 80000
            THEN 'RM60,000 - RM79,999'
        ELSE 'RM80,000 and Above'
    END

ORDER BY
    CASE order_status
        WHEN 'Order Completed' THEN 1
        WHEN 'Order Closed' THEN 2
        WHEN 'Order Cancelled' THEN 3
        WHEN 'Pending E-hak Milik' THEN 4
        WHEN 'Pending Pay' THEN 5
        WHEN 'Pending Deliver' THEN 6
        ELSE 7
    END,
    CASE
        WHEN loan_amount_band = 'Below RM20,000' THEN 1
        WHEN loan_amount_band = 'RM20,000 - RM39,999' THEN 2
        WHEN loan_amount_band = 'RM40,000 - RM59,999' THEN 3
        WHEN loan_amount_band = 'RM60,000 - RM79,999' THEN 4
        ELSE 5
    END;
    
    
    
USE carsome_orders_analysis;

SELECT
    COUNT(*) AS cancelled_total,

    SUM(
        CASE WHEN loan_amount IS NOT NULL
        THEN 1 ELSE 0 END
    ) AS records_with_loan_amount,

    SUM(
        CASE WHEN loan_amount IS NULL
        THEN 1 ELSE 0 END
    ) AS records_without_loan_amount,

    SUM(
        CASE WHEN loan_amount < 20000
        THEN 1 ELSE 0 END
    ) AS below_20000,

    SUM(
        CASE WHEN loan_amount >= 20000
              AND loan_amount < 40000
        THEN 1 ELSE 0 END
    ) AS band_20000_39999,

    SUM(
        CASE WHEN loan_amount >= 40000
              AND loan_amount < 60000
        THEN 1 ELSE 0 END
    ) AS band_40000_59999,

    SUM(
        CASE WHEN loan_amount >= 60000
              AND loan_amount < 80000
        THEN 1 ELSE 0 END
    ) AS band_60000_79999,

    SUM(
        CASE WHEN loan_amount >= 80000
        THEN 1 ELSE 0 END
    ) AS above_80000,

    ROUND(SUM(loan_amount), 2) AS total_loan_amount

FROM stg_orders
WHERE order_status = 'Order Cancelled';



USE carsome_orders_analysis;

-- 06.4 Step 1: Completed Loan Amount by Financier

SELECT
    TRIM(financier) AS financier,

    COUNT(*) AS completed_orders,

    ROUND(AVG(loan_amount), 2)
        AS avg_loan_amount,

    MIN(loan_amount)
        AS min_loan_amount,

    MAX(loan_amount)
        AS max_loan_amount,

    ROUND(SUM(loan_amount), 2)
        AS total_loan_amount,

    ROUND(
        SUM(loan_amount) / COUNT(*),
        2
    ) AS average_amount_check

FROM stg_orders

WHERE order_status = 'Order Completed'
  AND financier IS NOT NULL
  AND TRIM(financier) <> ''
  AND loan_amount IS NOT NULL

GROUP BY TRIM(financier)

ORDER BY completed_orders DESC;



USE carsome_orders_analysis;

SELECT
    TRIM(final_financier) AS financier,

    COUNT(*) AS completed_orders,

    ROUND(AVG(loan_amount), 2)
        AS avg_loan_amount,

    MIN(loan_amount)
        AS min_loan_amount,

    MAX(loan_amount)
        AS max_loan_amount,

    ROUND(SUM(loan_amount), 2)
        AS total_loan_amount

FROM stg_orders

WHERE order_status = 'Order Completed'
  AND final_financier IS NOT NULL
  AND TRIM(final_financier) <> ''
  AND loan_amount IS NOT NULL

GROUP BY TRIM(final_financier)

ORDER BY completed_orders DESC;



USE carsome_orders_analysis;

-- 06.4 Step 2: Loan Amount Distribution by Financier

WITH financier_amounts AS (
    SELECT
        TRIM(final_financier) AS financier,
        loan_amount,

        CASE
            WHEN loan_amount < 20000
                THEN 'Below RM20,000'

            WHEN loan_amount < 40000
                THEN 'RM20,000 - RM39,999'

            WHEN loan_amount < 60000
                THEN 'RM40,000 - RM59,999'

            WHEN loan_amount < 80000
                THEN 'RM60,000 - RM79,999'

            ELSE 'RM80,000 and Above'
        END AS loan_amount_band

    FROM stg_orders

    WHERE order_status = 'Order Completed'
      AND final_financier IS NOT NULL
      AND TRIM(final_financier) <> ''
      AND loan_amount IS NOT NULL
),

band_summary AS (
    SELECT
        financier,
        loan_amount_band,
        COUNT(*) AS case_count

    FROM financier_amounts

    GROUP BY
        financier,
        loan_amount_band
)

SELECT
    financier,
    loan_amount_band,
    case_count,

    SUM(case_count) OVER (
        PARTITION BY financier
    ) AS financier_total_orders,

    ROUND(
        case_count * 100.0 /
        SUM(case_count) OVER (
            PARTITION BY financier
        ),
        2
    ) AS percentage_within_financier

FROM band_summary

ORDER BY
    financier,
    CASE loan_amount_band
        WHEN 'Below RM20,000' THEN 1
        WHEN 'RM20,000 - RM39,999' THEN 2
        WHEN 'RM40,000 - RM59,999' THEN 3
        WHEN 'RM60,000 - RM79,999' THEN 4
        WHEN 'RM80,000 and Above' THEN 5
    END;
    
    
    
USE carsome_orders_analysis;

-- 06.4 Step 3: High-Value Loan Analysis

SELECT
    TRIM(final_financier) AS financier,

    COUNT(*) AS completed_orders,

    SUM(
        CASE
            WHEN loan_amount >= 60000
            THEN 1 ELSE 0
        END
    ) AS high_value_loan_orders,

    SUM(
        CASE
            WHEN loan_amount < 60000
            THEN 1 ELSE 0
        END
    ) AS standard_loan_orders,

    ROUND(
        SUM(
            CASE
                WHEN loan_amount >= 60000
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS high_value_loan_pct,

    ROUND(
        SUM(
            CASE
                WHEN loan_amount < 60000
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS standard_loan_pct,

    ROUND(
        AVG(
            CASE
                WHEN loan_amount >= 60000
                THEN loan_amount
            END
        ),
        2
    ) AS avg_high_value_loan,

    ROUND(
        AVG(
            CASE
                WHEN loan_amount < 60000
                THEN loan_amount
            END
        ),
        2
    ) AS avg_standard_loan

FROM stg_orders

WHERE order_status = 'Order Completed'
  AND final_financier IS NOT NULL
  AND TRIM(final_financier) <> ''
  AND loan_amount IS NOT NULL

GROUP BY TRIM(final_financier)

ORDER BY high_value_loan_pct DESC;



USE carsome_orders_analysis;

-- 06.4 Step 4: High-Value Loan Portfolio Contribution

WITH financier_summary AS (
    SELECT
        TRIM(final_financier) AS financier,

        COUNT(*) AS completed_orders,

        SUM(
            CASE
                WHEN loan_amount >= 60000 THEN 1
                ELSE 0
            END
        ) AS high_value_orders,

        SUM(
            CASE
                WHEN loan_amount >= 60000
                THEN loan_amount
                ELSE 0
            END
        ) AS high_value_loan_amount

    FROM stg_orders

    WHERE order_status = 'Order Completed'
      AND final_financier IS NOT NULL
      AND TRIM(final_financier) <> ''
      AND loan_amount IS NOT NULL

    GROUP BY TRIM(final_financier)
)

SELECT
    financier,

    completed_orders,

    high_value_orders,

    ROUND(
        high_value_orders * 100.0 /
        NULLIF(completed_orders, 0),
        2
    ) AS high_value_share_pct,

    ROUND(
        high_value_orders * 100.0 /
        NULLIF(
            SUM(high_value_orders) OVER (),
            0
        ),
        2
    ) AS portfolio_contribution_pct,

    ROUND(high_value_loan_amount, 2)
        AS high_value_loan_amount

FROM financier_summary

ORDER BY high_value_orders DESC;



USE carsome_orders_analysis;

WITH financier_summary AS (
    SELECT
        TRIM(final_financier) AS financier,

        COUNT(*) AS completed_orders,

        SUM(
            CASE
                WHEN loan_amount >= 60000
                THEN 1 ELSE 0
            END
        ) AS high_value_orders,

        SUM(
            CASE
                WHEN loan_amount >= 60000
                THEN loan_amount
                ELSE 0
            END
        ) AS high_value_loan_amount

    FROM stg_orders

    WHERE order_status = 'Order Completed'
      AND final_financier IS NOT NULL
      AND TRIM(final_financier) <> ''
      AND loan_amount IS NOT NULL

    GROUP BY TRIM(final_financier)
)

SELECT
    financier,

    completed_orders,

    high_value_orders,

    ROUND(high_value_loan_amount, 2)
        AS high_value_loan_amount,

    ROUND(
        high_value_loan_amount * 100.0 /
        NULLIF(SUM(high_value_loan_amount) OVER (), 0),
        2
    ) AS amount_contribution_pct

FROM financier_summary

ORDER BY high_value_loan_amount DESC;


USE carsome_orders_analysis;

-- 1. 查找 Loan Slash 相关表
SHOW TABLES LIKE '%slash%';

-- 2. 检查正式业务数据表
DESCRIBE stg_orders;


DESCRIBE tmp_06_slash_audit;

SELECT *
FROM tmp_06_slash_audit
LIMIT 10;


USE carsome_orders_analysis;

SHOW TABLES;

USE carsome_orders_analysis;

-- 1. 检查第二版数据表的字段
DESCRIBE stg_orders_v2;

-- 2. 检查两张订单表的记录数量
SELECT
    'stg_orders' AS table_name,
    COUNT(*) AS total_records
FROM stg_orders

UNION ALL

SELECT
    'stg_orders_v2',
    COUNT(*)
FROM stg_orders_v2;

-- 3. 查找数据库中所有与 Slash / Remark 相关的字段
SELECT
    TABLE_NAME,
    COLUMN_NAME,
    DATA_TYPE
FROM information_schema.COLUMNS
WHERE TABLE_SCHEMA = 'carsome_orders_analysis'
  AND (
      COLUMN_NAME LIKE '%slash%'
      OR COLUMN_NAME LIKE '%remark%'
      OR COLUMN_NAME LIKE '%loan_amount%'
  )
ORDER BY TABLE_NAME, ORDINAL_POSITION;


USE carsome_orders_analysis;

-- Step 1: Check duplicate order IDs
SELECT
    'stg_orders' AS table_name,
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_rows
FROM stg_orders

UNION ALL

SELECT
    'stg_orders_v2',
    COUNT(*),
    COUNT(DISTINCT order_id),
    COUNT(*) - COUNT(DISTINCT order_id)
FROM stg_orders_v2;


-- Step 2: Compare order IDs between two tables
SELECT
    COUNT(*) AS matched_order_ids,
    SUM(
        CASE WHEN s.loan_amount = v.loan_amount
             OR (s.loan_amount IS NULL AND v.loan_amount IS NULL)
             THEN 1 ELSE 0 END
    ) AS same_loan_amount,
    SUM(
        CASE WHEN NOT (
            s.loan_amount = v.loan_amount
            OR (s.loan_amount IS NULL AND v.loan_amount IS NULL)
        )
        THEN 1 ELSE 0 END
    ) AS different_loan_amount
FROM stg_orders s
INNER JOIN stg_orders_v2 v
    ON s.order_id = v.order_id;


-- Step 3: Find orders existing only in stg_orders
SELECT COUNT(*) AS only_in_stg_orders
FROM stg_orders s
LEFT JOIN stg_orders_v2 v
    ON s.order_id = v.order_id
WHERE v.order_id IS NULL;


-- Step 4: Find orders existing only in stg_orders_v2
SELECT COUNT(*) AS only_in_stg_orders_v2
FROM stg_orders_v2 v
LEFT JOIN stg_orders s
    ON v.order_id = s.order_id
WHERE s.order_id IS NULL;




USE carsome_orders_analysis;

-- Step 1: Count all remarks mentioning slash
SELECT
    COUNT(*) AS total_slash_records,
    COUNT(DISTINCT order_id) AS unique_slash_orders,
    COUNT(CASE
        WHEN loan_amount IS NOT NULL THEN 1
    END) AS records_with_loan_amount
FROM stg_orders
WHERE LOWER(COALESCE(final_status_remark, '')) LIKE '%slash%';


-- Step 2: Review all original slash records
SELECT
    order_id,
    final_financier AS financier,
    order_status,
    loan_amount,
    final_status_remark AS full_remark
FROM stg_orders
WHERE LOWER(COALESCE(final_status_remark, '')) LIKE '%slash%'
ORDER BY final_financier, order_id;



USE carsome_orders_analysis;

-- =====================================================
-- 06.5.1 | Create Permanent Loan Slash Audit Table
-- =====================================================

CREATE TABLE IF NOT EXISTS loan_slash_audit (
    order_id BIGINT NOT NULL,
    financier VARCHAR(150),
    order_status VARCHAR(100),
    loan_amount DECIMAL(15,2),
    full_remark TEXT,

    matched_text TEXT,
    auto_slash_amount DECIMAL(15,2),
    manual_slash_amount DECIMAL(15,2),
    final_slash_amount DECIMAL(15,2),

    validation_status VARCHAR(100)
        NOT NULL DEFAULT 'Pending Re-extraction',

    audit_reason VARCHAR(1000),

    audit_created_at DATETIME
        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    audit_updated_at DATETIME
        NOT NULL DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    PRIMARY KEY (order_id),

    INDEX idx_slash_financier (financier),
    INDEX idx_slash_status (validation_status)
);


-- =====================================================
-- Import original slash records
-- Only insert records that do not already exist
-- =====================================================

INSERT INTO loan_slash_audit (
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    validation_status,
    audit_reason
)
SELECT
    s.order_id,
    s.final_financier,
    s.order_status,
    s.loan_amount,
    s.final_status_remark,
    'Pending Re-extraction',
    'Original slash remark imported; amount requires validation'
FROM stg_orders s
WHERE LOWER(COALESCE(s.final_status_remark, '')) LIKE '%slash%'
  AND NOT EXISTS (
      SELECT 1
      FROM loan_slash_audit a
      WHERE a.order_id = s.order_id
  );


-- =====================================================
-- Verify imported records
-- =====================================================

SELECT
    COUNT(*) AS total_slash_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(auto_slash_amount) AS auto_extracted_records,
    COUNT(manual_slash_amount) AS manually_verified_records,
    COUNT(final_slash_amount) AS confirmed_final_amount_records
FROM loan_slash_audit;


-- Check status distribution

SELECT
    validation_status,
    COUNT(*) AS record_count
FROM loan_slash_audit
GROUP BY validation_status
ORDER BY record_count DESC;


-- Preview original records

SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    validation_status
FROM loan_slash_audit
ORDER BY financier, order_id;



USE carsome_orders_analysis;

SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,

    REGEXP_SUBSTR(
        full_remark,
        '(?i)(loan[[:space:]]*)?slash(ed)?[[:space:]]*(amount[[:space:]]*)?(rm[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]{1,2})?'
    ) AS matched_text,

    CASE
        WHEN REGEXP_SUBSTR(
            full_remark,
            '(?i)(loan[[:space:]]*)?slash(ed)?[[:space:]]*(amount[[:space:]]*)?(rm[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]{1,2})?'
        ) IS NOT NULL
        THEN CAST(
            REPLACE(
                REGEXP_SUBSTR(
                    REGEXP_SUBSTR(
                        full_remark,
                        '(?i)(loan[[:space:]]*)?slash(ed)?[[:space:]]*(amount[[:space:]]*)?(rm[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]{1,2})?'
                    ),
                    '[0-9][0-9,]*(\\.[0-9]{1,2})?'
                ),
                ',',
                ''
            ) AS DECIMAL(15,2)
        )
        ELSE NULL
    END AS candidate_slash_amount

FROM loan_slash_audit
ORDER BY financier, order_id;




USE carsome_orders_analysis;

WITH extracted AS (
    SELECT
        order_id,
        financier,
        order_status,
        loan_amount,
        full_remark,

        REGEXP_SUBSTR(
            full_remark,
            '(?i)slash(ed)?[[:blank:]]+(rm[[:blank:]]*)?[0-9][0-9,]*(\\.[0-9]+)?[[:blank:]]*k?'
        ) AS new_matched_text,

        CASE
            WHEN full_remark REGEXP
                '(?i)slash(ed)?[[:blank:]]+[0-9]+[[:blank:]]*years'
            THEN 'EXCLUDE - Loan tenure'

            ELSE 'CHECK'
        END AS initial_check

    FROM loan_slash_audit
),

cleaned AS (
    SELECT
        *,
        CASE
            WHEN new_matched_text IS NULL
                THEN NULL

            WHEN initial_check LIKE 'EXCLUDE%'
                THEN NULL

            ELSE TRIM(
                REGEXP_REPLACE(
                    new_matched_text,
                    '(?i)^.*?slash(ed)?[[:blank:]]+(rm[[:blank:]]*)?',
                    ''
                )
            )
        END AS numeric_token

    FROM extracted
),

converted AS (
    SELECT
        *,
        CASE
            WHEN numeric_token IS NULL
                THEN NULL

            WHEN UPPER(numeric_token) LIKE '%K'
                THEN CAST(
                    REPLACE(
                        REPLACE(UPPER(numeric_token), 'K', ''),
                        ',',
                        ''
                    ) AS DECIMAL(15,2)
                ) * 1000

            ELSE CAST(
                REPLACE(numeric_token, ',', '')
                AS DECIMAL(15,2)
            )
        END AS corrected_slash_amount

    FROM cleaned
)

SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    new_matched_text,
    numeric_token,
    corrected_slash_amount,

    CASE
        WHEN corrected_slash_amount IS NULL
            THEN 'Unable to Extract'

        WHEN corrected_slash_amount > loan_amount
            THEN 'Manual Review - Amount Consistency'

        WHEN corrected_slash_amount < 100
            THEN 'Manual Review - Small Amount'

        ELSE 'Auto Extracted - Pending Validation'
    END AS proposed_validation_status

FROM converted
ORDER BY financier, order_id;



USE carsome_orders_analysis;

WITH extracted AS (
    SELECT
        order_id,
        financier,
        order_status,
        loan_amount,
        full_remark,

        REGEXP_SUBSTR(
            full_remark,
            '(?i)slash(ed)?[[:blank:]]+(rm[[:blank:]]*)?[0-9][0-9,]*(\\.[0-9]+)?[[:blank:]]*k?(?![[:blank:]]*years)'
        ) AS corrected_matched_text

    FROM loan_slash_audit
),

cleaned AS (
    SELECT
        *,
        CASE
            WHEN corrected_matched_text IS NULL THEN NULL
            ELSE TRIM(
                REGEXP_REPLACE(
                    corrected_matched_text,
                    '(?i)^.*?slash(ed)?[[:blank:]]+(rm[[:blank:]]*)?',
                    ''
                )
            )
        END AS numeric_token
    FROM extracted
),

converted AS (
    SELECT
        *,
        CASE
            WHEN numeric_token IS NULL THEN NULL

            WHEN UPPER(numeric_token) LIKE '%K'
            THEN CAST(
                REPLACE(
                    REPLACE(UPPER(numeric_token), 'K', ''),
                    ',',
                    ''
                ) AS DECIMAL(15,2)
            ) * 1000

            ELSE CAST(
                REPLACE(numeric_token, ',', '')
                AS DECIMAL(15,2)
            )
        END AS corrected_slash_amount

    FROM cleaned
)

SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    corrected_matched_text,
    numeric_token,
    corrected_slash_amount,

    CASE
        WHEN corrected_slash_amount IS NULL
            THEN 'Unable to Extract'

        WHEN corrected_slash_amount > loan_amount
            THEN 'Manual Review - Amount Consistency'

        WHEN corrected_slash_amount < 100
            THEN 'Manual Review - Small Amount'

        ELSE 'Auto Extracted - Pending Validation'
    END AS proposed_validation_status

FROM converted
ORDER BY financier, order_id;



USE carsome_orders_analysis;

WITH extracted AS (
    SELECT
        order_id,
        financier,
        order_status,
        loan_amount,
        full_remark,

        REGEXP_SUBSTR(
            full_remark,
            '(?i)slash(ed)?[[:space:]]+(rm[[:space:]]*)?[0-9][0-9,]*(\\.[0-9]+)?[[:space:]]*k?(?![[:space:]]*years)'
        ) AS matched_text

    FROM loan_slash_audit
),

cleaned AS (
    SELECT
        *,
        CASE
            WHEN matched_text IS NULL THEN NULL
            ELSE TRIM(
                REGEXP_REPLACE(
                    matched_text,
                    '(?i)^.*?slash(ed)?[[:space:]]+(rm[[:space:]]*)?',
                    ''
                )
            )
        END AS numeric_token
    FROM extracted
),

converted AS (
    SELECT
        *,
        CASE
            WHEN numeric_token IS NULL THEN NULL

            WHEN UPPER(numeric_token) LIKE '%K'
            THEN CAST(
                REPLACE(
                    REPLACE(UPPER(numeric_token), 'K', ''),
                    ',',
                    ''
                ) AS DECIMAL(15,2)
            ) * 1000

            ELSE CAST(
                REPLACE(numeric_token, ',', '')
                AS DECIMAL(15,2)
            )
        END AS candidate_slash_amount

    FROM cleaned
)

SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    matched_text,
    numeric_token,
    candidate_slash_amount,

    CASE
        WHEN candidate_slash_amount IS NULL
            THEN 'Unable to Extract'

        WHEN candidate_slash_amount > loan_amount
            THEN 'Manual Review - Amount Consistency'

        WHEN candidate_slash_amount < 100
            THEN 'Manual Review - Small Amount'

        ELSE 'Auto Extracted - Pending Validation'
    END AS proposed_validation_status

FROM converted
ORDER BY financier, order_id;



USE carsome_orders_analysis;

-- 1. 检查正式审计表结构
DESCRIBE loan_slash_audit;

-- 2. 查看完整建表定义
SHOW CREATE TABLE loan_slash_audit;

-- 3. 检查当前正式审计表记录数
SELECT COUNT(*) AS total_records
FROM loan_slash_audit;

-- 4. 检查订单 ID 是否重复
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM loan_slash_audit;



USE carsome_orders_analysis;

CREATE TABLE IF NOT EXISTS loan_slash_audit_stage_20261106 (
    order_id BIGINT NOT NULL PRIMARY KEY,
    financier VARCHAR(150),
    order_status VARCHAR(100),
    loan_amount DECIMAL(15 , 2 ),
    full_remark TEXT,
    matched_text TEXT,
    numeric_token VARCHAR(100),
    candidate_slash_amount DECIMAL(15 , 2 ),
    proposed_validation_status VARCHAR(100)
);


-- 1. 检查导入数量
SELECT COUNT(*) AS stage_records
FROM loan_slash_audit_stage_20261106;

-- 2. 检查订单唯一性
SELECT
    COUNT(*) AS total_rows,
    COUNT(DISTINCT order_id) AS unique_orders
FROM loan_slash_audit_stage_20261106;

-- 3. 检查提取状态
SELECT
    proposed_validation_status,
    COUNT(*) AS record_count
FROM loan_slash_audit_stage_20261106
GROUP BY proposed_validation_status
ORDER BY record_count DESC;

-- 4. 检查正式表和临时表订单是否一一对应
SELECT
    COUNT(*) AS matched_records
FROM loan_slash_audit a
INNER JOIN loan_slash_audit_stage_20261106 s
    ON a.order_id = s.order_id;

-- 5. 检查是否存在无法匹配的订单
SELECT s.order_id
FROM loan_slash_audit_stage_20261106 s
LEFT JOIN loan_slash_audit a
    ON s.order_id = a.order_id
WHERE a.order_id IS NULL;


USE carsome_orders_analysis;

SELECT
    COUNT(*) AS mismatch_records
FROM loan_slash_audit a
JOIN loan_slash_audit_stage_20261106 s
    ON a.order_id = s.order_id
WHERE
       NOT (a.financier <=> s.financier)
    OR NOT (a.order_status <=> s.order_status)
    OR NOT (a.loan_amount <=> s.loan_amount)
    OR NOT (a.full_remark <=> s.full_remark);
    
    
START TRANSACTION;

UPDATE loan_slash_audit a
JOIN loan_slash_audit_stage_20261106 s
    ON a.order_id = s.order_id
SET
    a.matched_text = s.matched_text,
    a.auto_slash_amount = s.candidate_slash_amount,

    a.audit_reason = CONCAT(
        'Source: loan8.csv; ',
        'Status: ',
        s.proposed_validation_status,
        '; Numeric token: ',
        COALESCE(s.numeric_token, 'NULL')
    ),

    a.validation_status = s.proposed_validation_status;

-- 检查本次更新影响的记录
SELECT ROW_COUNT() AS updated_records;

COMMIT;




USE carsome_orders_analysis;

-- 1. 正式表记录总数
SELECT COUNT(*) AS total_records
FROM loan_slash_audit;

-- 2. 检查验证状态分布
SELECT
    validation_status,
    COUNT(*) AS record_count
FROM loan_slash_audit
GROUP BY validation_status
ORDER BY record_count DESC;

-- 3. 检查自动提取金额数量
SELECT
    COUNT(*) AS total_records,
    COUNT(auto_slash_amount) AS extracted_amounts,
    SUM(auto_slash_amount) AS total_candidate_amount
FROM loan_slash_audit;



SELECT
    COUNT(*) AS total_records,
    COUNT(manual_slash_amount) AS manual_amount_records,
    COUNT(final_slash_amount) AS final_amount_records
FROM loan_slash_audit;


SELECT
    order_id,
    financier,
    loan_amount,
    matched_text,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM loan_slash_audit
WHERE validation_status LIKE 'Manual Review%'
   OR validation_status = 'Unable to Extract'
ORDER BY financier, order_id;




USE carsome_orders_analysis;

SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    matched_text,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM loan_slash_audit
WHERE validation_status IN (
    'Unable to Extract',
    'Manual Review - Small Amount',
    'Manual Review - Amount Consistency'
)
ORDER BY
    CASE
        WHEN validation_status = 'Manual Review - Small Amount' THEN 1
        WHEN validation_status = 'Manual Review - Amount Consistency' THEN 2
        WHEN validation_status = 'Unable to Extract' THEN 3
    END,
    financier,
    order_id;
    
    
    
    
USE carsome_orders_analysis;

START TRANSACTION;

-- 1. Confirm RM50
UPDATE loan_slash_audit
SET
    manual_slash_amount = 50.00,
    validation_status = 'Manually Confirmed',
    audit_reason = CONCAT(
        COALESCE(audit_reason, ''),
        ' | Human Adjudication: Confirmed RM50. Explicitly stated as LOAN SLASH RM50.'
    )
WHERE order_id = 20260915530002;

-- 2. Reject false extraction RM22
UPDATE loan_slash_audit
SET
    manual_slash_amount = NULL,
    validation_status = 'Rejected - False Extraction',
    audit_reason = CONCAT(
        COALESCE(audit_reason, ''),
        ' | Human Adjudication: Rejected RM22. Extracted from date 22/9, not a slash amount.'
    )
WHERE order_id = 20260916210017;

-- 3. Confirm RM50
UPDATE loan_slash_audit
SET
    manual_slash_amount = 50.00,
    validation_status = 'Manually Confirmed',
    audit_reason = CONCAT(
        COALESCE(audit_reason, ''),
        ' | Human Adjudication: Confirmed RM50. Explicitly stated as loan slashed RM50.'
    )
WHERE order_id = 20260916550001;

-- 4. Retain RM20,000 with consistency warning
UPDATE loan_slash_audit
SET
    manual_slash_amount = 20000.00,
    validation_status = 'Manual Review - Amount Consistency',
    audit_reason = CONCAT(
        COALESCE(audit_reason, ''),
        ' | Human Adjudication: Retained RM20,000 based on explicit remark evidence. Amount consistency requires further investigation because current loan_amount is RM15,000.'
    )
WHERE order_id = 20260924260002;

COMMIT;



SELECT
    order_id,
    financier,
    loan_amount,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM loan_slash_audit
WHERE order_id IN (
    20260915530002,
    20260916210017,
    20260916550001,
    20260924260002
)
ORDER BY order_id;



SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    matched_text,
    auto_slash_amount,
    validation_status,
    audit_reason
FROM loan_slash_audit
WHERE validation_status = 'Auto Extracted - Pending Validation'
ORDER BY financier, order_id;


USE carsome_orders_analysis;

START TRANSACTION;

UPDATE loan_slash_audit
SET
    manual_slash_amount = auto_slash_amount,

    validation_status = 'Manually Confirmed',

    audit_reason = CONCAT(
        COALESCE(audit_reason, ''),
        ' | Human Adjudication: Confirmed. Original full_remark explicitly supports the extracted slash amount. Reviewed against loan11.csv.'
    )

WHERE validation_status = 'Auto Extracted - Pending Validation'
  AND auto_slash_amount IS NOT NULL;

SELECT ROW_COUNT() AS updated_records;

COMMIT;


-- 检查全部人工裁定状态
SELECT
    validation_status,
    COUNT(*) AS record_count
FROM loan_slash_audit
GROUP BY validation_status
ORDER BY record_count DESC;



USE carsome_orders_analysis;

-- 1. 全部人工裁定状态
SELECT
    validation_status,
    COUNT(*) AS record_count
FROM loan_slash_audit
GROUP BY validation_status
ORDER BY record_count DESC;

-- 2. 自动金额与人工金额汇总
SELECT
    COUNT(*) AS total_records,
    COUNT(auto_slash_amount) AS auto_amount_records,
    SUM(auto_slash_amount) AS total_auto_amount,
    COUNT(manual_slash_amount) AS manual_amount_records,
    SUM(manual_slash_amount) AS total_manual_amount,
    COUNT(final_slash_amount) AS final_amount_records,
    SUM(final_slash_amount) AS total_final_amount
FROM loan_slash_audit;

-- 3. 检查人工确认金额与自动金额的差异
SELECT
    order_id,
    financier,
    auto_slash_amount,
    manual_slash_amount,
    validation_status
FROM loan_slash_audit
WHERE validation_status = 'Manually Confirmed'
  AND NOT (auto_slash_amount <=> manual_slash_amount);

-- 4. 检查仍需复核的记录
SELECT
    order_id,
    financier,
    loan_amount,
    auto_slash_amount,
    manual_slash_amount,
    validation_status,
    audit_reason
FROM loan_slash_audit
WHERE validation_status NOT IN (
    'Manually Confirmed',
    'Rejected - False Extraction'
)
ORDER BY financier, order_id;



USE carsome_orders_analysis;

-- 检查55条人工确认记录
SELECT
    COUNT(*) AS confirmed_cases,
    SUM(manual_slash_amount) AS confirmed_slash_amount,
    MIN(manual_slash_amount) AS min_slash_amount,
    MAX(manual_slash_amount) AS max_slash_amount
FROM loan_slash_audit
WHERE validation_status = 'Manually Confirmed';

-- 检查待核查金额
SELECT
    order_id,
    financier,
    loan_amount,
    auto_slash_amount,
    manual_slash_amount,
    validation_status
FROM loan_slash_audit
WHERE validation_status = 'Manual Review - Amount Consistency';

-- 检查最终金额字段是否仍未提前填写
SELECT
    COUNT(*) AS total_records,
    COUNT(final_slash_amount) AS populated_final_amounts
FROM loan_slash_audit;


USE carsome_orders_analysis;

CREATE TABLE loan_slash_final_20261106 AS
SELECT
    order_id,
    financier,
    order_status,
    loan_amount,
    full_remark,
    matched_text,
    auto_slash_amount,
    manual_slash_amount,

    manual_slash_amount AS final_slash_amount,

    validation_status,

    'Human Confirmed' AS final_amount_source,

    CURRENT_TIMESTAMP AS finalized_at

FROM loan_slash_audit

WHERE validation_status = 'Manually Confirmed'
  AND manual_slash_amount IS NOT NULL;
  
  
-- 设置订单 ID 为主键
ALTER TABLE loan_slash_final_20261106
ADD PRIMARY KEY (order_id);

-- 检查记录数量与金额
SELECT
    COUNT(*) AS final_cases,
    SUM(final_slash_amount) AS total_final_slash_amount,
    MIN(final_slash_amount) AS min_slash_amount,
    MAX(final_slash_amount) AS max_slash_amount,
    AVG(final_slash_amount) AS avg_slash_amount
FROM loan_slash_final_20261106;

-- 检查各银行的确认金额
SELECT
    financier,
    COUNT(*) AS confirmed_cases,
    SUM(final_slash_amount) AS total_slash_amount,
    AVG(final_slash_amount) AS avg_slash_amount,
    MIN(final_slash_amount) AS min_slash_amount,
    MAX(final_slash_amount) AS max_slash_amount
FROM loan_slash_final_20261106
GROUP BY financier
ORDER BY total_slash_amount DESC;


USE carsome_orders_analysis;

DESCRIBE loan_slash_final_20261106;

DESCRIBE stg_orders;


SELECT
    COUNT(*) AS slash_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    SUM(final_slash_amount) AS total_slash_amount
FROM loan_slash_final_20261106;



SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(*) - COUNT(DISTINCT order_id) AS duplicate_records
FROM stg_orders;



SELECT
    COUNT(*) AS matched_records,
    COUNT(DISTINCT f.order_id) AS matched_unique_orders,
    COUNT(*) - COUNT(DISTINCT f.order_id) AS duplicate_join_rows
FROM loan_slash_final_20261106 f
INNER JOIN stg_orders s
    ON f.order_id = s.order_id;
    
    
SELECT
    f.order_id,
    f.financier,
    f.final_slash_amount
FROM loan_slash_final_20261106 f
LEFT JOIN stg_orders s
    ON f.order_id = s.order_id
WHERE s.order_id IS NULL;



USE carsome_orders_analysis;

SELECT
    COUNT(*) AS matched_records,

    SUM(
        CASE
            WHEN ROUND(f.loan_amount, 2)
                 <=> ROUND(s.loan_amount, 2)
            THEN 0 ELSE 1
        END
    ) AS loan_amount_mismatch,

    SUM(
        CASE
            WHEN f.loan_amount IS NULL
              OR s.loan_amount IS NULL
            THEN 1 ELSE 0
        END
    ) AS null_loan_amount_records

FROM loan_slash_final_20261106 f
JOIN stg_orders s
    ON f.order_id = s.order_id;
    
    
    
SELECT
    COUNT(*) AS matched_records,

    SUM(
        CASE
            WHEN LOWER(TRIM(f.financier))
                 <=> LOWER(TRIM(s.final_financier))
            THEN 0 ELSE 1
        END
    ) AS financier_mismatch

FROM loan_slash_final_20261106 f
JOIN stg_orders s
    ON f.order_id = s.order_id;
    
    
    
SELECT
    f.order_id,

    f.financier AS audit_financier,
    s.final_financier AS source_financier,

    f.loan_amount AS audit_loan_amount,
    s.loan_amount AS source_loan_amount,

    f.final_slash_amount

FROM loan_slash_final_20261106 f
JOIN stg_orders s
    ON f.order_id = s.order_id

WHERE
    NOT (
        LOWER(TRIM(f.financier))
        <=> LOWER(TRIM(s.final_financier))
    )
    OR NOT (
        ROUND(f.loan_amount, 2)
        <=> ROUND(s.loan_amount, 2)
    )

ORDER BY f.order_id;


USE carsome_orders_analysis;

CREATE TABLE loan_slash_analysis_20261106 AS
SELECT
    f.order_id,

    f.financier,
    s.order_status,
    s.created_time,
    s.store,

    s.loan_amount,
    f.final_slash_amount,

    ROUND(
        f.final_slash_amount / NULLIF(s.loan_amount, 0) * 100,
        2
    ) AS slash_to_loan_ratio_pct,

    s.loan_tenure,
    s.final_loan_type,

    CURRENT_TIMESTAMP AS analysis_created_at

FROM loan_slash_final_20261106 f

INNER JOIN stg_orders s
    ON f.order_id = s.order_id

WHERE f.final_slash_amount IS NOT NULL
  AND s.loan_amount > 0;
  
  
SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,

    SUM(final_slash_amount) AS total_slash_amount,

    SUM(loan_amount) AS total_loan_amount,

    ROUND(AVG(loan_amount), 2) AS avg_loan_amount,

    ROUND(AVG(final_slash_amount), 2) AS avg_slash_amount,

    ROUND(AVG(slash_to_loan_ratio_pct), 2)
        AS avg_slash_ratio_pct,

    MIN(slash_to_loan_ratio_pct) AS min_slash_ratio_pct,

    MAX(slash_to_loan_ratio_pct) AS max_slash_ratio_pct

FROM loan_slash_analysis_20261106;


SELECT
    financier,

    COUNT(*) AS slash_cases,

    ROUND(SUM(final_slash_amount), 2)
        AS total_slash_amount,

    ROUND(AVG(final_slash_amount), 2)
        AS avg_slash_amount,

    ROUND(AVG(loan_amount), 2)
        AS avg_loan_amount,

    ROUND(AVG(slash_to_loan_ratio_pct), 2)
        AS avg_slash_ratio_pct,

    ROUND(
        SUM(final_slash_amount) /
        NULLIF(SUM(loan_amount), 0) * 100,
        2
    ) AS weighted_slash_ratio_pct

FROM loan_slash_analysis_20261106

GROUP BY financier

ORDER BY weighted_slash_ratio_pct DESC;



SELECT
    order_id,
    financier,
    loan_amount,
    final_slash_amount,
    slash_to_loan_ratio_pct
FROM loan_slash_analysis_20261106
ORDER BY slash_to_loan_ratio_pct DESC;


USE carsome_orders_analysis;

SELECT
    COUNT(*) AS sample_size,

    ROUND(
        (
            COUNT(*) * SUM(loan_amount * final_slash_amount)
            - SUM(loan_amount) * SUM(final_slash_amount)
        )
        /
        NULLIF(
            SQRT(
                (
                    COUNT(*) * SUM(loan_amount * loan_amount)
                    - POW(SUM(loan_amount), 2)
                )
                *
                (
                    COUNT(*) * SUM(final_slash_amount * final_slash_amount)
                    - POW(SUM(final_slash_amount), 2)
                )
            ),
            0
        ),
        4
    ) AS pearson_correlation

FROM loan_slash_analysis_20261106;


SELECT
    CASE
        WHEN slash_to_loan_ratio_pct < 2
            THEN 'Below 2%'
        WHEN slash_to_loan_ratio_pct < 5
            THEN '2% - 5%'
        WHEN slash_to_loan_ratio_pct < 10
            THEN '5% - 10%'
        WHEN slash_to_loan_ratio_pct < 20
            THEN '10% - 20%'
        ELSE '20% and Above'
    END AS slash_ratio_group,

    COUNT(*) AS order_count,

    ROUND(
        COUNT(*) * 100.0 /
        (SELECT COUNT(*)
         FROM loan_slash_analysis_20261106),
        2
    ) AS percentage

FROM loan_slash_analysis_20261106
GROUP BY slash_ratio_group
ORDER BY MIN(slash_to_loan_ratio_pct);



USE carsome_orders_analysis;

SELECT
    a.order_id,
    a.financier,
    a.loan_amount,
    a.final_slash_amount,
    a.slash_to_loan_ratio_pct,
    a.loan_tenure,

    f.full_remark,
    f.matched_text

FROM loan_slash_analysis_20261106 a

JOIN loan_slash_final_20261106 f
    ON a.order_id = f.order_id

WHERE a.slash_to_loan_ratio_pct >= 20

ORDER BY a.slash_to_loan_ratio_pct DESC;


USE carsome_orders_analysis;

SHOW TABLES LIKE '%slash%';

SHOW CREATE TABLE loan_slash_audit;


SELECT
    validation_status,
    COUNT(*) AS record_count,
    COUNT(auto_slash_amount) AS auto_amount_count,
    COUNT(manual_slash_amount) AS manual_amount_count,
    COUNT(final_slash_amount) AS final_amount_count
FROM loan_slash_audit
GROUP BY validation_status
ORDER BY record_count DESC;


SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(auto_slash_amount) AS auto_amount_records,
    COUNT(manual_slash_amount) AS manual_amount_records,
    COUNT(final_slash_amount) AS final_amount_records
FROM loan_slash_audit;




-- 1. 检查三个表的结构
SHOW CREATE TABLE loan_slash_analysis_20261106;

SHOW CREATE TABLE loan_slash_audit_stage_20261106;

SHOW CREATE TABLE loan_slash_final_20261106;


-- 2. 检查三个表的记录数量
SELECT 'loan_slash_analysis_20261106' AS table_name,
       COUNT(*) AS total_records
FROM loan_slash_analysis_20261106

UNION ALL

SELECT 'loan_slash_audit_stage_20261106',
       COUNT(*)
FROM loan_slash_audit_stage_20261106

UNION ALL

SELECT 'loan_slash_final_20261106',
       COUNT(*)
FROM loan_slash_final_20261106;




-- 3. 查看主审计表中已确认记录的金额字段
SELECT
    order_id,
    financier,
    loan_amount,
    auto_slash_amount,
    manual_slash_amount,
    final_slash_amount,
    validation_status,
    audit_reason
FROM loan_slash_audit
WHERE validation_status IN (
    'Manually Confirmed',
    'Manual Review - Amount Consistency',
    'Rejected - False Extraction'
)
ORDER BY validation_status, order_id;





SELECT
    validation_status,
    final_amount_source,
    COUNT(*) AS record_count,
    COUNT(final_slash_amount) AS final_amount_count,
    COUNT(auto_slash_amount) AS auto_amount_count,
    COUNT(manual_slash_amount) AS manual_amount_count
FROM loan_slash_final_20261106
GROUP BY
    validation_status,
    final_amount_source
ORDER BY record_count DESC;



SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT order_id) AS unique_orders,
    COUNT(final_slash_amount) AS records_with_final_amount,
    SUM(final_slash_amount IS NULL) AS missing_final_amount,
    SUM(final_slash_amount <= 0) AS non_positive_amount
FROM loan_slash_final_20261106;






SELECT
    COUNT(*) AS matched_orders,
    SUM(f.final_slash_amount IS NULL) AS final_missing_amount,
    SUM(a.final_slash_amount IS NULL) AS analysis_missing_amount,
    SUM(
        f.final_slash_amount <> a.final_slash_amount
    ) AS amount_mismatch
FROM loan_slash_final_20261106 f
LEFT JOIN loan_slash_analysis_20261106 a
    ON f.order_id = a.order_id;
    
    
    
    
SELECT
    f.order_id,
    f.financier,
    f.loan_amount,
    f.auto_slash_amount,
    f.manual_slash_amount,
    f.final_slash_amount,
    f.validation_status,
    f.final_amount_source,
    a.final_slash_amount AS analysis_slash_amount,
    a.slash_to_loan_ratio_pct
FROM loan_slash_final_20261106 f
LEFT JOIN loan_slash_analysis_20261106 a
    ON f.order_id = a.order_id
WHERE
    f.final_slash_amount IS NULL
    OR a.order_id IS NULL
    OR f.final_slash_amount <> a.final_slash_amount
ORDER BY f.order_id;



USE carsome_orders_analysis;

SELECT *
FROM loan_slash_analysis_20261106
LIMIT 10;