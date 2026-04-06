# SEO SQL Audit Query Library

Reusable SQL queries for technical SEO audits 
using Screaming Frog crawl data imported into MySQL.

Built by Khuthadzo — Technical SEO Specialist | 
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

## Author

**Munyai Khuthadzo**
Technical SEO Specialist | SQL + Data-Driven SEO
GitHub: github.com/Munyai-Khuthadzo
