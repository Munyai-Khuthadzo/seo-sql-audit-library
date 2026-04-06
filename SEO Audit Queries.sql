-- ============================================================
-- SEO AUDIT QUERY LIBRARY
-- Author: Khuthadzo
-- GitHub: github.com/khuthadzo/seo-sql-audit-library
-- Description: Reusable SQL queries for technical SEO audits
--              using Screaming Frog crawl data imported into MySQL
-- Compatible: MySQL 5.7+ / MariaDB 10.3+
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE SETUP
-- Run these queries first to create your audit environment
-- ============================================================

-- Create the SEO audits database
CREATE DATABASE IF NOT EXISTS seo_audits;
USE seo_audits;

-- Drop existing table if re-importing fresh crawl data
DROP TABLE IF EXISTS crawl_data;

-- Create table matching Screaming Frog internal tab CSV export
-- Only essential SEO columns are retained for performance
CREATE TABLE crawl_data (
  id                          INT AUTO_INCREMENT PRIMARY KEY,
  address                     VARCHAR(500),
  content_type                VARCHAR(100),
  status_code                 INT,
  status                      VARCHAR(50),
  indexability                VARCHAR(50),
  indexability_status         VARCHAR(100),
  title_1                     VARCHAR(500),
  title_1_length              INT,
  meta_description_1          TEXT,
  meta_description_1_length   INT,
  h1_1                        VARCHAR(500),
  h1_1_length                 INT,
  h2_1                        VARCHAR(500),
  h2_1_length                 INT,
  h2_2                        VARCHAR(500),
  h2_2_length                 INT,
  canonical_link_element_1    VARCHAR(500),
  word_count                  INT,
  crawl_depth                 INT,
  inlinks                     INT,
  unique_inlinks              INT,
  response_time               DECIMAL(10,4),
  redirect_url                VARCHAR(500),
  redirect_type               VARCHAR(50),
  size_bytes                  INT,
  language                    VARCHAR(50),
  crawl_timestamp             VARCHAR(100)
);

-- After creating the table:
-- 1. Open MySQL Workbench
-- 2. Right-click crawl_data table
-- 3. Select Table Data Import Wizard
-- 4. Browse to your Screaming Frog CSV export
-- 5. Map columns and execute


-- ============================================================
-- SECTION 2: VERIFICATION QUERIES
-- Always run these first to confirm data imported correctly
-- ============================================================

-- Check total rows imported
SELECT COUNT(*) as total_urls_imported
FROM crawl_data;

-- Preview first 5 rows
SELECT
  address,
  status_code,
  title_1,
  meta_description_1_length,
  h1_1,
  response_time
FROM crawl_data
LIMIT 5;

-- Status code breakdown — overall site health
SELECT
  status_code,
  status,
  COUNT(*) as url_count,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM crawl_data), 2) as percentage
FROM crawl_data
GROUP BY status_code, status
ORDER BY url_count DESC;


-- ============================================================
-- SECTION 3: ON-PAGE SEO QUERIES
-- Find missing and weak on-page elements
-- ============================================================

-- QUERY 1: Missing Meta Descriptions
-- Finds all indexable HTML pages with no meta description
-- Impact: Google auto-generates descriptions — reduces CTR
SELECT
  address,
  title_1,
  meta_description_1_length
FROM crawl_data
WHERE (meta_description_1 IS NULL
   OR meta_description_1 = '')
AND status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'
AND address NOT LIKE '%wp-includes%'
ORDER BY inlinks DESC;


-- QUERY 2: Missing H1 Tags
-- Finds all pages with no H1 tag
-- Impact: Google loses primary on-page topic signal
SELECT
  address,
  title_1,
  h1_1,
  h1_1_length,
  inlinks
FROM crawl_data
WHERE (h1_1 IS NULL
   OR h1_1 = '')
AND status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'
AND address NOT LIKE '%wp-includes%'
ORDER BY inlinks DESC;


-- QUERY 3: Short Title Tags
-- Finds pages with title tags under 30 characters
-- Impact: Not using full 60 character keyword opportunity
SELECT
  address,
  title_1,
  title_1_length
FROM crawl_data
WHERE title_1_length < 30
AND title_1_length > 0
AND status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'
ORDER BY title_1_length ASC;


-- QUERY 4: Long Title Tags
-- Finds pages with title tags over 60 characters
-- Impact: Google truncates titles in search results
SELECT
  address,
  title_1,
  title_1_length
FROM crawl_data
WHERE title_1_length > 60
AND status_code = 200
AND content_type LIKE '%html%'
ORDER BY title_1_length DESC;


-- QUERY 5: Long Meta Descriptions
-- Finds meta descriptions over 160 characters
-- Impact: Google truncates — loses call to action
SELECT
  address,
  meta_description_1,
  meta_description_1_length
FROM crawl_data
WHERE meta_description_1_length > 160
AND status_code = 200
AND content_type LIKE '%html%'
ORDER BY meta_description_1_length DESC;


-- QUERY 6: Duplicate H2 Tags Across Pages
-- Finds H2 text appearing on more than one page
-- Impact: Inconsistent heading structure confuses Google
SELECT
  h2_1,
  COUNT(*) as pages_using_this_h2,
  GROUP_CONCAT(address SEPARATOR ' | ') as pages
FROM crawl_data
WHERE h2_1 IS NOT NULL
AND h2_1 != ''
AND status_code = 200
GROUP BY h2_1
HAVING COUNT(*) > 1
ORDER BY pages_using_this_h2 DESC;


-- QUERY 7: Thin Content Pages
-- Finds real HTML pages with fewer than 300 words
-- Impact: Google may consider thin content low quality
SELECT
  address,
  title_1,
  word_count,
  inlinks
FROM crawl_data
WHERE word_count < 300
AND word_count > 0
AND status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'
AND address NOT LIKE '%wp-includes%'
ORDER BY word_count ASC;


-- ============================================================
-- SECTION 4: TECHNICAL SEO QUERIES
-- Find crawl, indexation and performance issues
-- ============================================================

-- QUERY 8: Slow Response Times
-- Finds pages with server response over 1.5 seconds
-- Impact: Slow TTFB cascades into failing Core Web Vitals
SELECT
  address,
  response_time,
  size_bytes,
  word_count,
  inlinks
FROM crawl_data
WHERE response_time > 1.5
AND status_code = 200
AND content_type LIKE '%html%'
ORDER BY response_time DESC;


-- QUERY 9: Canonical Tag Audit
-- Detects missing, self-referencing, and mismatched canonicals
-- Impact: WWW/non-WWW mismatches invisible to manual review
SELECT
  address,
  canonical_link_element_1,
  CASE
    WHEN canonical_link_element_1 IS NULL
      OR canonical_link_element_1 = ''
    THEN 'Missing Canonical'
    WHEN canonical_link_element_1 = address
    THEN 'Self Referencing OK'
    ELSE 'Points Elsewhere — Review Needed'
  END as canonical_status
FROM crawl_data
WHERE status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'
AND address NOT LIKE '%wp-includes%'
ORDER BY canonical_status;


-- QUERY 10: Non-Indexable Pages
-- Finds pages blocked from Google indexation
-- Impact: Important pages may be accidentally blocked
SELECT
  address,
  indexability,
  indexability_status,
  title_1
FROM crawl_data
WHERE indexability = 'Non-Indexable'
AND status_code = 200
ORDER BY inlinks DESC;


-- QUERY 11: Redirect Chains
-- Finds pages returning 301 redirects — potential chains
-- Impact: Each redirect hop wastes crawl budget and dilutes PageRank
SELECT
  address,
  redirect_url,
  redirect_type,
  status_code
FROM crawl_data
WHERE status_code IN (301, 302)
ORDER BY address;


-- QUERY 12: WordPress System Files Being Crawled
-- Identifies WordPress infrastructure files in crawl
-- Impact: Googlebot wastes crawl budget on non-content files
SELECT
  address,
  content_type,
  status_code,
  size_bytes
FROM crawl_data
WHERE (address LIKE '%wp-content%'
   OR address LIKE '%wp-includes%'
   OR address LIKE '%wp-admin%')
ORDER BY address;


-- QUERY 13: Orphaned Pages
-- Finds pages with very few inlinks — hard for Google to discover
-- Impact: Pages with no internal links may never be crawled
SELECT
  address,
  title_1,
  inlinks,
  unique_inlinks,
  word_count
FROM crawl_data
WHERE inlinks <= 1
AND status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'
ORDER BY inlinks ASC;


-- QUERY 14: Deep Pages
-- Finds pages buried more than 3 clicks from homepage
-- Impact: Deep pages receive less crawl attention and PageRank
SELECT
  address,
  crawl_depth,
  inlinks,
  title_1
FROM crawl_data
WHERE crawl_depth > 3
AND status_code = 200
AND content_type LIKE '%html%'
ORDER BY crawl_depth DESC;


-- ============================================================
-- SECTION 5: CRAWL BUDGET ANALYSIS
-- Quantify crawl budget waste for client reporting
-- ============================================================

-- QUERY 15: Crawl Budget Waste Breakdown
-- Shows percentage of crawl spent on non-200 responses
-- Use this to quantify waste as a % for client reports
SELECT
  CASE
    WHEN status_code = 200 THEN 'Productive Crawls'
    WHEN status_code = 301 THEN 'Redirect Waste'
    WHEN status_code = 302 THEN 'Temporary Redirect Waste'
    WHEN status_code = 404 THEN 'Broken Page Waste'
    WHEN status_code = 500 THEN 'Server Error Waste'
    ELSE 'Other'
  END as crawl_type,
  COUNT(*) as total_crawls,
  ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM crawl_data), 2) as percentage
FROM crawl_data
GROUP BY crawl_type
ORDER BY total_crawls DESC;


-- QUERY 16: Internal Linking Structure
-- Shows which pages receive the most internal link equity
-- Use to identify poor internal linking patterns
SELECT
  address,
  title_1,
  inlinks,
  unique_inlinks,
  crawl_depth
FROM crawl_data
WHERE status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'
AND address NOT LIKE '%wp-includes%'
ORDER BY inlinks DESC;


-- ============================================================
-- SECTION 6: MASTER OVERVIEW QUERY
-- Complete per-page snapshot — run this for full audit picture
-- ============================================================

-- QUERY 17: Complete SEO Audit Overview
-- All key metrics per page in one view
-- Use as starting point for any audit
SELECT
  address,
  status_code,
  indexability,
  title_1,
  title_1_length,
  meta_description_1_length,
  h1_1,
  h1_1_length,
  word_count,
  response_time,
  inlinks,
  canonical_link_element_1,
  crawl_depth
FROM crawl_data
WHERE status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'
AND address NOT LIKE '%wp-includes%'
ORDER BY inlinks DESC;


-- ============================================================
-- SECTION 7: QUICK AUDIT SCORECARD
-- Run this for a fast summary of site health
-- ============================================================

SELECT 'Total Pages Crawled' as metric,
  COUNT(*) as value
FROM crawl_data
WHERE status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'

UNION ALL

SELECT 'Missing Meta Descriptions',
  COUNT(*)
FROM crawl_data
WHERE (meta_description_1 IS NULL OR meta_description_1 = '')
AND status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'

UNION ALL

SELECT 'Missing H1 Tags',
  COUNT(*)
FROM crawl_data
WHERE (h1_1 IS NULL OR h1_1 = '')
AND status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'

UNION ALL

SELECT 'Short Title Tags (under 30 chars)',
  COUNT(*)
FROM crawl_data
WHERE title_1_length < 30
AND title_1_length > 0
AND status_code = 200
AND content_type LIKE '%html%'
AND address NOT LIKE '%wp-content%'

UNION ALL

SELECT 'Slow Pages (over 1.5s response)',
  COUNT(*)
FROM crawl_data
WHERE response_time > 1.5
AND status_code = 200
AND content_type LIKE '%html%'

UNION ALL

SELECT 'Redirect Pages',
  COUNT(*)
FROM crawl_data
WHERE status_code IN (301, 302)

UNION ALL

SELECT 'Broken Pages (404)',
  COUNT(*)
FROM crawl_data
WHERE status_code = 404;


-- ============================================================
-- HOW TO USE THIS LIBRARY
-- ============================================================
-- 1. Crawl your target website using Screaming Frog
-- 2. Export the Internal tab as CSV
-- 3. Run Section 1 to create your database and table
-- 4. Import the CSV using MySQL Table Data Import Wizard
-- 5. Run Section 2 verification queries to confirm import
-- 6. Run any queries from Sections 3-6 as needed
-- 7. Document findings in your audit report
--
-- REUSABILITY: These queries work on any website.
-- Simply import a new Screaming Frog CSV into the
-- crawl_data table and run the same queries.
--
-- GITHUB: github.com/khuthadzo/seo-sql-audit-library
-- ============================================================
