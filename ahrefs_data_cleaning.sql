-- =============================================================================
-- Ahrefs Keyword Export — Data Cleaning Script
-- Author : Munyai Khuthadzo
-- Version: 1.0
-- =============================================================================
-- PURPOSE
-- Raw keyword exports from Ahrefs are rarely analysis-ready. This script
-- systematically cleans a keyword dataset exported from Ahrefs, addressing
-- the most common data quality issues found in real-world SEO exports.
--
-- Each cleaning step is documented with:
--   > The problem it solves
--   > The logic behind the approach
--   > The expected result after cleaning
--
-- CLEANING WORKFLOW
--   Step 1 : Standardise text capitalisation
--   Step 2 : Replace non-standard null representations
--   Step 3 : Remove empty string values
--   Step 4 : Standardise domain rating values
--   Step 5 : Standardise date formats
--   Step 6 : Identify and remove duplicate rows
--
-- TABLE REFERENCED
--   ahrefs_data : Raw keyword export from Ahrefs containing keyword, country,
--                 device, intent, search volume, position, traffic, URL,
--                 domain rating, CPC and export date columns
--
-- NOTE
-- Safe update mode is toggled off before each UPDATE statement and restored
-- immediately after. This is required when updating all rows without a key
-- column in the WHERE clause. Safe mode is always restored after each step.
-- =============================================================================


-- =============================================================================
-- STEP 1: STANDARDISE TEXT CAPITALISATION
-- =============================================================================
--
-- PROBLEM
-- Text columns contain inconsistent capitalisation across rows. The same
-- keyword appears as 'local seo checklist', 'LOCAL SEO CHECKLIST' and
-- 'Local Seo Checklist' — SQL treats these as different values, which causes
-- incorrect duplicate detection, incorrect grouping and unreliable analysis.
--
-- APPROACH
-- Apply LOWER() to all text columns to standardise every value to lowercase.
-- This ensures consistent matching across keyword, country, device, intent
-- and URL columns before any further cleaning or analysis is performed.
-- =============================================================================

SET SQL_SAFE_UPDATES = 0;

UPDATE ahrefs_data
SET
    keyword = LOWER(keyword),
    country = LOWER(country),
    device  = LOWER(device),
    intent  = LOWER(intent),
    url     = LOWER(url);

SET SQL_SAFE_UPDATES = 1;

-- RESULT
-- All text columns are now lowercase. 'LOCAL SEO CHECKLIST', 'Local Seo
-- Checklist' and 'local seo checklist' are now identical values and will
-- be correctly identified as duplicates in subsequent steps.
-- =============================================================================


-- =============================================================================
-- STEP 2: REPLACE NON-STANDARD NULL REPRESENTATIONS
-- =============================================================================
--
-- PROBLEM
-- Missing values in this export are represented inconsistently. Some columns
-- use the word 'unknown', others use 'N/A' and others use the word 'missing'.
-- SQL does not recognise these as missing data — it treats them as valid text
-- strings, which breaks numeric calculations, averages and filters.
--
-- APPROACH
-- Replace each non-standard representation with a true SQL NULL value.
-- NULL is the correct way to represent missing data in SQL and allows
-- aggregate functions like AVG() and COUNT() to handle missing data correctly.
-- Each column is updated independently using CASE WHEN to avoid overwriting
-- valid data in rows where only some columns are affected.
-- =============================================================================

-- 2A: Replace 'unknown' with NULL in current_position
SET SQL_SAFE_UPDATES = 0;

UPDATE ahrefs_data
SET current_position = NULL
WHERE current_position = 'unknown';

SET SQL_SAFE_UPDATES = 1;

-- 2B: Replace 'N/A' and 'missing' with NULL across affected columns
SET SQL_SAFE_UPDATES = 0;

UPDATE ahrefs_data
SET
    search_volume = CASE WHEN search_volume = 'N/A' THEN NULL ELSE search_volume END,
    cpc           = CASE WHEN cpc = 'N/A'           THEN NULL ELSE cpc           END,
    traffic       = CASE WHEN traffic = 'missing'   THEN NULL ELSE traffic       END;

SET SQL_SAFE_UPDATES = 1;

-- RESULT
-- All non-standard representations of missing data have been replaced with
-- true NULL values. Aggregate functions and filters will now handle missing
-- data correctly across all affected columns.
-- =============================================================================


-- =============================================================================
-- STEP 3: REMOVE EMPTY STRING VALUES
-- =============================================================================
--
-- PROBLEM
-- Some cells appear empty but contain whitespace characters rather than NULL.
-- SQL does not treat an empty string or a string of spaces as NULL — these
-- values would be included in counts and cause incorrect analysis results.
--
-- APPROACH
-- Apply TRIM() to remove leading and trailing whitespace from each column,
-- then check if the result is an empty string. If it is, replace it with NULL.
-- This covers both completely empty strings ('') and strings containing
-- only whitespace (' '). Applied to all columns that could be affected.
-- =============================================================================

SET SQL_SAFE_UPDATES = 0;

UPDATE ahrefs_data
SET
    search_volume    = CASE WHEN TRIM(search_volume)    = '' THEN NULL ELSE search_volume    END,
    current_position = CASE WHEN TRIM(current_position) = '' THEN NULL ELSE current_position END,
    traffic          = CASE WHEN TRIM(traffic)          = '' THEN NULL ELSE traffic          END,
    cpc              = CASE WHEN TRIM(cpc)              = '' THEN NULL ELSE cpc              END,
    url              = CASE WHEN TRIM(url)              = '' THEN NULL ELSE url              END,
    domain_rating    = CASE WHEN TRIM(domain_rating)    = '' THEN NULL ELSE domain_rating    END,
    export_date      = CASE WHEN TRIM(export_date)      = '' THEN NULL ELSE export_date      END;

SET SQL_SAFE_UPDATES = 1;

-- RESULT
-- All empty strings and whitespace-only values have been replaced with NULL
-- across all affected columns. The dataset now has consistent NULL handling
-- for all missing data regardless of how it was originally represented.
-- =============================================================================


-- =============================================================================
-- STEP 4: STANDARDISE DOMAIN RATING VALUES
-- =============================================================================
--
-- PROBLEM
-- The domain_rating column contains a mix of numeric values (e.g. 70.8, 96.1)
-- and the word 'high'. Domain Rating is a numeric score from 0 to 100 in
-- Ahrefs. The word 'high' cannot be used in numeric calculations or
-- comparisons and its exact value is unknown.
--
-- APPROACH
-- Replace 'high' with NULL rather than inventing a numeric equivalent.
-- Substituting an assumed value (e.g. 70) would introduce inaccurate data.
-- NULL correctly represents that the exact value is unknown, preserving
-- data integrity for all downstream analysis.
-- =============================================================================

SET SQL_SAFE_UPDATES = 0;

UPDATE ahrefs_data
SET domain_rating = NULL
WHERE domain_rating = 'high';

SET SQL_SAFE_UPDATES = 1;

-- RESULT
-- All 'high' values in the domain_rating column have been replaced with NULL.
-- The column now contains only numeric values and NULLs, making it suitable
-- for filtering, averaging and comparison in analysis queries.
-- =============================================================================


-- =============================================================================
-- STEP 5: STANDARDISE DATE FORMATS
-- =============================================================================
--
-- PROBLEM
-- The export_date column contains dates in two different formats:
-- 'YYYY-MM-DD' (e.g. 2025-09-17) and 'DD/MM/YYYY' (e.g. 04/04/2026).
-- Mixed date formats prevent correct date sorting, filtering and trend
-- analysis. SQL requires a consistent format to treat values as dates.
--
-- APPROACH
-- Use STR_TO_DATE() to convert slash-formatted dates to the standard
-- SQL date format YYYY-MM-DD. The WHERE clause targets only rows containing
-- a slash character using LIKE '%/%', ensuring correctly formatted dates
-- are not affected.
-- =============================================================================

SET SQL_SAFE_UPDATES = 0;

UPDATE ahrefs_data
SET export_date = STR_TO_DATE(export_date, '%d/%m/%Y')
WHERE export_date LIKE '%/%';

SET SQL_SAFE_UPDATES = 1;

-- RESULT
-- All dates are now in the consistent YYYY-MM-DD format. The export_date
-- column can now be used reliably for date filtering, sorting and trend
-- analysis across the dataset.
-- =============================================================================


-- =============================================================================
-- STEP 6: IDENTIFY AND REMOVE DUPLICATE ROWS
-- =============================================================================
--
-- PROBLEM
-- The dataset contains duplicate rows where the same keyword appears multiple
-- times for the same country, device and intent combination. True duplicates
-- waste storage, skew analysis and produce inflated keyword counts.
--
-- NOTE: Not all repeated keywords are duplicates. The same keyword ranking
-- in different countries, on different devices or with different intent
-- classifications represents genuinely different data and must be preserved.
-- A true duplicate is defined as a row sharing the same keyword, country,
-- device AND intent.
--
-- APPROACH
-- Use ROW_NUMBER() with PARTITION BY to assign a number to each row within
-- each unique keyword + country + device + intent group. Rows are ordered
-- by data completeness — prioritising rows that have values in the most
-- important analysis columns (search_volume, current_position, cpc).
-- Selecting only rows where row_num = 1 returns one complete row per group,
-- discarding all true duplicates while preserving legitimate variations.
-- =============================================================================

WITH ranked_keywords AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY keyword, country, intent, device
            ORDER BY
                CASE WHEN search_volume    IS NULL THEN 1 ELSE 0 END,
                CASE WHEN current_position IS NULL THEN 1 ELSE 0 END,
                CASE WHEN cpc              IS NULL THEN 1 ELSE 0 END
        ) AS row_num
    FROM
        ahrefs_data
)
SELECT *
FROM ranked_keywords
WHERE row_num = 1;

-- RESULT
-- Returns one row per unique keyword + country + device + intent combination.
-- Within each group the most complete row is retained — prioritising rows
-- with search volume, position and CPC data. All true duplicates are excluded
-- from the result while legitimate keyword variations across different
-- countries, devices and intents are preserved.
-- =============================================================================
