# Run from the post7 folder: Rscript code/prepare.R
if (!requireNamespace("jsonlite", quietly = TRUE)) {
  stop("Install jsonlite first: install.packages('jsonlite')")
}
d <- read.csv("data/pa-counties.csv", colClasses = c(GEOID = "character"))
stopifnot(nrow(d) == 67, !anyDuplicated(d$GEOID), all(d$base2020 > 0),
          all(d$change == d$population2024 - d$base2020),
          all(abs(d$change_pct - 100 * d$change / d$base2020) < 1e-8))
d <- d[order(d$county), c("GEOID", "county", "base2020", "population2024", "change", "change_pct")]
json <- jsonlite::toJSON(d, dataframe = "rows", digits = 10, auto_unbox = TRUE)
writeLines(paste0("window.countyData = ", json, ";"), "data/counties.js", useBytes = TRUE)
