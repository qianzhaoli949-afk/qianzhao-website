# Run: Rscript analyze.R path/to/cps_00001.xml path/to/cps_00001.dat.gz
# Only grouped summaries are saved. Microdata stay outside the website.
if (!requireNamespace("xml2", quietly = TRUE)) stop("Install xml2 first.")
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) stop("Supply the DDI XML and compressed data paths.")
ddi <- xml2::read_xml(args[1])
xml2::xml_ns_strip(ddi)
fields <- c("YEAR", "MONTH", "AGE", "EMPSTAT", "EDUC", "WTFINL")
nodes <- lapply(fields, function(n) xml2::xml_find_first(ddi, paste0("//var[@name='", n, "']")))
start <- vapply(nodes, function(v) as.integer(xml2::xml_attr(xml2::xml_find_first(v, "location"), "StartPos")), 1L)
end <- vapply(nodes, function(v) as.integer(xml2::xml_attr(xml2::xml_find_first(v, "location"), "EndPos")), 1L)
decimals <- vapply(nodes, function(v) {
  a <- xml2::xml_attr(v, "dcml")
  if (is.na(a)) 0 else as.numeric(a)
}, 0)
stopifnot(!anyNA(start), !anyNA(end), decimals[6] == 4)
groups <- c("Less than high school", "High school", "Some college / associate", "Bachelor's or higher")
education <- function(x) {
  g <- rep(NA_integer_, length(x))
  g[x %in% c(2, 10, 20, 30, 40, 50, 60, 71)] <- 1L
  g[x == 73] <- 2L
  g[x %in% c(81, 91, 92)] <- 3L
  g[x %in% c(111, 123, 124, 125)] <- 4L
  g
}
con <- gzfile(args[2], "rt")
parts <- list()
audit <- c(records = 0, excluded_age = 0, excluded_weight = 0,
           excluded_status = 0, excluded_education = 0, retained = 0)
repeat {
  lines <- readLines(con, n = 100000L, warn = FALSE)
  if (!length(lines)) break
  stopifnot(all(nchar(lines) >= max(end)))
  x <- as.data.frame(setNames(lapply(seq_along(fields), function(i)
    as.numeric(substr(lines, start[i], end[i])) / 10^decimals[i]), fields))
  stopifnot(!anyNA(x), all(x$YEAR %in% 2019:2024), all(x$MONTH %in% 1:12))
  audit["records"] <- audit["records"] + nrow(x)
  valid <- x$AGE >= 25 & x$AGE <= 64
  audit["excluded_age"] <- audit["excluded_age"] + sum(!valid)
  x <- x[valid, ]
  valid <- is.finite(x$WTFINL) & x$WTFINL > 0
  audit["excluded_weight"] <- audit["excluded_weight"] + sum(!valid)
  x <- x[valid, ]
  valid <- x$EMPSTAT %in% c(10, 12, 20, 21, 22, 30:36)
  audit["excluded_status"] <- audit["excluded_status"] + sum(!valid)
  x <- x[valid, ]
  x$education <- education(x$EDUC)
  unknown <- setdiff(unique(x$EDUC[is.na(x$education)]), c(0, 1, 999))
  if (length(unknown)) stop("Review education codes: ", paste(unknown, collapse = ", "))
  audit["excluded_education"] <- audit["excluded_education"] + sum(is.na(x$education))
  x <- x[!is.na(x$education), ]
  audit["retained"] <- audit["retained"] + nrow(x)
  x$age_group <- ifelse(x$AGE < 35, "25-34", ifelse(x$AGE < 50, "35-49", "50-64"))
  employed <- x$EMPSTAT %in% c(10, 12)
  unemployed <- x$EMPSTAT %in% c(20, 21, 22)
  x$population <- x$WTFINL
  x$labor_force <- x$WTFINL * (employed | unemployed)
  x$unemployed <- x$WTFINL * unemployed
  x$employed <- x$WTFINL * employed
  x$n <- 1
  x$n_lf <- as.integer(employed | unemployed)
  parts[[length(parts) + 1L]] <- aggregate(
    x[c("population", "labor_force", "unemployed", "employed", "n", "n_lf")],
    x[c("YEAR", "MONTH", "education", "age_group")], sum)
}
close(con)
cells <- do.call(rbind, parts)
totals <- c("population", "labor_force", "unemployed", "employed", "n", "n_lf")
combine <- function(by) aggregate(cells[totals], cells[by], sum)
rates <- function(x) {
  x$unemployment_rate <- 100 * x$unemployed / x$labor_force
  x$employment_population <- 100 * x$employed / x$population
  x$participation_rate <- 100 * x$labor_force / x$population
  stopifnot(all(is.finite(x$unemployment_rate)), all(x$unemployment_rate >= 0 & x$unemployment_rate <= 100))
  x
}
monthly <- rates(combine(c("YEAR", "MONTH", "education")))
annual <- rates(combine(c("YEAR", "education")))
age <- rates(combine(c("YEAR", "education", "age_group")))
stopifnot(nrow(monthly) == 72L * 4L, nrow(annual) == 24L,
          nrow(age) == 72L, sum(monthly$n) == audit["retained"],
          sum(audit[2:6]) == audit[1], all(monthly$n_lf >= 100))
result <- list(monthly = monthly, annual = annual, age = age,
               groups = groups, audit = audit,
               source_md5 = setNames(unname(tools::md5sum(args)), basename(args)))
saveRDS(result, "summary.rds")
capture.output(sessionInfo(), file = "session-info.txt")
print(audit)
print(annual[annual$YEAR %in% c(2019, 2020, 2024), c("YEAR", "education", "unemployment_rate")], row.names = FALSE)
