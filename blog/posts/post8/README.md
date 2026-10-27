# Blog 8: Bootstrap intervals and hypothesis testing

This post uses invented weekly grocery spending to explain inference. It does
not use real survey data. The population is normal with mean $50 and standard
deviation $10; the null simulation assumes the same known standard deviation.

## Files

- `code/simulate.R`: draws samples and resamples, calculates percentile
  intervals and coverage, and simulates the null distribution.
- `data/simulations.rds` and `data/simulations.js`: reproducible saved results.
- `code/charts.js`: Plotly charts and sample-size control.
- `vendor/plotly-basic-2.35.2.min.js`: Plotly.js 2.35.2, MIT-licensed;
  downloaded from https://cdn.plot.ly/plotly-basic-2.35.2.min.js.
- `index.qmd`: article; its rendered page is under `docs/blog/posts/post8/`.

## Reproduce

Install R, Quarto, and the R package `jsonlite`. From the repository root:

```sh
cd blog/posts/post8
Rscript code/simulate.R
cd ../../..
quarto render blog/posts/post8/index.qmd
```

The script uses seed 20261027 and sample sizes 20, 50, and 100. For each
size, it draws one sample and 500 bootstrap resamples, then constructs 1,000
percentile bootstrap intervals using 500 resamples each. It saves the first
100 intervals for display and the coverage count for all 1,000. It also draws
5,000 means under the null. The simulated 95th percentile of absolute
deviations defines the two-sided rejection cutoff; the p-value is the
fraction of absolute null deviations at least as large as the observed one.
The visualizations use precomputed results; changing the menu does not draw
new samples. Small differences can arise across R versions or random seeds.
