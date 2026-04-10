-- ============================================================
-- GOOGLE SEARCH CONSOLE SQL QUERY LIBRARY
-- Author: Khuthadzo Munyai
-- GitHub: github.com/Munyai-Khuthadzo/seo-sql-audit-library
-- Description: SQL queries for analysing Google Search Console
--              export data to find traffic opportunities,
--              quick wins, keyword gaps, and CTR improvements
-- Compatible: MySQL 5.7+ / MariaDB 10.3+
-- ============================================================


-- ============================================================
-- SECTION 1: DATABASE SETUP
-- ============================================================

USE seo_audits;

DROP TABLE IF EXISTS gsc_data;

-- Create table matching Google Search Console CSV export format
-- Export from: GSC → Performance → Export → Download CSV
CREATE TABLE gsc_data (
  id          INT AUTO_INCREMENT PRIMARY KEY,
  query       VARCHAR(500),
  clicks      INT,
  impressions INT,
  ctr         DECIMAL(6,2),
  position    DECIMAL(6,2),
  page        VARCHAR(500)
);

-- Import CSV using MySQL Workbench Table Data Import Wizard
-- Or use: LOAD DATA LOCAL INFILE 'path/to/gsc_export.csv'
--         INTO TABLE gsc_data
--         FIELDS TERMINATED BY ','
--         ENCLOSED BY '"'
--         LINES TERMINATED BY '\n'
--         IGNORE 1 ROWS;


-- ============================================================
-- SECTION 2: VERIFICATION
-- ============================================================

-- Confirm import worked correctly
SELECT COUNT(*) as total_keywords FROM gsc_data;

-- Preview data
SELECT * FROM gsc_data LIMIT 10;

-- Overall traffic summary
SELECT
  SUM(clicks) as total_clicks,
  SUM(impressions) as total_impressions,
  ROUND(SUM(clicks) * 100.0 / SUM(impressions), 2) as overall_ctr,
  ROUND(AVG(position), 1) as avg_position
FROM gsc_data;


-- ============================================================
-- SECTION 3: BRANDED VS NON-BRANDED ANALYSIS
-- ============================================================

-- QUERY 1: Split traffic by branded vs non-branded
-- Replace '%yourbrand%' with your actual brand name
-- Impact: Reveals over-reliance on brand searches
SELECT
  CASE
    WHEN query LIKE '%yourbrand%' THEN 'Branded'
    ELSE 'Non-Branded'
  END as traffic_type,
  COUNT(*) as total_queries,
  SUM(clicks) as total_clicks,
  SUM(impressions) as total_impressions,
  ROUND(AVG(ctr), 2) as avg_ctr,
  ROUND(AVG(position), 1) as avg_position
FROM gsc_data
GROUP BY traffic_type
ORDER BY total_clicks DESC;

-- What to look for:
-- Branded CTR should be 20-40% (people searching your name click through)
-- Non-branded CTR under 3% = title/meta description problem
-- If branded clicks > non-branded clicks = dangerous dependency


-- ============================================================
-- SECTION 4: QUICK WINS — HIGH IMPRESSION LOW CTR
-- ============================================================

-- QUERY 2: Find quick win keywords
-- Already ranking page 1 but users not clicking
-- Fix: rewrite title tag and meta description
SELECT
  query,
  clicks,
  impressions,
  ctr,
  position,
  page
FROM gsc_data
WHERE impressions > 300
AND ctr < 3.0
AND position BETWEEN 1 AND 10
ORDER BY impressions DESC;

-- QUERY 3: Quantify the opportunity — clicks being left on table
-- Shows how many extra clicks you'd get at 5% CTR benchmark
SELECT
  query,
  clicks,
  impressions,
  ctr,
  position,
  page,
  ROUND((impressions * 0.05) - clicks, 0) as potential_extra_clicks
FROM gsc_data
WHERE position <= 10
AND ctr < 5.0
AND impressions > 100
AND query NOT LIKE '%yourbrand%'
ORDER BY potential_extra_clicks DESC;

-- QUERY 4: Total traffic opportunity from CTR improvements
SELECT
  ROUND(SUM(impressions * 0.05) - SUM(clicks), 0) as total_extra_clicks_at_5pct,
  SUM(clicks) as current_clicks,
  SUM(impressions) as total_impressions
FROM gsc_data
WHERE position <= 10
AND ctr < 5.0
AND query NOT LIKE '%yourbrand%';


-- ============================================================
-- SECTION 5: KEYWORD GAP ANALYSIS — PAGE 2 OPPORTUNITIES
-- ============================================================

-- QUERY 5: Keywords ranking page 2-3 — close to page 1
-- Small content improvements could push these to page 1
-- Position 11 to position 5 = typically 5-10x more traffic
SELECT
  query,
  clicks,
  impressions,
  ctr,
  position,
  page
FROM gsc_data
WHERE position BETWEEN 11 AND 20
AND impressions > 200
ORDER BY impressions DESC;

-- QUERY 6: Keywords deep on page 3+ — need more work
SELECT
  query,
  clicks,
  impressions,
  ctr,
  position,
  page
FROM gsc_data
WHERE position > 20
AND impressions > 100
ORDER BY impressions DESC;


-- ============================================================
-- SECTION 6: PAGE PERFORMANCE ANALYSIS
-- ============================================================

-- QUERY 7: Performance summary per page
-- Shows which pages drive traffic and which underperform
SELECT
  page,
  COUNT(*) as total_queries,
  SUM(clicks) as total_clicks,
  SUM(impressions) as total_impressions,
  ROUND(SUM(clicks) * 100.0 /
    NULLIF(SUM(impressions), 0), 2) as overall_ctr,
  ROUND(AVG(position), 1) as avg_position
FROM gsc_data
GROUP BY page
ORDER BY total_clicks DESC;

-- QUERY 8: Find pages with low CTR despite good positions
-- These pages need title tag and meta description rewrites
SELECT
  page,
  COUNT(*) as queries,
  SUM(clicks) as clicks,
  SUM(impressions) as impressions,
  ROUND(AVG(ctr), 2) as avg_ctr,
  ROUND(AVG(position), 1) as avg_position
FROM gsc_data
WHERE position <= 10
GROUP BY page
HAVING avg_ctr < 3.0
AND impressions > 200
ORDER BY impressions DESC;


-- ============================================================
-- SECTION 7: CANNIBALIZATION DETECTION
-- ============================================================

-- QUERY 9: Find keywords where multiple pages compete
-- Multiple pages ranking for same keyword = cannibalization
SELECT
  query,
  COUNT(DISTINCT page) as pages_ranking,
  GROUP_CONCAT(DISTINCT page SEPARATOR ' | ') as competing_pages,
  SUM(clicks) as total_clicks,
  SUM(impressions) as total_impressions
FROM gsc_data
GROUP BY query
HAVING pages_ranking > 1
ORDER BY total_impressions DESC;

-- No results = good news, no cannibalization detected
-- Results = review competing pages and consolidate or differentiate


-- ============================================================
-- SECTION 8: INTENT MISMATCH DETECTION
-- ============================================================

-- QUERY 10: Find informational keywords ranking on service pages
-- Informational queries (what is, how to) should rank on blog posts
-- If ranking on homepage/service pages = intent mismatch
SELECT
  query,
  page,
  position,
  impressions,
  ctr
FROM gsc_data
WHERE (query LIKE '%what is%'
   OR query LIKE '%how to%'
   OR query LIKE '%what are%'
   OR query LIKE '%guide%'
   OR query LIKE '%examples%'
   OR query LIKE '%meaning%')
AND page NOT LIKE '%blog%'
AND page NOT LIKE '%guide%'
AND page NOT LIKE '%article%'
ORDER BY impressions DESC;

-- Results = these keywords need dedicated blog posts
-- Currently ranking on wrong pages = low CTR and poor user experience


-- ============================================================
-- SECTION 9: COMPLETE ACTION PLAN QUERY
-- ============================================================

-- QUERY 11: Master quick wins report with recommended actions
-- Automatically labels every keyword with what to do next
SELECT
  query,
  clicks,
  impressions,
  ctr,
  position,
  page,
  CASE
    WHEN position <= 10 AND ctr < 3.0
      THEN 'Fix CTR — rewrite title tag and meta description'
    WHEN position BETWEEN 11 AND 15
      THEN 'Push to page 1 — improve page content and internal links'
    WHEN position BETWEEN 16 AND 20
      THEN 'Wrong page — create dedicated content targeting this keyword'
    WHEN position > 20
      THEN 'Too deep — needs full SEO content and link building work'
    WHEN position <= 10 AND ctr >= 3.0
      THEN 'Performing well — maintain and monitor'
    ELSE 'Review manually'
  END as recommended_action
FROM gsc_data
WHERE impressions > 100
AND query NOT LIKE '%yourbrand%'
ORDER BY impressions DESC;


-- ============================================================
-- SECTION 10: REPORTING QUERIES
-- ============================================================

-- QUERY 12: Executive summary scorecard
SELECT 'Total Keywords Tracked' as metric,
  COUNT(*) as value
FROM gsc_data

UNION ALL

SELECT 'Total Clicks', SUM(clicks)
FROM gsc_data

UNION ALL

SELECT 'Total Impressions', SUM(impressions)
FROM gsc_data

UNION ALL

SELECT 'Keywords on Page 1 (pos 1-10)',
  COUNT(*)
FROM gsc_data
WHERE position <= 10

UNION ALL

SELECT 'Keywords on Page 2 (pos 11-20)',
  COUNT(*)
FROM gsc_data
WHERE position BETWEEN 11 AND 20

UNION ALL

SELECT 'Keywords on Page 3+ (pos 21+)',
  COUNT(*)
FROM gsc_data
WHERE position > 20

UNION ALL

SELECT 'Quick Win Keywords (page 1, CTR under 3%)',
  COUNT(*)
FROM gsc_data
WHERE position <= 10
AND ctr < 3.0
AND impressions > 100

UNION ALL

SELECT 'Informational Keywords on Wrong Pages',
  COUNT(*)
FROM gsc_data
WHERE (query LIKE '%what is%' OR query LIKE '%how to%')
AND page NOT LIKE '%blog%';


-- ============================================================
-- HOW TO USE THIS LIBRARY
-- ============================================================
-- 1. Export data from Google Search Console:
--    Performance → Export → Download CSV
-- 2. Run Section 1 to create gsc_data table
-- 3. Import CSV using Table Data Import Wizard
-- 4. Replace '%yourbrand%' with your actual brand name
-- 5. Run Section 2 to verify import
-- 6. Run queries from Sections 3-10 as needed
-- 7. Document findings in your audit report
--
-- COMBINE WITH SCREAMING FROG DATA:
-- Cross-reference gsc_data with crawl_data to connect
-- rankings data with technical issues:
-- Pages ranking poorly (GSC) + missing H1 (Screaming Frog)
-- = clear technical fix for ranking improvement
--
-- GITHUB: github.com/Munyai-Khuthadzo/seo-sql-audit-library
-- ============================================================
