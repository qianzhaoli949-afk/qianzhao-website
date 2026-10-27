# Run from blog/posts/post8: Rscript code/simulate.R
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Install jsonlite first.")
set.seed(20261027)
mu <- 50
sigma <- 10
repetitions <- 1000
resamples <- 500
null_draws <- 5000
sizes <- c(20, 50, 100)
result <- lapply(sizes, function(n) {
  boot <- function(x) replicate(resamples, mean(sample(x, length(x), replace = TRUE)))
  sample_data <- rnorm(n, mu, sigma)
  sample_boot <- boot(sample_data)
  interval <- unname(quantile(sample_boot, c(.025, .975)))
  intervals <- t(replicate(repetitions, {
    x <- rnorm(n, mu, sigma)
    unname(quantile(boot(x), c(.025, .975)))
  }))
  covers <- intervals[, 1] <= mu & intervals[, 2] >= mu
  null_means <- replicate(null_draws, mean(rnorm(n, mu, sigma)))
  cutoff <- unname(quantile(abs(null_means - mu), .95))
  observed <- mean(sample_data)
  p <- mean(abs(null_means - mu) >= abs(observed - mu))
  list(n = n, sample_mean = observed, bootstrap = sample_boot,
       interval = interval, lower = intervals[1:100, 1], upper = intervals[1:100, 2],
       coverage = mean(covers), covered_count = sum(covers), repetitions = repetitions,
       null_means = null_means, cutoff = cutoff, p_value = p)
})
names(result) <- as.character(sizes)
stopifnot(all(vapply(result, function(x) length(x$bootstrap) == resamples &&
  length(x$null_means) == null_draws && x$coverage >= 0 && x$coverage <= 1, logical(1))))
json <- jsonlite::toJSON(result, auto_unbox = TRUE, digits = 9)
writeLines(paste0("window.simulations = ", json, ";"), "data/simulations.js", useBytes = TRUE)
saveRDS(result, "data/simulations.rds")
for (x in result) cat(sprintf("n=%d mean=%.2f CI=[%.2f,%.2f] coverage=%d/%d p=%.4f cutoff=%.2f\n",
  x$n, x$sample_mean, x$interval[1], x$interval[2], x$covered_count, x$repetitions, x$p_value, x$cutoff))
