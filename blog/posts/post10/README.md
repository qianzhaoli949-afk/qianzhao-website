# Post 10: Can Car Specifications Predict Fuel Economy?

This post compares ridge regression, a random forest, and a training-mean benchmark on the historical UCI Auto MPG dataset.

## Files

- `index.qmd`: article and references to the figures.
- `data/auto-mpg.data`: original UCI data snapshot.
- `code/analyze.py`: chronological splits, preprocessing, tuning, evaluation, and plots.
- `requirements.txt`: Python package versions.
- `results/summary.json`: sample sizes, model settings, and evaluation results.
- `results/test_predictions.csv`: actual and predicted fuel economy for test cars.
- `results/validation_importance.csv`: permutation importance on the validation period.
- `results/test_errors.png` and `results/importance.png`: article figures.

## Data and methods

Source: [UCI Auto MPG](https://archive.ics.uci.edu/dataset/9/auto+mpg), DOI [10.24432/C5859H](https://doi.org/10.24432/C5859H), licensed CC BY 4.0. The included snapshot has 398 observations and six missing horsepower values. The outcome is city miles per gallon. Predictors are cylinders, displacement, horsepower, weight, acceleration, model year, and origin; car names are excluded.

The 1970–1978 cars form the development set. Three expanding cross-validation folds keep whole model years together: train through 1973 and validate on 1974–1975; train through 1975 and validate on 1976–1977; train through 1977 and validate on 1978. They select ridge's penalty and the forest's maximum depth and minimum leaf size by RMSE. Within each fold, a pipeline imputes numerical medians, scales numerical features, and one-hot encodes origin. The forest uses 250 trees and a fixed random seed.

The 1979–1980 cars select the algorithm by RMSE. The selected model is ridge. The script then refits both algorithms on data through 1980 and evaluates them and the training-mean benchmark on the held-out 1981–1982 cars. It reports MAE and RMSE. Permutation importance uses the selected model trained through 1978 and the 1979–1980 validation data; it is exploratory because those data also select the algorithm. It measures reliance on inputs, not causal effects. Model-year separation does not guarantee that related car models never appear across splits.

## Reproduce

Use Python 3.12, and run these commands from `blog/posts/post10/`:

```sh
python3 -m pip install -r requirements.txt
python3 code/analyze.py
```

The script reads the included data snapshot and writes the files in `results/`. It does not need an API key or a network connection after installation. From the website repository root, render the post with:

```sh
quarto render blog/posts/post10/index.qmd
```

The data are historical, and the results should not be assumed to apply to current vehicles.
