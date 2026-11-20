# Post 11: What Follows an Unexpected Rise in Interest Rates?

This post estimates a Bayesian VAR with a recursively identified interest-rate shock. It uses a fixed FRED data snapshot so that the calculations can be reproduced without a live data connection.

## Files and data

- `index.qmd`: post and figures.
- `data/INDPRO.csv`, `data/CPIAUCSL.csv`, `data/FEDFUNDS.csv`: monthly FRED snapshots downloaded November 9, 2026; the script restricts them to January 1990–December 2019.
- `code/analyze.py`: transformation, Gibbs sampler, diagnostics and impulse responses.
- `results/analysis_data.csv`: transformed observations before lag trimming.
- `results/impulse_responses.csv`: posterior medians and pointwise 95% credible intervals by variable and month.
- `results/summary.json`: sample, sampler settings, selected results and split-R-hat summary.
- `results/impulse_responses.png`, `results/trace.png`: figures in the post.
- `requirements.txt`: tested Python package versions.

Sources: Board of Governors, [industrial production](https://fred.stlouisfed.org/series/INDPRO) and [effective federal funds rate](https://fred.stlouisfed.org/series/FEDFUNDS); Bureau of Labor Statistics, [CPI for All Urban Consumers](https://fred.stlouisfed.org/series/CPIAUCSL), retrieved through FRED. Values are revised, not real-time vintages. The data can be downloaded from FRED's `graph/fredgraph.csv?id=SERIES` endpoint.

## Model and identification

Use 100 times the monthly log changes of INDPRO and CPIAUCSL and the untransformed FEDFUNDS rate. With two lags, 357 observations remain. The recursive ordering is production growth, inflation, rate: the first two variables do not respond to the rate shock within the same month, while the rate can respond to both immediately. Each posterior draw uses a Cholesky factor and rescales the shock to raise the rate by 0.25 percentage points on impact. Responses for growth and inflation are changes in monthly rates, not cumulative levels. The intervals are pointwise, not joint.

For Y = XB + U with U ~ N(0, Sigma), use B conditional on Sigma ~ MatrixNormal(B0, V0, Sigma), with B0 zero and V0 diagonal (10 for intercept, 0.25 for each lag); Sigma ~ inverse-Wishart(df=5, scale=0.5 I). Four Gibbs chains alternate conditional draws of Sigma and B, using seeds 1100–1103, 1,000 warmup draws and 3,000 retained draws each. The sampler computes classical split-R-hat for all 21 coefficients and six distinct covariance entries. The trace plot shows the first lag of production growth in the production equation. Diagnostics cannot establish the validity of the prior or identifying restrictions; the prior is not tested for sensitivity here.

## Reproduce

Use Python 3.12. From this directory:

```sh
python3 -m pip install -r requirements.txt
python3 code/analyze.py
```

The script overwrites the files in `results/`. It reads the saved data snapshot and does not download new revisions. From the website repository root, render with `quarto render blog/posts/post11/index.qmd`. Minor numerical differences across platforms may occur.
