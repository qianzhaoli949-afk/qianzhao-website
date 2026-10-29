"""Build a fixed CSV snapshot from downloaded Yahoo-derived parquet files.

Usage: python code/prepare_data.py /path/to/stock-parquets /path/to/daily_prices.parquet
"""
from pathlib import Path
import sys
import pandas as pd

source, spy_path = Path(sys.argv[1]), Path(sys.argv[2])
frames = []
for path in sorted(source.glob('*.parquet')):
    d = pd.read_parquet(path)
    d = d[(d.date >= '2022-01-01') & (d.date <= '2026-06-30')].copy()
    d['symbol'] = path.stem
    frames.append(d)
prices = pd.concat(frames, ignore_index=True)
spy = pd.read_parquet(spy_path, columns=['SPY']).reset_index()
spy.columns = ['date', 'spy_adjusted']
spy = spy[(spy.date >= '2022-01-01') & (spy.date <= '2026-06-30')].dropna(subset=['spy_adjusted'])
prices.to_csv('data/stock_prices.csv.gz', index=False, compression='gzip', float_format='%.8f')
spy.to_csv('data/spy.csv', index=False, float_format='%.8f')
print('Stock symbols:', prices.symbol.nunique(), 'rows:', len(prices), 'SPY rows:', len(spy))
