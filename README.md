# Qianzhao Li — Personal Website & Economics Blog

A Quarto website featuring my profile, résumé, and coursework in economics and data analysis. The blog combines economic intuition, reproducible R code, and data visualization.

**[Visit the website](https://qianzhaoli949-afk.github.io/qianzhao-website/)** · **[Read the blog](https://qianzhaoli949-afk.github.io/qianzhao-website/blog/)** · **[View my résumé](https://qianzhaoli949-afk.github.io/qianzhao-website/resume.html)**

## Blog projects

| Post | Question and approach | Source code |
| --- | --- | --- |
| [1. Why More Income Can Mean Less Instant Noodles](https://qianzhaoli949-afk.github.io/qianzhao-website/blog/posts/post1/Untitled.html) | Explains inferior goods using a hypothetical example and an R plot. | [Post 1](blog/posts/post1/Untitled.qmd) |
| [2. Beyond the Highest Salary: Choosing a Quantitative Career](https://qianzhaoli949-afk.github.io/qianzhao-website/blog/posts/post2/index.html) | Uses `rvest` to collect four O\*NET occupation profiles and compare pay and projected job openings. | [Post 2](blog/posts/post2/) |
| [3. Education and Unemployment: Unequal Shocks, Uneven Recovery](https://qianzhaoli949-afk.github.io/qianzhao-website/blog/posts/post3/index.html) | Uses weighted IPUMS CPS microdata and three visualizations to examine unemployment by education, 2019–2024. | [Post 3](blog/posts/post3/) |
| [4. Beyond the Sticker Price: The Cost of Financing a New Home](https://qianzhaoli949-afk.github.io/qianzhao-website/blog/posts/post4/index.html) | Combines FRED prices, rates, and CPI to compare real mortgage payments with three visualizations, 2015–2024. | [Post 4](blog/posts/post4/) |

## Run locally

Post 4, [Beyond the Sticker Price](blog/posts/post4/index.qmd), uses new-home prices, mortgage rates, and CPI from FRED to compare inflation-adjusted mortgage payments. Its [replication guide](blog/posts/post4/README.md) documents the `code/`, `data/`, and `results/` folders and all assumptions.

Each post has a dedicated guide mapping its code, data, and results and explaining how to reproduce them:

- [Post 1 replication guide](blog/posts/post1/README.md)
- [Post 2 replication guide](blog/posts/post2/README.md)
- [Post 3 replication guide](blog/posts/post3/README.md)
- [Post 4 replication guide](blog/posts/post4/README.md)

You will need [R](https://www.r-project.org/) and [Quarto](https://quarto.org/). RStudio is optional.

1. Clone this repository and open its folder:

   ```sh
   git clone https://github.com/qianzhaoli949-afk/qianzhao-website.git
   cd qianzhao-website
   ```

2. Install the R packages once, from the R console:

   ```r
   install.packages(c("knitr", "rmarkdown", "rvest", "httr", "xml2"))
   ```

3. Preview the website from a terminal in the repository root:

   ```sh
   quarto preview
   ```

   To generate the website files without starting a preview:

   ```sh
   quarto render
   ```

The output is written to `docs/`, as configured in `_quarto.yml`. Ordinary rendering uses the saved O\*NET snapshots, CPS grouped summaries, and FRED downloads; it does not require a new web scrape or access to CPS microdata.

## Reproduce the analyses

### Post 1: Inferior goods

The R code is included directly in [Untitled.qmd](blog/posts/post1/Untitled.qmd). Its six observations are hypothetical teaching data, not survey estimates. Rendering the post regenerates the figure.

### Post 2: Career comparison

From `blog/posts/post2/`, run in R:

```r
source("scrape-careers.R")
careers <- build_careers("data", refresh = FALSE)
source("plot-careers.R")
plot_careers(careers)
source("analyze-careers.R")
analysis <- analyze_careers(careers)
write.csv(analysis, "data/career-analysis.csv", row.names=FALSE)
plot_growth(analysis)
```

The default reuses saved HTML snapshots. The folder includes cleaned data, retrieval timestamps, checksums, and source documentation. Online collection is rate-limited and stops if the reviewed robots policy changes. See [data and reproduction notes](blog/posts/post2/DATA-NOTES.md) for definitions, attribution, and refresh instructions.

### Post 3: Education and unemployment

To redraw the figures from the included grouped summaries, run in R from `blog/posts/post3/`:

```r
source("plots.R")
draw_figures(readRDS("summary.rds"))
```

To reproduce the summaries from microdata, obtain your own authorized IPUMS CPS extract following [REPRODUCE.txt](blog/posts/post3/REPRODUCE.txt). Then run from that same folder in a terminal, replacing the example paths:

```sh
Rscript analyze.R /path/to/cps_00001.xml /path/to/cps_00001.dat.gz
```

This regenerates `summary.rds` and `session-info.txt`. The analysis covers adults ages 25–64 in all 72 Basic Monthly samples from 2019 through 2024. Estimates use `WTFINL`, and the unemployment-rate denominator is the civilian labor force. Results are descriptive and not seasonally adjusted; they do not establish a causal effect of education. The reader uses base R and `xml2`; `ipumsr` is not required by this script.

**CPS microdata and their DDI files are not included.** Keep licensed extracts outside the website directory. The `.gitignore` rules also exclude files named `cps_*.dat`, `cps_*.dat.gz`, and `cps_*.xml`. Public outputs contain grouped summaries rather than individual records.

## Repository layout

```text
_quarto.yml          Website configuration
index.qmd            Homepage
bio.qmd              Biography
resume.qmd           Résumé
blog/index.qmd       Blog listing
blog/posts/post1/    Inferior-goods explanation
blog/posts/post2/    Web-scraping analysis and saved source snapshots
blog/posts/post3/    CPS analysis, grouped summaries, and figures
blog/posts/post4/    FRED housing analysis: code, data, results, and replication guide
images/              Website images
styles.css           Custom styling
docs/                Rendered website for GitHub Pages
```

## Updating the website

Edit the source files, run `quarto render`, inspect the results, and commit the relevant source files together with the updated `docs/` output. Push the commit to GitHub to publish through the repository's GitHub Pages configuration. Local edits in RStudio do not automatically upload to GitHub. Edit `.qmd` sources rather than generated HTML files.

## Sources and data use

- **Post 4:** Census Bureau/HUD new-home sales prices, Freddie Mac mortgage rates, and BLS CPI retrieved through FRED. See the post's README and download manifest for definitions, attribution, dates, and transformations.

- **Post 1:** hypothetical data defined in the article.
- **Post 2:** O\*NET OnLine, U.S. Department of Labor, Employment and Training Administration; wage and projection figures attributed to the Bureau of Labor Statistics. Detailed source links and reuse information are provided with the post.
- **Post 3:** IPUMS CPS, University of Minnesota, using underlying U.S. Census Bureau and Bureau of Labor Statistics data. See [IPUMS citation guidance](https://cps.ipums.org/cps/citation.shtml) and comply with the applicable data-use agreement.

Third-party data and images remain subject to their respective terms; inclusion in this repository does not grant additional reuse rights.

## Contact

[Email](mailto:liqianz@sas.upenn.edu) · [GitHub](https://github.com/qianzhaoli949-afk) · [LinkedIn](https://www.linkedin.com/in/qianzhao-li-53bb9529a)
