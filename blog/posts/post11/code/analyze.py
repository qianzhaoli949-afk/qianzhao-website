"""Estimate a three-variable Bayesian VAR and recursively identify a rate shock."""
from pathlib import Path
import json
import numpy as np
import pandas as pd
from scipy.stats import invwishart
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'results'
OUT.mkdir(exist_ok=True)
series = []
for name in ['INDPRO', 'CPIAUCSL', 'FEDFUNDS']:
    data = pd.read_csv(ROOT / 'data' / f'{name}.csv', parse_dates=['observation_date'])
    series.append(data.set_index('observation_date')[[name]])
raw = pd.concat(series, axis=1).loc['1990-01-01':'2019-12-01'].apply(pd.to_numeric, errors='coerce')
assert len(raw) == 360 and raw.notna().all().all() and (raw[['INDPRO', 'CPIAUCSL']] > 0).all().all()
z = pd.DataFrame({'production_growth': 100*np.log(raw.INDPRO).diff(),
                  'inflation': 100*np.log(raw.CPIAUCSL).diff(),
                  'funds_rate': raw.FEDFUNDS}).dropna()
lags = 2
Y = z.iloc[lags:].to_numpy()
X = np.column_stack([np.ones(len(Y))] + [z.shift(j).iloc[lags:].to_numpy() for j in range(1, lags+1)])
n, k = X.shape
m = Y.shape[1]

# Conjugate matrix-normal/inverse-Wishart prior. Columns of B are equations.
B0 = np.zeros((k, m))
V0 = np.diag([10.0] + [0.25]*(k-1))
V0inv = np.linalg.inv(V0)
S0 = np.diag([0.5, 0.5, 0.5])
nu0 = 5
V = np.linalg.inv(V0inv + X.T @ X)
M = V @ (V0inv @ B0 + X.T @ Y)
LV = np.linalg.cholesky(V)

def irf(B, sigma, horizon=24):
    # The last column is a positive rate shock, scaled to +0.25 percentage points.
    impact = np.linalg.cholesky(sigma)[:, 2]
    impact *= 0.25 / impact[2]
    out = np.zeros((horizon+1, m)); out[0] = impact
    for h in range(1, horizon+1):
        for j in range(1, min(lags, h)+1):
            A = B[1+(j-1)*m:1+j*m, :].T
            out[h] += A @ out[h-j]
    return out

def split_rhat(chains):
    # Classical split-Rhat, computed for each column.
    c, length, p = chains.shape
    halves = np.concatenate((chains[:, :length//2], chains[:, length//2:]), axis=0)
    N = halves.shape[1]
    within = halves.var(axis=1, ddof=1).mean(axis=0)
    between = N * halves.mean(axis=1).var(axis=0, ddof=1)
    return np.sqrt(((N-1)/N*within + between/N)/within)

all_draws, all_irfs = [], []
burn, kept = 1000, 3000
for chain in range(4):
    rng = np.random.default_rng(1100+chain)
    B = M.copy() + rng.normal(0, 0.1, (k, m))
    sigma = np.eye(m) * (0.5 + chain)
    draws, responses = [], []
    for i in range(burn+kept):
        residual = Y-X@B
        delta = B-B0
        scale = S0 + residual.T@residual + delta.T@V0inv@delta
        sigma = invwishart.rvs(df=nu0+n+k, scale=scale, random_state=rng)
        B = M + LV @ rng.normal(size=(k,m)) @ np.linalg.cholesky(sigma).T
        if i >= burn:
            draws.append(np.r_[B.ravel(), sigma[np.tril_indices(m)]])
            responses.append(irf(B, sigma))
    all_draws.append(draws); all_irfs.append(responses)
draws = np.array(all_draws); responses = np.array(all_irfs)
rhats = split_rhat(draws)
flat = responses.reshape(-1, 25, 3)
quantiles = np.quantile(flat, [0.025, 0.5, 0.975], axis=0)
rows = []
for h in range(25):
    for j, name in enumerate(z.columns):
        rows.append({'month':h, 'variable':name, 'lower':quantiles[0,h,j],
                     'median':quantiles[1,h,j], 'upper':quantiles[2,h,j]})
pd.DataFrame(rows).to_csv(OUT/'impulse_responses.csv', index=False)
z.to_csv(OUT/'analysis_data.csv')
summary = {'sample': '1990-02 to 2019-12 before two lags', 'observations':n,
           'chains':4, 'burn_in_per_chain':burn, 'draws_per_chain':kept,
           'max_split_rhat':float(rhats.max()), 'min_split_rhat':float(rhats.min()),
           'rhat_above_1_01':int((rhats>1.01).sum()), 'shock_rate_pp':0.25,
           'irf_median_month_12':quantiles[1,12,:].tolist(),
           'irf_95_month_12_low':quantiles[0,12,:].tolist(),
           'irf_95_month_12_high':quantiles[2,12,:].tolist()}
(OUT/'summary.json').write_text(json.dumps(summary, indent=2))
print(json.dumps(summary, indent=2))

plt.rcParams.update({'font.size':10, 'axes.spines.top':False, 'axes.spines.right':False})
fig, axs = plt.subplots(1, 3, figsize=(12, 3.8), sharex=True)
titles = ['Industrial production growth', 'Monthly inflation', 'Federal funds rate']
for j, ax in enumerate(axs):
    ax.fill_between(np.arange(25), quantiles[0,:,j], quantiles[2,:,j], color='#91b9b1', alpha=.45, label='95% credible interval')
    ax.plot(quantiles[1,:,j], color='#276c65', lw=2, label='Posterior median')
    ax.axhline(0, color='gray', lw=.8); ax.set_title(titles[j]); ax.set_xlabel('Months after shock')
    ax.set_ylabel('Percentage points')
axs[0].legend(frameon=False, fontsize=8, loc='best')
fig.suptitle('Responses to a 0.25 percentage-point rate shock', y=1.02)
fig.tight_layout(); fig.savefig(OUT/'impulse_responses.png', dpi=170, bbox_inches='tight'); plt.close(fig)
fig, ax = plt.subplots(figsize=(9,3))
for c in range(4): ax.plot(draws[c,:,3], lw=.45, alpha=.7, label=f'Chain {c+1}')
ax.set(xlabel='Post-warmup draw', ylabel='Coefficient', title='Trace: lagged production growth in its own equation')
ax.legend(ncol=4, fontsize=8, frameon=False); fig.tight_layout(); fig.savefig(OUT/'trace.png', dpi=150); plt.close(fig)
