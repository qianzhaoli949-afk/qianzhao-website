# Post 3 — Education and Unemployment

**Question:** How did unemployment vary by education before, during, and after the pandemic among U.S. adults ages 25–64?

[Read the post](https://qianzhaoli949-afk.github.io/qianzhao-website/blog/posts/post3/index.html) · [Repository guide](../../../README.md)

## Code, data, and results

| Component | Location and purpose |
| --- | --- |
| Article | [index.qmd](index.qmd) |
| Data processing | [analyze.R](analyze.R): reads a local licensed extract and calculates weighted summaries |
| Visualization | [plots.R](plots.R): generates all three figures |
| Public data | [summary.rds](summary.rds): grouped totals, rates, exclusion counts, and input checksums; no individual records |
| Private inputs | An authorized `.dat.gz` extract and its `.xml` DDI, stored outside this repository |
| Results | [figures/](figures/): `monthly.png`, `annual.png`, and `age.png` |
| Detailed methods | [REPRODUCE.txt](REPRODUCE.txt): sample selections, variable codes, formulas, and checks |
| Software environment | [session-info.txt](session-info.txt) |

## Option A: Recreate figures from the included summaries

This route needs R but no IPUMS account or microdata. Set R's working directory to `blog/posts/post3/`, then run:

```r
s <- readRDS("summary.rds")
source("plots.R")
draw_figures(s)
```

The script writes or replaces the three PNG files in `figures/`. It uses base R. This reproduces the visuals from saved results; it does not rerun the microdata analysis.

## Option B: Reproduce the analysis from microdata

1. Register for authorized access at [IPUMS CPS](https://cps.ipums.org/). Choose **Cross-sectional → Basic Monthly** and all months from January 2019 through December 2024 (72 samples). Do not include ASEC samples.
2. Include `AGE`, `EMPSTAT`, `EDUC`, `WTFINL`, `YEAR`, and `MONTH`. Keep the automatically selected technical variables. Select ages **25–64 inclusive**, retaining only individuals who meet that condition.
3. Choose rectangular, fixed-width `.dat` output. Download both the compressed data and DDI `.xml`. Keep them outside the website folder and do not publicly redistribute them.
4. Install the analysis dependency in R:

   ```r
   install.packages("xml2")
   ```

5. In a terminal with `blog/posts/post3/` as the working directory, replace the paths and run:

   ```sh
   Rscript analyze.R /path/to/cps_00001.xml /path/to/cps_00001.dat.gz
   ```

   This overwrites `summary.rds` and `session-info.txt`. The script reads field positions and implied decimals from the DDI; `ipumsr` is not required. Repeat Option A to regenerate the figures.

The original extract was created September 27, 2026. It contained 3,856,411 person-month records; 20,453 nonpositive-weight records were excluded, leaving 3,835,958. Updated IPUMS releases may produce different results. The script checks sample accounting, valid codes, rate bounds, and complete month/education coverage.

## Render the article

Install Quarto and, in R, `install.packages(c("knitr", "rmarkdown"))`. From a terminal in the repository root:

```sh
quarto render blog/posts/post3/index.qmd
```

Open `docs/blog/posts/post3/index.html`. Rendering uses `summary.rds` and redraws the figures; it does not reread private microdata.

## Methods and data use

Estimates use the monthly person weight `WTFINL`. Unemployment rates divide weighted unemployed people by the weighted civilian labor force, not all adults. Annual rates are ratios of summed monthly weighted counts. Repeated respondents are person-month observations, not distinct individuals. Results are not seasonally adjusted and do not establish causality; no statistical significance is claimed. Full coding and validation details are in [REPRODUCE.txt](REPRODUCE.txt).

Source: IPUMS CPS, University of Minnesota, using underlying U.S. Census Bureau and Bureau of Labor Statistics data. Follow [IPUMS citation guidance](https://cps.ipums.org/cps/citation.shtml) and the data-use agreement. The repository intentionally excludes individual-level CPS extracts and their DDI files; obtain your own authorized copy for full replication.
