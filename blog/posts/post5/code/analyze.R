# Run from blog/posts/post5: Rscript code/analyze.R [--refresh]
if (!requireNamespace("sf", quietly=TRUE)) stop("Install sf first: install.packages('sf')")
dir.create("data/raw", recursive=TRUE, showWarnings=FALSE)
dir.create("results/figures", recursive=TRUE, showWarnings=FALSE)
refresh <- "--refresh" %in% commandArgs(trailingOnly=TRUE)
sources <- c(
  "population.csv"="https://www2.census.gov/programs-surveys/popest/datasets/2020-2024/counties/totals/co-est2024-alldata.csv",
  "counties.zip"="https://www2.census.gov/geo/tiger/GENZ2024/shp/cb_2024_us_county_500k.zip")
manifest <- if (file.exists("data/manifest.csv")) read.csv("data/manifest.csv") else
  data.frame(file=character(), url=character(), retrieved_utc=character(), md5=character())
for (f in names(sources)) {
  path <- file.path("data/raw", f)
  if (refresh || !file.exists(path)) {
    download.file(sources[[f]], path, mode="wb", method="libcurl", quiet=TRUE)
    manifest <- rbind(manifest[manifest$file != f, ], data.frame(file=f, url=sources[[f]],
      retrieved_utc=format(Sys.time(),tz="UTC",usetz=TRUE), md5=unname(tools::md5sum(path))))
    write.csv(manifest,"data/manifest.csv",row.names=FALSE)
  }
  m <- manifest[manifest$file == f, ]
  stopifnot(nrow(m)==1, m$md5 == unname(tools::md5sum(path)))
}
raw <- read.csv("data/raw/population.csv", fileEncoding="latin1")
pa <- raw[raw$STATE==42 & raw$SUMLEV==50, ]
stopifnot(nrow(pa)==67, !anyDuplicated(pa$COUNTY), all(pa$ESTIMATESBASE2020>0))
d <- data.frame(GEOID=sprintf("%02d%03d",pa$STATE,pa$COUNTY),
  county=sub(" County$","",pa$CTYNAME), base2020=pa$ESTIMATESBASE2020,
  population2024=pa$POPESTIMATE2024)
d$change <- d$population2024-d$base2020
d$change_pct <- 100*d$change/d$base2020
# 2020 components cover April 1–July 1; later components cover July–July years.
sum_component <- function(prefix) rowSums(pa[paste0(prefix,2020:2024)])
d$natural_change <- sum_component("NATURALCHG")
d$net_migration <- sum_component("NETMIG")
d$residual <- sum_component("RESIDUAL")
stopifnot(!anyNA(d), all(d$change == d$natural_change+d$net_migration+d$residual))
for (v in c("natural_change","net_migration","residual"))
  d[[paste0(v,"_per100")]] <- 100*d[[v]]/d$base2020
state <- raw[raw$STATE==42 & raw$SUMLEV==40, ]
stopifnot(nrow(state)==1, sum(d$base2020)==state$ESTIMATESBASE2020,
          sum(d$population2024)==state$POPESTIMATE2024)
shape_dir <- tempfile("county-shapes-")
dir.create(shape_dir)
unzip("data/raw/counties.zip", exdir=shape_dir)
shp <- list.files(shape_dir,pattern="\\.shp$",full.names=TRUE)
stopifnot(length(shp)==1)
geo <- sf::st_read(shp, quiet=TRUE)
geo <- geo[geo$STATEFP=="42", c("GEOID","NAME")]
stopifnot(nrow(geo)==67, !anyDuplicated(geo$GEOID), setequal(geo$GEOID,d$GEOID))
geo <- sf::st_transform(geo,5070)
stopifnot(all(sf::st_is_valid(geo)), !any(sf::st_is_empty(geo)))
d <- d[match(geo$GEOID,d$GEOID), ]
stopifnot(identical(geo$GEOID,d$GEOID), identical(as.character(geo$NAME),d$county))
geo <- cbind(geo,d[setdiff(names(d),c("GEOID","county"))])
write.csv(d,"data/pa-counties.csv",row.names=FALSE)
saveRDS(geo,"data/pa-counties.rds")
source("code/plots.R")
draw_figures(geo,d)
capture.output(sessionInfo(),file="results/session-info.txt")
print(d[order(d$change_pct,decreasing=TRUE),c("county","change","change_pct")],row.names=FALSE)
cat("State change:",sum(d$change),"; percent:",100*sum(d$change)/sum(d$base2020),"\n")
