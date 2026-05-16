# SEO SQL Audit Query Library

Reusable SQL queries for technical SEO audits 
using Screaming Frog crawl data imported into MySQL.

Built by Munyai Khuthadzo — Technical SEO Specialist | 
SQL + SEO Data Pipeline

---

## What This Is

Most SEO audits are done manually — checking pages 
one by one. This query library automates that process 
by importing Screaming Frog crawl data into MySQL and 
running structured queries that find issues across 
thousands of pages in seconds.

---

## What's Inside

| Section | Queries | Purpose |
|---|---|---|
| Database Setup | 2 | Create database and table |
| Verification | 3 | Confirm data imported correctly |
| On-Page SEO | 5 | Meta, H1, titles, thin content |
| Technical SEO | 4 | Canonicals, redirects, orphans |
| Crawl Budget | 2 | Quantify waste as percentage |
| Master Overview | 1 | Full audit snapshot |

---
## How To Use

**Step 1 — Crawl your target website**
Use Screaming Frog SEO Spider (free up to 500 URLs)

**Step 2 — Export crawl data**
Export the Internal tab as CSV

**Step 3 — Set up the database**
Run the setup queries in Section 1

**Step 4 — Import your CSV**
Use MySQL Workbench Table Data Import Wizard

**Step 5 — Run audit queries**
Run any queries from Sections 3-6

**Step 6 — Document findings**
Use results to build your professional audit report

---

## Issues These Queries Find

- Missing meta descriptions
- Missing H1 tags across entire site
- Short or weak title tags
- Duplicate H2 tags across pages
- Thin content pages under 300 words
- Slow server response times
- Canonical tag mismatches (including WWW vs non-WWW)
- Non-indexable pages
- Redirect chains
- WordPress system files being crawled
- Orphaned pages with no internal links
- Deep pages buried in site structure
- Crawl budget waste percentage
- Poor internal linking structure

---

## Real Results

Applied to mtgfunerals.co.za (Venda, Limpopo):

- 105 URLs crawled
- 18 total issues found
- 3 issues discovered by SQL only — invisible to manual audit
- WWW vs non-WWW canonical mismatch caught automatically
- WordPress system files crawl waste identified

---

## Requirements

- MySQL 5.7+ or MariaDB 10.3+
- MySQL Workbench (free)
- Screaming Frog SEO Spider (free up to 500 URLs)

---

## Enterprise Audit Queries (seo_audit_library.sql)
Audit queries designed for high-volume websites (50,000+ pages) covering orphan page detection,
template-level performance diagnosis and automated noindex monitoring.

### 1. Orphan Page Detection
Identifies indexable URLs that exist in the sitemap but have zero internal links pointing to them.

### 2. Template-Level LCP Diagnosis
Proves whether poor Largest Contentful Paint scores are a template-level issue or individual page errors, and identifies the specific resource causing the problem.

### 3. Noindex Canary Check
Monitors the percentage of pages carrying a noindex directive to detect accidental deployments before they impact organic rankings.

## Ahrefs Data-Cleaning Pipeline

The data-cleaning workflow standardizes, refines, and deduplicates raw SEO data exported from Ahrefs to ensure it is structured correctly for accurate analytics and reporting.
The pipeline addresses critical data integrity issues through the following strategic steps:

### Intelligent Deduplication:
Identifies and isolates unique keyword records across matching dimensions (Keyword, Country, Intent, Device), systematically keeping the records with the most complete metrics while eliminating redundant rows.

### Case Uniformity: 
Normalizes all text and URL inputs to lowercase, preventing reporting tools from fragmenting data due to mismatched capitalization (e.g., treating "SEO" and "seo" as distinct categories).

### Type Standardization & Value Cleansing:
Strips out uncalculable text strings (such as "unknown", "high", "N/A", and "missing") and hidden spaces from numeric metrics. By converting these to proper SQL NULL values, the dataset is cleared of corrupting elements, enabling error-free mathematical aggregations like averages, sums, and distributions.

### Time-Series Normalization:
Transforms non-standard string dates into standard SQL format, a required step for accurate chronological sorting, date-range filtering, and trend forecasting. Business & Analytical Value By executing this workflow, the dataset shifts from an unreliable raw export to a pristine, production-ready table. This guarantees that any downstream dashboards, performance tracking tools, or ROI calculations are built on uniform, accurate, and structurally sound data.

## Author

**Munyai Khuthadzo**
Technical SEO Specialist | SQL + Data-Driven SEO
GitHub: github.com/Munyai-Khuthadzo
