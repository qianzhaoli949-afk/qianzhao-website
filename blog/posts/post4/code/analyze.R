# Run from blog/posts/post4: Rscript code/analyze.R [--refresh]
# Cached downloads make ordinary analysis runs independent of FRED availability.
dir.create("data/raw", recursive = TRUE, showWarnings = FALSE)
dir.create("results", showWarnings = FALSE)
refresh <- "--refresh" %in% commandArgs(trailingOnly = TRUE)
ids <- c("MSPUS", "MORTGAGE30US", "CPIAUCNS")
manifest_path <- "data/manifest.csv"
manifest <- if (file.exists(manifest_path)) read.csv(manifest_path) else
  data.frame(series = character(), url = character(), retrieved_utc = character(), md5 = character())
read_series <- function(id) {
  path <- file.path("data/raw", paste0(id, ".csv"))
  url <- paste0("https://fred.stlouisfed.org/graph/fredgraph.csv?id=", id,
                "&cosd=2015-01-01&coed=2024-12-31")
  if (refresh || !file.exists(path)) {
    tmp <- tempfile(fileext = ".csv")
    download.file(url, tmp, method = "libcurl", mode = "wb", quiet = TRUE)
    test <- read.csv(tmp, na.strings = c(".", ""))
    stopifnot(identical(names(test), c("observation_date", id)))
    stopifnot(file.copy(tmp, path, overwrite = TRUE))
    manifest <<- rbind(manifest[manifest$series != id, ], data.frame(
      series = id, url = url,
      retrieved_utc = format(Sys.time(), tz = "UTC", usetz = TRUE),
      md5 = unname(tools::md5sum(path))))
    write.csv(manifest, manifest_path, row.names = FALSE)
    Sys.sleep(1)
  }
  row <- manifest[manifest$series == id, ]
  stopifnot(nrow(row) == 1, row$md5 == unname(tools::md5sum(path)))
  d <- read.csv(path, na.strings = c(".", ""))
  stopifnot(identical(names(d), c("observation_date", id)))
  names(d) <- c("date", "value")
  d$date <- as.Date(d$date)
  d <- d[d$date >= as.Date("2015-01-01") & d$date <= as.Date("2024-12-31"), ]
  stopifnot(!anyNA(d), !anyDuplicated(d$date), all(d$value > 0))
  d$quarter <- paste0(format(d$date, "%Y"), "Q", (as.integer(format(d$date, "%m")) - 1) %/% 3 + 1)
  d
}
raw <- setNames(lapply(ids, read_series), ids)
quarter_mean <- function(d, expected) {
  n <- table(d$quarter)
  stopifnot(length(n) == 40, all(n %in% expected))
  aggregate(value ~ quarter, d, mean)
}
p <- quarter_mean(raw$MSPUS, 1)
r <- quarter_mean(raw$MORTGAGE30US, 12:14)
cpi <- quarter_mean(raw$CPIAUCNS, 3)
names(p)[2] <- "price"
names(r)[2] <- "rate"
names(cpi)[2] <- "cpi"
d <- Reduce(function(x, y) merge(x, y, by = "quarter"), list(p, r, cpi))
stopifnot(nrow(d) == 40, identical(d$quarter, paste0(rep(2015:2024, each=4), "Q", 1:4)))
d$date <- as.Date(paste0(substr(d$quarter, 1, 4), "-",
                         sprintf("%02d", (as.integer(substr(d$quarter, 6, 6))-1)*3+1), "-01"))
base <- d[d$quarter == "2019Q4", ]
last <- d[d$quarter == "2024Q4", ]
# 20% down; fixed-rate, fully amortizing 30-year loan; principal and interest only.
payment <- function(price, rate) {
  m <- rate / 1200
  0.8 * price * m / (1 - (1 + m)^(-360))
}
stopifnot(abs(payment(300000, 6) - 1438.9213) < .01)
d$real_price <- d$price * last$cpi / d$cpi
d$payment_nominal <- payment(d$price, d$rate)
d$payment_real <- d$payment_nominal * last$cpi / d$cpi
d$payment_fixed_rate_real <- payment(d$price, base$rate) * last$cpi / d$cpi
scenarios <- data.frame(
  scenario = c("2019 price + rate", "2024 price only", "2024 rate only", "2024 price + rate"),
  real_price = c(base$price * last$cpi/base$cpi, last$price,
                 base$price * last$cpi/base$cpi, last$price),
  rate = c(base$rate, base$rate, last$rate, last$rate))
scenarios$payment <- payment(scenarios$real_price, scenarios$rate)
stopifnot(all(is.finite(d$payment_real)), all(d$payment_real > 0),
          abs(tail(d$payment_real, 1)-scenarios$payment[4]) < 1e-8)
write.csv(d, "data/quarterly.csv", row.names = FALSE)
write.csv(scenarios, "results/scenarios.csv", row.names = FALSE)
capture.output(sessionInfo(), file = "results/session-info.txt")
source("code/plots.R")
draw_figures(d, scenarios)
print(d[d$quarter %in% c("2019Q4", "2024Q4"), c("quarter", "price", "rate", "real_price", "payment_real")])
print(scenarios)
