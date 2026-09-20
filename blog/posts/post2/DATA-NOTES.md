# Blog Post 2: data and reproduction notes

Author: Qianzhao Li. Collected September 19, 2026, America/New_York
(September 20, 2026 UTC; exact times appear in data/manifest.csv).

## Scope and sources

Four purposefully selected quantitative occupations:

| O*NET-SOC | Profile |
| --- | --- |
| 15-2051.00 | https://www.onetonline.org/link/summary/15-2051.00 |
| 15-2031.00 | https://www.onetonline.org/link/summary/15-2031.00 |
| 13-2051.00 | https://www.onetonline.org/link/summary/13-2051.00 |
| 15-2011.00 | https://www.onetonline.org/link/summary/15-2011.00 |

This is not a random sample or an exhaustive ranking. Financial and Investment
Analysts is SOC 13-2051; it excludes Financial Risk Specialists (13-2054).
Original BLS direct-access testing received HTTP 403; collection switched to
O*NET's independently accessible public pages without bypassing that denial.

## Meaning of the fields

- `median_annual_pay_usd`: national occupational median annual wage, in nominal
  USD, from the page's **annual** figure (not its hourly figure). Wage year: 2025.
  Not an entry-level salary, promised offer, or compensation adjusted for location.
- `annual_projected_openings`: average annual openings due to growth and
  replacement in the 2024–2034 projection. Not total openings over ten years,
  current vacancies, net employment change, or graduate-only jobs.
  O*NET's national trends page makes the annual unit explicit:
  https://www.onetonline.org/link/localtrends/15-2051.00
- `growth_category`: the exact category published in the summary. "7% or higher"
  is a threshold, not an observed 7% growth rate. Categories are not precise rankings.
- `employment` / `employment_year`: employment stock and base year shown on page.
- `top_education_response` / `education_response_pct`: the largest displayed
  survey response and its percentage. Not a universal hiring requirement or the
  share of job advertisements. The Financial and Investment Analysts profile
  has no Education response section; these fields are NA for it.
- `education_all_responses`: all displayed education responses, including missing
  values where unavailable. Education survey dates are not assumed to equal 2025.
- `source_url` / `retrieved_utc`: provenance; `manifest.csv` adds HTML filenames and
  MD5 checksums for accidental-change detection.

2025 wage data and 2024–2034 projections are separate reference periods. O*NET
does not necessarily update at the same time as BLS's current OOH pages. The
analysis faithfully uses the vintages shown on the collected O*NET pages.
Source register: https://www.onetonline.org/help/online/datasources

## Ethical collection

Review: https://www.onetonline.org/robots.txt and
https://www.onetonline.org/help/license

At collection time the wildcard robots block does not disallow /link/summary/.
The robots file also contains a separate Jobrapido-specific block; this scraper
identifies itself as StudentCareerResearch, not Jobrapido. The reviewed file is
saved as ROBOTS-REVIEWED.txt. Future online runs halt if robots.txt changes, so a
person must re-review its rules before updating that baseline. Permission to
reuse information is not a blanket exemption from access or traffic restrictions.

Requests are sequential, spaced by four seconds, with a descriptive user agent
and the public project URL as contact. No login, CAPTCHA, paywall, or blocked
endpoint is bypassed. HTTP errors stop the script with no retry. Default offline
runs reparse all four original HTML snapshots with rvest; they do not make requests.

## Files and commands

The reproduction ZIP contains the R scripts, Quarto source, cleaned CSV, original
HTML, manifest, reviewed robots file, chart, and session information. The HTML
snapshots are source evidence, not pages to publish as part of the blog navigation.

Unzip into a folder and set that as R's working directory. Install once:

```r
install.packages(c("rvest", "httr"))
```

Full reproduction commands:

```r
source("scrape-careers.R")
careers <- build_careers("data", refresh = FALSE)
source("plot-careers.R")
plot_careers(careers)
```

Rendering the Quarto page additionally requires Quarto, knitr and rmarkdown.
From the website root, run `quarto render blog/posts/post2/index.qmd`.
To obtain a new snapshot, first re-check the site's access policy, back up the
current data folder, then deliberately use `build_careers("data", refresh = TRUE)`.
An ordinary render does not refresh the snapshot.

## Attribution and transformations

O*NET OnLine is provided by the U.S. Department of Labor, Employment and Training
Administration. Its own content is used under CC BY 4.0:
https://creativecommons.org/licenses/by/4.0/
O*NET is a registered trademark of USDOL/ETA. External wage and projection figures
come from BLS, as identified in O*NET's source register. We do not apply O*NET's
license to third-party material that its license explicitly excludes.

Transformations by Qianzhao Li: selected four profiles; extracted HTML labels and
values; converted annual currency and counts to numbers; retained education
missingness and source growth categories; calculated a ratio; made a comparison
table and scatterplot; added interpretation. USDOL/ETA has not approved, endorsed,
or tested these modifications. The project does not reproduce source-site images.
