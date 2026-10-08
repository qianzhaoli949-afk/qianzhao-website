# Post 2 — Choosing a Quantitative Career

**Question:** How do pay, projected growth, and openings relative to market size compare across four quantitative careers?

[Read the post](https://qianzhaoli949-afk.github.io/qianzhao-website/blog/posts/post2/index.html) · [Repository guide](../../../README.md)

## Code, data, and results

| Component | Location and purpose |
| --- | --- |
| Article | [index.qmd](index.qmd) |
| Collection and cleaning | [scrape-careers.R](scrape-careers.R) |
| Visualization | [plot-careers.R](plot-careers.R) |
| Growth and market-size analysis | [analyze-careers.R](analyze-careers.R); output [data/career-analysis.csv](data/career-analysis.csv) |
| Source data | [data/raw/](data/raw/): four saved O\*NET HTML profiles |
| Cleaned data | [data/careers.csv](data/careers.csv) |
| Provenance | [data/manifest.csv](data/manifest.csv): retrieval times and checksums |
| Access-policy record | [ROBOTS-REVIEWED.txt](ROBOTS-REVIEWED.txt) and [data/robots.txt](data/robots.txt) |
| Results | [Pay/openings figure](figures/career-comparison.png), [growth/openings figure](figures/growth-openings.png), and comparison tables |
| Detailed methods | [DATA-NOTES.md](DATA-NOTES.md) |
| Software environment | [session-info.txt](session-info.txt) |

The profiles cover data scientists, operations research analysts, financial and investment analysts, and actuaries. Their saved figures use 2025 wages and 2024–2034 projections. Annual openings are not current vacancies, and median wages are not starting salaries.

## Reproduce from saved data

Install R; install Quarto if rendering the article. In the R console:

```r
install.packages(c("rvest", "httr", "knitr", "rmarkdown"))
```

With R's working directory set to `blog/posts/post2/`, run:

```r
source("scrape-careers.R")
careers <- build_careers("data", refresh = FALSE)
stopifnot(nrow(careers) == 4)
source("plot-careers.R")
plot_careers(careers)
source("analyze-careers.R")
analysis <- analyze_careers(careers)
write.csv(analysis, "data/career-analysis.csv", row.names=FALSE)
plot_growth(analysis)
```

This reparses the saved HTML, checks snapshot checksums, rewrites `data/careers.csv`, and displays the plot. With the included snapshots present, no web requests are made. Reproducing the original snapshot should give 23,400 annual openings for data scientists and 2,400 for actuaries.

To save the figure and regenerate the article, run from a terminal in the repository root:

```sh
quarto render blog/posts/post2/index.qmd
```

The article's R chunks write both PNG figures and `data/career-analysis.csv`. The rendered page is `docs/blog/posts/post2/index.html`.

## Interpreting growth and market size

Growth remains categorical: three careers have projected 2024–2034 net growth of 7% or higher; financial and investment analysis has 5% to 6%. These are ten-year categories, not annual rates, and do not rank occupations within a category. The additional measure is `100 * annual_projected_openings / employment`: projected annual openings per 100 jobs in the 2024 base year. It includes growth and replacement needs, not just net growth. Expected rounded results are data science 9.5, operations research 8.6, actuarial work 7.1, and financial analysis 6.8. It is not a hiring probability or vacancy rate. The analysis also compares rankings before and after this size adjustment.

## Collect a fresh snapshot

Refreshing is optional and may change the results. Back up the current data first, review the site's current access rules and terms, and follow [DATA-NOTES.md](DATA-NOTES.md) before using `build_careers("data", refresh = TRUE)`. Requests are spaced four seconds apart; HTTP errors or a changed robots policy stop collection. Do not bypass access restrictions.

## Attribution

O\*NET OnLine is provided by the U.S. Department of Labor, Employment and Training Administration. Wage and employment projections are attributed to BLS. Source URLs, transformations, and applicable reuse terms are documented in [DATA-NOTES.md](DATA-NOTES.md).
