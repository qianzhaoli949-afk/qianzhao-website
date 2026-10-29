"""Time-ordered comparison of classroom-inspired XGBoost models."""
import json
import numpy as np
import pandas as pd
from xgboost import XGBRegressor
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.dates as mdates
from pathlib import Path

Path('results').mkdir(exist_ok=True)
prices = pd.read_csv('data/stock_prices.csv.gz', parse_dates=['date']).sort_values(['symbol','date'])
spy = pd.read_csv('data/spy.csv', parse_dates=['date']).dropna(subset=['spy_adjusted']).sort_values('date')
spy['spy_ret'] = spy.spy_adjusted.pct_change(fill_method=None)
d = prices.merge(spy[['date','spy_ret','spy_adjusted']], on='date', how='inner', validate='many_to_one')
g = d.groupby('symbol', sort=False)
d['ret'] = g.adj_close.pct_change(fill_method=None)
for n in [5,21,63,126]:
    d[f'old_{n}'] = g.adj_close.shift(n) / g.adj_close.shift(1) - 1
    d[f'momentum_{n}'] = g.adj_close.shift(1) / g.adj_close.shift(n) - 1
d['vol'] = d.groupby('symbol',sort=False).ret.transform(lambda x: x.shift(1).rolling(22).std())
d['excess'] = d.ret-d.spy_ret
d['target'] = g.adj_close.shift(-20)/g.adj_close.shift(-1)-1
d['entry_date'] = g.date.shift(-1)
d['target_end'] = g.date.shift(-20)
base = ['open','high','low','close','adj_close','volume','ret','spy_ret','old_21','old_63','old_126','vol','old_5','excess']
improved = ['ret','spy_ret','momentum_5','momentum_21','momentum_63','momentum_126','vol','excess']
d = d.dropna(subset=base+improved+['target','entry_date','target_end']).copy()
assert not d.duplicated(['date','symbol']).any()
assert d.symbol.nunique() >= 80
train = d[(d.date < '2024-01-01') & (d.target_end < '2024-01-01')]
test = d[d.date >= '2024-01-01'].copy()
fit_train = d[(d.date < '2023-01-01') & (d.target_end < '2023-01-01')]
validate = d[(d.date >= '2023-01-01') & (d.target_end < '2024-01-01')]
assert train.target_end.max() < test.date.min()
assert fit_train.target_end.max() < validate.date.min()

def model(depth, trees, rate, minimum):
    return XGBRegressor(n_estimators=trees, max_depth=depth, learning_rate=rate,
                        min_child_weight=minimum, objective='reg:squarederror',
                        random_state=123, n_jobs=4, tree_method='hist')

# The R classroom code uses these hyperparameters, including reversed momentum.
# Python XGBoost and a purged split are an adaptation, not a byte-for-byte rerun.
original = model(5,300,.05,10)
original.fit(train[base], train.target)
test['original'] = original.predict(test[base])

choices = [(2,150,.03,30), (2,300,.03,30), (3,150,.03,30)]
validation = []
for choice in choices:
    fitted = model(*choice)
    fitted.fit(fit_train[improved], fit_train.target)
    pred = fitted.predict(validate[improved])
    validation.append(float(np.mean((pred-validate.target)**2)))
choice = choices[int(np.argmin(validation))]
new = model(*choice)
new.fit(train[improved], train.target)
test['improved'] = new.predict(test[improved])
test['zero'] = 0.0

metrics = {}
for name in ['original','improved','zero']:
    residual = test[name]-test.target
    metrics[name] = {'mse':float(np.mean(residual**2)), 'mae':float(np.mean(np.abs(residual))),
                     'sign_accuracy':float(np.mean((test[name]>0)==(test.target>0))) if name != 'zero' else None}

# Non-overlapping 19-trading-day holdings, entered next close and exited on t+20.
days = np.array(sorted(test.date.unique()))
rebalance = days[::20]
rows=[]
for name in ['original','improved']:
    for day in rebalance:
        group = test[test.date == day].sort_values(name, ascending=False).head(10)
        if len(group)<10: continue
        positive = np.maximum(group[name].to_numpy(),0)
        weights = positive/positive.sum() if positive.sum()>0 else np.repeat(.1,10)
        gross=float(np.dot(weights,group.target))
        # The entire position is bought and sold every period, including the
        # first and last. The sale cost applies to the sale proceeds.
        net=(1-.001)*(1+gross)*(1-.001)-1
        costs=gross-net
        assert group.entry_date.nunique() == 1 and group.target_end.nunique() == 1, 'Mixed holding dates'
        entry, exit_date = group.entry_date.iloc[0], group.target_end.iloc[0]
        spy_entry=spy.loc[spy.date==entry,'spy_adjusted']
        spy_exit=spy.loc[spy.date==exit_date,'spy_adjusted']
        assert len(spy_entry)==1 and len(spy_exit)==1
        benchmark=float(spy_exit.iloc[0]/spy_entry.iloc[0]-1)
        rows.append({'model':name,'date':str(pd.Timestamp(day).date()),'gross':gross,'net':net,
                     'spy':benchmark,'trading_cost':costs})
bt=pd.DataFrame(rows)
assert len(bt)>0 and bt.groupby('model').size().nunique()==1
bt.to_csv('results/backtest.csv',index=False)
test[['date','symbol','target','original','improved','zero']].to_csv('results/predictions.csv.gz',index=False,compression='gzip')
for name in ['original','improved']:
    part=bt[bt.model==name]
    metrics[name].update({'gross_growth':float((1+part.gross).prod()), 'net_growth':float((1+part.net).prod()),
                          'mean_trading_cost':float(part.trading_cost.mean())})
metrics['spy']={'growth':float((1+bt[bt.model=='original'].spy).prod())}
result={'metrics':metrics,'stock_count':int(d.symbol.nunique()),'train_rows':len(train),'test_rows':len(test),
        'train_start':str(train.date.min().date()),'train_end':str(train.date.max().date()),
        'test_start':str(test.date.min().date()),'test_end':str(test.date.max().date()),
        'validation_mse':validation,'chosen_hyperparameters':list(choice),'periods':int(len(bt)/2)}
Path('results/summary.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))

plt.rcParams.update({'font.size':11,'axes.spines.top':False,'axes.spines.right':False})
fig,ax=plt.subplots(figsize=(8,4.2))
names=['Classroom-style','Modified model','Zero forecast']
bars=ax.bar(names,[metrics[k]['mse']*10000 for k in ['original','improved','zero']],color=['#679b98','#c77747','#8794a1'])
ax.bar_label(bars, fmt='%.1f', padding=3)
ax.set_ylim(0, 100)
ax.set_ylabel('Mean squared error (percentage points²)')
ax.set_title('Out-of-sample forecast error')
fig.tight_layout();fig.savefig('results/forecast.png',dpi=160);plt.close(fig)
fig,ax=plt.subplots(figsize=(8,4.4))
for name,label,color in [('original','Classroom-style, net','#679b98'),('improved','Modified model, net','#c77747')]:
    part=bt[bt.model==name]; ax.plot(pd.to_datetime(part.date),(1+part.net).cumprod(),label=label,color=color)
part=bt[bt.model=='original'];ax.plot(pd.to_datetime(part.date),(1+part.spy).cumprod(),label='SPY, same holding dates',color='#34495e')
ax.axhline(1,color='#aaaaaa',lw=.6);ax.set_ylabel('Growth of $1');ax.set_title('Illustrative test-period portfolios');ax.legend(frameon=False)
ax.xaxis.set_major_locator(mdates.MonthLocator(bymonth=[1,7]))
ax.xaxis.set_major_formatter(mdates.DateFormatter('%b %Y'))
fig.tight_layout();fig.savefig('results/wealth.png',dpi=160);plt.close(fig)
