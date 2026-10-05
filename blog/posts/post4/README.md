# Post 4 — Beyond the Sticker Price

Question: How did real new-home prices and mortgage rates jointly change an illustrative buyer's monthly principal-and-interest payment?

## Folder structure

| Location | Purpose |
| --- | --- |
| `index.qmd` | Blog text, dynamically calculated values, and figures |
| `code/analyze.R` | Downloads/caches FRED series, checks inputs, aggregates and transforms data |
| `code/plots.R` | Generates three figures |
| `data/raw/` | Original FRED CSV downloads |
| `data/manifest.csv` | Download URLs, UTC timestamps, and MD5 checksums |
| `data/quarterly.csv` | 40-quarter analysis dataset, 2015 Q1–2024 Q4 |
| `results/scenarios.csv` | Four endpoint price/rate scenarios |
| `results/figures/` | Three PNG figures |
| `results/session-info.txt` | R environment from the last analysis run |

## Reproduce in RStudio

Open the website's RStudio project. In the R console, starting from the project root:

```r
local({
  original_directory <- getwd()
  on.exit(setwd(original_directory))
  setwd("blog/posts/post4")
  source("code/analyze.R")
})
```

Alternatively, from a terminal in `blog/posts/post4/`:

```sh
Rscript code/analyze.R
```

The analysis and plots use only base R. A normal run checks snapshot checksums, recomputes the cleaned data and four scenarios, and overwrites the generated results. It does not contact FRED when all snapshots are present. Missing snapshots are downloaded. No API key or account is needed.

To intentionally fetch a new snapshot from FRED, back up existing data first and run from the post4 folder:

```sh
Rscript code/analyze.R --refresh
```

FRED can revise historical values. Refreshing may change the results; do not manually edit raw files to make a checksum pass. New downloads are checked for expected column names, valid dates/values, and quarterly coverage. Weekly rates require 12–14 observations per quarter, CPI exactly three months, and new-home prices one observation. The code also checks a known mortgage-payment calculation.

## Render

Install Quarto and the R packages `knitr` and `rmarkdown`. In a terminal at the website root:

```sh
quarto render blog/posts/post4/index.qmd
quarto render blog/index.qmd
```

The article is `docs/blog/posts/post4/index.html`. Rendering reruns the analysis using cached inputs. To update the whole website, use `quarto render` from the root. Commit the source, data, results, and generated website changes together before pushing.

## Data definitions and transformations

- [MSPUS](https://fred.stlouisfed.org/series/MSPUS): Census Bureau/HUD median sales price of **new** houses, quarterly, nominal USD. This is not the median of all existing homes or a constant-quality index.
- [MORTGAGE30US](https://fred.stlouisfed.org/series/MORTGAGE30US): Freddie Mac 30-year fixed mortgage benchmark, weekly, annual percent. Compute the arithmetic average of available dated weekly observations in each calendar quarter; these are not daily-weighted averages. Freddie Mac changed its methodology on November 17, 2022. Copyright Freddie Mac; attribution required; see the source's notes and terms.
- [CPIAUCNS](https://fred.stlouisfed.org/series/CPIAUCNS): BLS all-items CPI-U, monthly, index 1982–84=100. Average three months per quarter. Census/HUD and BLS data are public domain with citation requested.

All series are retrieved through FRED, Federal Reserve Bank of St. Louis, and are not seasonally adjusted. Retrieval times and exact query URLs are saved in the manifest. An initial check of a through-2025 download found October 2025 CPI missing. The final analysis deliberately ends in 2024, the preceding complete calendar year, rather than imputing CPI. Raw snapshots included here cover the final 2015–2024 window.

The loan equals 80% of the price, with 360 monthly installments. If the annual rate in percent is `r`, monthly interest is `r/1200`; payment is `loan * monthly_rate / (1 - (1 + monthly_rate)^(-360))`. Convert dollars using `CPI_2024Q4 / CPI_quarter`. Because the payment formula is linear in price, deflating the payment is equivalent to calculating a payment on the deflated price at the same rate.

Figure 1 plots real prices and rates in separate panels. Figure 2 compares contemporaneous-rate payments with a fixed-2019-Q4-rate scenario at each quarter's price. Figure 3 uses 2019 Q4 and 2024 Q4 real prices and rates in all four combinations. Price and rate effects interact; the two individual changes are not an additive causal decomposition.

No personal data, simulated observations, or CPS weights are used. These are published aggregate series and deterministic loan calculations. Estimates exclude taxes, insurance, fees, maintenance, and income; they are not a full affordability index or individual financial advice.
