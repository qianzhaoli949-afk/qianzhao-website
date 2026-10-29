# Blog 9: Revisiting the classroom stock-return model

This post compares a classroom-style XGBoost model, a modified XGBoost model,
and a zero-return prediction benchmark. It also compares hypothetical model
portfolios against SPY over matching holding windows. These are historical
simulations and do not establish future investment performance.

## Files and data

- `code/analyze.py`: features, time splits, validation, models, predictions,
  hypothetical portfolio calculations, and figures.
- `data/stock_prices.csv.gz`: saved 2022–June 2026 daily OHLCV and adjusted
  prices for the 95 tickers listed in the classroom R script. The data come
  from [AmirTrader/YahooFinance](https://huggingface.co/datasets/AmirTrader/YahooFinance),
  revision `59e236cb942b89e5de1a043fa2c849fe3b9a91ed`, obtained October 28,
  2026. The provider describes the data as Yahoo Finance via yfinance and
  lists an MIT license for the dataset repository.
- `data/spy.csv`: adjusted SPY prices from [HerdingAI/stock-price-returns](https://github.com/HerdingAI/stock-price-returns),
  revision `330ab252dfd3c620520a4e425690dc1a5bb9a3f9`, which describes the
  data as Yahoo Finance via yfinance. Holiday rows with missing prices are
  removed. The analysis keeps the common period ending June 30, 2026.
- `code/prepare_data.py`: constructs the snapshots from the 95 individual
  stock parquet files and the archive's `daily_prices.parquet`; requires
  `pyarrow`. The saved CSV files are sufficient to rerun the analysis.
- `results/`: predictions, 31 portfolio holding windows, summary, and figures.
- `requirements.txt`: versions of the analysis packages used for this run.
- `index.qmd`: article; `docs/blog/posts/post9/` contains the rendered page.

## Reproduce the analysis

Install Python 3.12 and the packages in `requirements.txt`, including
`scikit-learn` for XGBoost's Python estimator. On macOS XGBoost
may require the OpenMP runtime; follow the package's installation instructions.
From the repository root:

```sh
cd blog/posts/post9
python3 -m pip install -r requirements.txt
python3 code/analyze.py
cd ../../..
quarto render blog/posts/post9/index.qmd
```

The run uses XGBoost's histogram algorithm and a fixed seed of 123. Small
differences across library versions or platforms are possible. Inputs are
saved locally so the ordinary analysis does not redownload data.

The classroom-style model uses 300 trees, depth 5, learning rate 0.05,
minimum child weight 10, and the classroom feature formulas. Python XGBoost,
the data snapshots, and a purged split differ from the original R script;
the comparison is a reconstruction, not a byte-identical rerun. The modified
model chooses among three specified settings on 2023 data, then refits before
testing 2024–2026. Training outcomes must end before the next period begins.

The model selects ten stocks at the signal close, enters at the following
close, and exits at the close 20 trading days after the signal. Signals occur
every 20 trading days; the portfolio is out of the market between exit and
the next entry. SPY uses exactly the same entry and exit dates and no ETF
trading costs. For each holding period, the portfolio buys all positions and
sells them all at the end. It pays 0.1% of the amount traded on each side,
including the first purchase and final sale. The net growth factor is
`(1 - 0.001) * (1 + gross return) * (1 - 0.001)`; the sale fee applies to
sale proceeds. `trading_cost` in `results/backtest.csv` is the difference
between the gross and net return, relative to wealth before the purchase.
The dataset uses a fixed list of surviving large companies, and price
adjustments and data revisions may incorporate later corporate actions.
