# Post 4 — Beyond the Sticker Price

Question: How did real new-home prices and mortgage rates change an illustrative buyer's monthly payment, and how did that payment compare with median household income?

## Folder structure

| Location | Purpose |
| --- | --- |
| `index.qmd` | Blog text, dynamically calculated values, and figures |
| `code/analyze.R` | Checks source snapshots, aggregates data, calculates payments and the income benchmark |
| `code/plots.R` | Generates three figures |
| `data/raw/` | Original FRED CSV downloads and Census Table H-5 workbook |
| `data/manifest.csv` | Download URLs, UTC timestamps, and MD5 checksums |
| `data/quarterly.csv` | 40-quarter analysis dataset, 2015 Q1–2024 Q4 |
| `results/scenarios.csv` | Four endpoint price/rate scenarios |
| `results/affordability.csv` | Q4 modeled payment divided by same-year U.S. median household income, 2015–2024 |
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

The calculations and plots use base R; reading the Census workbook also requires `xml2` (`install.packages("xml2")`). A normal run checks source-file checksums, recomputes the cleaned data, four price/rate scenarios, and income comparison, then overwrites the generated results. It does not contact either source when all snapshots are present. Missing snapshots are downloaded. No API key or account is needed.

To intentionally fetch new FRED snapshots, back up existing data first and run from the post4 folder:

```sh
Rscript code/analyze.R --refresh
```

FRED can revise historical values. Refreshing may change the results; do not manually edit raw files to make a checksum pass. The `--refresh` switch applies to the FRED series, not Census Table H-5. To update the income series, obtain a new official H-5 workbook and update its manifest checksum and retrieval date. New FRED downloads are checked for expected column names, valid dates/values, and quarterly coverage. Weekly rates require 12–14 observations per quarter, CPI exactly three months, and new-home prices one observation. The code also checks a known mortgage-payment calculation.

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
- [Census Table H-5](https://www.census.gov/data/tables/time-series/demo/income-poverty/historical-income-households.html): U.S. median household income, annual, **current dollars**, from the "All Races" section. The saved [workbook](data/raw/h05.xlsx) is the October 21, 2026 snapshot. It contains two 2017 rows; the analysis uses the first, footnote-40 row, which the [Census historical footnotes](https://www.census.gov/topics/income-poverty/income/guidance/cps-historic-footnotes.html) identify as the revised-processing series for comparisons with later years.

All series are retrieved through FRED, Federal Reserve Bank of St. Louis, and are not seasonally adjusted. Retrieval times and exact query URLs are saved in the manifest. An initial check of a through-2025 download found October 2025 CPI missing. The final analysis deliberately ends in 2024, the preceding complete calendar year, rather than imputing CPI. Raw snapshots included here cover the final 2015–2024 window.

The loan equals 80% of the price, with 360 monthly installments. If the annual rate in percent is `r`, monthly interest is `r/1200`; payment is `loan * monthly_rate / (1 - (1 + monthly_rate)^(-360))`. Convert dollars using `CPI_2024Q4 / CPI_quarter`. Because the payment formula is linear in price, deflating the payment is equivalent to calculating a payment on the deflated price at the same rate.

Figure 1 plots real prices and rates in separate panels. Figure 2 compares contemporaneous-rate payments with a fixed-2019-Q4-rate scenario at each quarter's price. The four endpoint combinations remain in `results/scenarios.csv`, not a separate figure. Relative to the 2019 Q4 baseline, changing only the real price adds about $66 per month, changing only the rate adds about $580, and changing both adds about $671. The remaining roughly $26 is their interaction, so these are not an additive causal decomposition.

Figure 3 annualizes each **nominal** Q4 modeled payment (`12 × monthly payment`) and divides it by the **nominal** U.S. median household income for the same calendar year. This puts the payment and income in matching dollars without mixing a CPI-adjusted numerator with a current-dollar denominator. The result rises from about 21% in 2019 to 31% in 2024. It is a national comparison benchmark, **not** the actual payment-to-income ratio of new-home buyers.

No personal data, simulated observations, or CPS weights are used. These are published aggregate series and deterministic loan calculations. Payments exclude taxes, insurance, fees, and maintenance; the income comparison does not turn them into a full affordability index or individual financial advice.
