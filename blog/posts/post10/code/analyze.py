"""Compare auto-fuel-economy models using a chronological holdout."""
import json
from pathlib import Path
import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.dummy import DummyRegressor
from sklearn.ensemble import RandomForestRegressor
from sklearn.impute import SimpleImputer
from sklearn.inspection import permutation_importance
from sklearn.linear_model import Ridge
from sklearn.metrics import mean_absolute_error, mean_squared_error
from sklearn.model_selection import GridSearchCV
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt

Path('results').mkdir(exist_ok=True)
columns=['mpg','cylinders','displacement','horsepower','weight','acceleration','model_year','origin','car_name']
d=pd.read_csv('data/auto-mpg.data',sep=r'\s+',names=columns,na_values='?').sort_values('model_year').reset_index(drop=True)
assert len(d)==398 and d.mpg.notna().all()
numeric=['cylinders','displacement','horsepower','weight','acceleration','model_year']
categorical=['origin']
features=numeric+categorical
train=d[d.model_year<=78].reset_index(drop=True)
val=d[d.model_year.isin([79,80])]
test=d[d.model_year.isin([81,82])]
full=d[d.model_year<=80]
assert len(train)+len(val)+len(test)==398 and set(d.model_year)==set(range(70,83))

def prep():
    return ColumnTransformer([
        ('numbers',Pipeline([('impute',SimpleImputer(strategy='median')),('scale',StandardScaler())]),numeric),
        ('origin',OneHotEncoder(handle_unknown='ignore'),categorical)])

# Entire model years stay together in each expanding cross-validation split.
folds=[]
for last_train, validation_years in [(73,[74,75]),(75,[76,77]),(77,[78])]:
    folds.append((np.flatnonzero(train.model_year<=last_train),np.flatnonzero(train.model_year.isin(validation_years))))
models={
 'Ridge':(Ridge(),{'model__alpha':[0.1,1,10,100,1000]}),
 'Random forest':(RandomForestRegressor(n_estimators=250,random_state=6400,n_jobs=1),
                  {'model__max_depth':[3,6,10,None],'model__min_samples_leaf':[3,10]}),
}
searches={}; validation={}
for name,(estimator,grid) in models.items():
    pipe=Pipeline([('prepare',prep()),('model',estimator)])
    search=GridSearchCV(pipe,grid,cv=folds,scoring='neg_root_mean_squared_error',n_jobs=1)
    search.fit(train[features],train.mpg)
    searches[name]=search
    validation[name]=float(np.sqrt(mean_squared_error(val.mpg,search.predict(val[features]))))
chosen=min(validation,key=validation.get)
# Interpret the selected development model on the same validation period.
importance=permutation_importance(searches[chosen].best_estimator_,val[features],val.mpg,
    scoring='neg_mean_absolute_error',n_repeats=30,random_state=6400,n_jobs=1)
ranking=pd.DataFrame({'feature':features,'importance_mae':importance.importances_mean,
                      'sd':importance.importances_std}).sort_values('importance_mae',ascending=False)
ranking.to_csv('results/validation_importance.csv',index=False)
predictions=test[['model_year','car_name','mpg']].copy()
baseline=DummyRegressor(strategy='mean').fit(full[features],full.mpg)
all_models={'Training mean':baseline}
for name,search in searches.items():
    fitted=search.best_estimator_
    fitted.fit(full[features],full.mpg)
    all_models[name]=fitted
metrics={}
for name,fitted in all_models.items():
    pred=fitted.predict(test[features]); predictions[name]=pred
    metrics[name]={'rmse':float(np.sqrt(mean_squared_error(test.mpg,pred))),
                   'mae':float(mean_absolute_error(test.mpg,pred))}
predictions.to_csv('results/test_predictions.csv',index=False)
summary={'n_development':len(train),'n_validation':len(val),'n_test':len(test),'missing_horsepower':int(d.horsepower.isna().sum()),
         'validation_rmse':validation,'chosen_by_validation':chosen,
         'cv_best_rmse':{k:float(-s.best_score_) for k,s in searches.items()},
         'best_params':{k:s.best_params_ for k,s in searches.items()},'test':metrics,
         'test_actual_mean':float(test.mpg.mean()),'training_mean':float(full.mpg.mean()),
         'test_prediction_means':{k:float(predictions[k].mean()) for k in all_models},
         'features':features,'importance_source':'1979–1980 validation cars, selected model fitted through 1978'}
Path('results/summary.json').write_text(json.dumps(summary,indent=2))
print(json.dumps(summary,indent=2));print(ranking.to_string(index=False))

plt.rcParams.update({'font.size':11,'axes.spines.top':False,'axes.spines.right':False})
fig,ax=plt.subplots(figsize=(8,4.5))
labels=list(metrics); values=[metrics[k]['mae'] for k in labels]
bars=ax.bar(labels,values,color=['#8b98a4','#438b84','#d37d4b'])
ax.bar_label(bars,fmt='%.2f',padding=3);ax.set_ylim(0,max(values)*1.2)
ax.set_ylabel('Mean absolute error (miles per gallon)');ax.set_title('Prediction error on 1981–1982 cars')
fig.tight_layout();fig.savefig('results/test_errors.png',dpi=160);plt.close(fig)
labels={'cylinders':'Cylinders','displacement':'Engine size','horsepower':'Horsepower','weight':'Weight',
        'acceleration':'Acceleration','model_year':'Model year','origin':'Origin'}
fig,ax=plt.subplots(figsize=(8,4.8)); v=ranking.iloc[::-1]
ax.barh(v.feature.map(labels),v.importance_mae,color='#438b84');ax.axvline(0,color='#444',lw=.8)
ax.set_xlabel('Increase in validation MAE when shuffled (mpg)')
ax.set_title('Which inputs mattered for the selected model?')
fig.tight_layout();fig.savefig('results/importance.png',dpi=160);plt.close(fig)
