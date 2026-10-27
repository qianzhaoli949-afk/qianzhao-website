# Blog 7: County population change in Pennsylvania

This post compares changes in population counts and percentages across all 67
Pennsylvania counties. It uses the Census Bureau's Vintage 2024 estimates
base for April 1, 2020 and its July 1, 2024 estimates. The fixed vintage makes
the results comparable with Blog 5; it is not the latest available vintage.

## Files

- `data/pa-counties.csv`: county-level data from `../post5/data/pa-counties.csv`.
- `code/prepare.R`: checks the data and creates `data/counties.js` for the chart.
- `code/chart.js`: Plotly chart and interactive controls.
- `vendor/plotly-basic-2.35.2.min.js`: Plotly.js basic bundle, version 2.35.2,
  from https://cdn.plot.ly/plotly-basic-2.35.2.min.js (MIT license).
- `index.qmd`: article and chart container; rendered output appears in `docs/blog/posts/post7/`.

## Reproduce

Install R, Quarto, and the R package `jsonlite`. The saved CSV and Plotly bundle
allow rendering without downloading data. From the repository root, run:

```sh
cd blog/posts/post7
Rscript code/prepare.R
cd ../../..
quarto render blog/posts/post7/index.qmd
```

Open `docs/blog/posts/post7/index.html` in a JavaScript-enabled browser. To
regenerate the CSV from the original Census data, follow the Blog 5
[README](../post5/README.md), then copy its `data/pa-counties.csv` into this
post's `data/` folder and rerun the commands above. The Census original is
https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/counties/totals/co-est2024-alldata.csv.

Population change equals the 2024 estimate minus the 2020 estimates base;
percent change divides that difference by the 2020 base. These are descriptive
estimates, not direct measures of individual moves or causes of change.
