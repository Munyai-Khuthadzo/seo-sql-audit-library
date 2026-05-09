-- =============================================================================
-- SEO SQL Audit Library
-- Enterprise Technical SEO Queries
-- Author : Munyai Khuthadzo
-- Version: 1.0
-- =============================================================================
-- PURPOSE
-- This library contains SQL audit queries designed to identify and diagnose
-- technical SEO issues at scale for high-volume websites (50,000+ pages).
--
-- Each query is documented with:
--   > The problem it solves
--   > The logic behind the approach
--   > The expected result and its business meaning
--
-- TABLES REFERENCED
--   site_data        : Sitemap data — URLs intended to be indexed
--   crawl_data       : Crawl data — URLs discovered with link and tag metadata
--   performance_data : Page performance data — LCP scores, resource URLs, templates
-- =============================================================================


-- =============================================================================
-- SECTION 1: ORPHAN PAGE DETECTION
-- =============================================================================
--
-- PROBLEM
-- Orphan pages are indexable URLs that exist in the sitemap but have zero
-- internal links pointing to them. Search engines struggle to discover and
-- prioritise these pages because no other page on the site references them.
-- On a high-volume site, orphan pages represent wasted crawl budget and
-- lost ranking potential.
--
-- APPROACH
-- Join the sitemap data (our source of truth for intended indexable pages)
-- against the crawl data (which captures internal link counts per URL).
-- A LEFT JOIN returns all sitemap URLs — including those with no crawl match.
-- Filtering on NULL or zero internal links surfaces the orphans.
-- Filtering on indexability_status ensures we only flag pages that are
-- intended to be indexed — excluding pages that are intentionally unlinked
-- (e.g. thank-you pages, login pages, admin routes).
-- =============================================================================

SELECT
    s.url
FROM
    site_data s
    LEFT JOIN crawl_data c ON c.url = s.url
WHERE
    (c.internal_links IS NULL OR c.internal_links = 0)
    AND s.indexability_status = 'indexable';

-- RESULT
-- Returns a list of indexable URLs from the sitemap that have zero internal
-- links pointing to them. Each URL in this output is an orphan page —
-- visible to search engines in the sitemap but unreachable through the
-- site's internal link structure.
-- =============================================================================


-- =============================================================================
-- SECTION 2: TEMPLATE-LEVEL LCP ISSUE DIAGNOSIS
-- =============================================================================
--
-- PROBLEM
-- A client has 40,000 product pages with poor Largest Contentful Paint (LCP)
-- scores. The goal is to determine whether this is a template-level issue
-- (shared across all product pages) or isolated individual page errors.
-- The distinction matters because a template issue requires a single
-- engineering fix — not 40,000 individual page fixes.
--
-- APPROACH
-- If the same template is causing poor LCP, the average LCP score will be
-- consistently high across all pages sharing that template. Random individual
-- issues would produce scattered, inconsistent scores with no clear pattern.
-- Grouping by template_type and filtering with HAVING surfaces only the
-- templates where performance is systematically poor.
-- =============================================================================

-- QUERY 2A: Identify which templates have poor average LCP
SELECT
    template_type,
    AVG(lcp_score) AS avg_lcp_score
FROM
    performance_data
GROUP BY
    template_type
HAVING
    AVG(lcp_score) > 2.5;

-- RESULT
-- Returns each template type alongside its average LCP score, filtered to
-- show only templates exceeding the 2.5 second threshold. A consistently
-- high average across a single template type is evidence of a
-- template-level issue rather than individual page errors.
-- =============================================================================


-- QUERY 2B: Identify the specific resource (JS script) causing poor LCP
--
-- Once a template-level issue is confirmed, the next step is identifying
-- the specific resource responsible. On a shared template, the same
-- JavaScript file will appear on most or all of the slow pages.
-- Counting how frequently each resource URL appears across pages with
-- poor LCP surfaces the most likely culprit.
-- =============================================================================

SELECT
    resource_url,
    COUNT(resource_url) AS pages_affected
FROM
    performance_data
WHERE
    lcp_score > 2.5
GROUP BY
    resource_url
HAVING
    COUNT(resource_url) > 1
ORDER BY
    pages_affected DESC;

-- RESULT
-- Returns a ranked list of resource URLs ordered by how many slow pages
-- they appear on. The resource at the top of this list is the most likely
-- cause of the template-level LCP issue. This gives the engineering team
-- a specific, evidence-backed target to investigate and fix.
-- =============================================================================


-- =============================================================================
-- SECTION 3: NOINDEX CANARY CHECK — AUTOMATED MONITORING
-- =============================================================================
--
-- PROBLEM
-- A developer accidentally pushes a noindex directive to the live site.
-- On a 50,000 page site, this can wipe out organic rankings within days
-- if Google recrawls those pages before the issue is caught. Manual checks
-- are too slow and unreliable at this scale.
--
-- APPROACH
-- Two queries work together as a canary check — an early warning system
-- that can be run on a schedule to detect abnormal noindex counts before
-- they cause ranking damage.
--
-- Query 3A identifies which pages are affected.
-- Query 3B measures the scale as a percentage of the total site.
-- A sudden jump in the percentage (e.g. from 2% to 80%) triggers an alert.
-- =============================================================================

-- QUERY 3A: Identify pages with a noindex directive
SELECT
    COUNT(meta_robots) AS noindex_encountered
FROM
    crawl_data
WHERE
    meta_robots LIKE '%noindex%';

-- RESULT
-- Returns the total number of pages currently carrying a noindex directive.
-- This count becomes the baseline. When scheduled to run daily, a spike
-- in this number signals an accidental deployment that needs immediate attention.
-- =============================================================================


-- QUERY 3B: Calculate the percentage of pages affected by noindex
SELECT
    COUNT(CASE WHEN meta_robots LIKE '%noindex%' THEN 1 END)   AS noindex_count,
    COUNT(*)                                                     AS total_pages,
    COUNT(CASE WHEN meta_robots LIKE '%noindex%' THEN 1 END)
        / COUNT(*) * 100                                         AS noindex_percentage
FROM
    crawl_data;

-- RESULT
-- Returns the raw noindex count, the total page count, and the percentage
-- of the site affected. Monitoring this percentage over time makes accidental
-- mass noindex deployments immediately visible. If the percentage jumps
-- significantly above the established baseline, the deployment should be
-- investigated and rolled back before search engines recrawl the affected pages.
-- =============================================================================
