# All figures use the weighted summaries created by analyze.R.
education_gaps <- function(s) {
  a <- s$annual
  low <- a[a$education == 1, c("YEAR", "unemployment_rate")]
  high <- a[a$education == 4, c("YEAR", "unemployment_rate")]
  stopifnot(!anyDuplicated(low$YEAR), !anyDuplicated(high$YEAR),
            setequal(low$YEAR, 2019:2024), setequal(high$YEAR, 2019:2024))
  names(low)[2] <- "less_than_high_school_rate"
  names(high)[2] <- "bachelors_or_higher_rate"
  g <- merge(low, high, by="YEAR", sort=TRUE)
  stopifnot(!anyNA(g), all(g$bachelors_or_higher_rate > 0))
  g$gap_percentage_points <- g$less_than_high_school_rate - g$bachelors_or_higher_rate
  g$rate_ratio <- g$less_than_high_school_rate / g$bachelors_or_higher_rate
  g
}

draw_figures <- function(s) {
  dir.create("figures", showWarnings = FALSE)
  cols <- c("#AD4931", "#C28B20", "#25857D", "#345AA3")
  short <- c("Less than HS", "High school", "College / associate", "Bachelor's+")
  open_plot <- function(name, height = 1050) {
    png(file.path("figures", name), width = 1800, height = height, res = 180)
    par(mar = c(6.2, 4.7, 4.1, 1.3), family = "sans", las = 1,
        col.axis = "#445263", col.lab = "#243447", fg = "#243447")
  }
  footer <- function() mtext("Source: IPUMS CPS | Ages 25–64 | WTFINL weighted | Not seasonally adjusted",
                             side = 1, line = 4.9, cex = .7, col = "#526475")
  open_plot("monthly.png")
  d <- s$monthly
  d$date <- as.Date(sprintf("%d-%02d-01", d$YEAR, d$MONTH))
  plot(range(d$date), c(0, 24), type = "n", xlab = "", ylab = "Unemployment rate (%)", xaxt = "n", yaxt = "n")
  rect(as.Date("2020-03-01"), 0, as.Date("2020-06-01"), 24, col = "#EFF2F5", border = NA)
  abline(h = seq(0, 24, 4), col = "#E6EBF0")
  axis(2, at = seq(0, 24, 4))
  ticks <- as.Date(paste0(2019:2024, "-01-01"))
  axis.Date(1, at = ticks, format = "%Y")
  for (g in 1:4) { z <- d[d$education == g, ]; z <- z[order(z$date), ]; lines(z$date, z$unemployment_rate, col = cols[g], lwd = 2) }
  title("Unemployment rose across all four education groups in 2020", adj = 0, col.main = "#20354A", cex.main=.95)
  legend("topright", legend = short, col = cols, lty = 1, lwd = 2, bty = "n", cex = .82)
  footer(); dev.off()
  write.csv(education_gaps(s), "education-gaps.csv", row.names=FALSE)
  open_plot("employment.png")
  a <- s$annual
  par(mar = c(6.2, 9, 4.1, 1.3))
  years <- c(2019, 2020, 2024)
  year_cols <- c("#345AA3", "#AD4931", "#25857D")
  offsets <- c(.18, 0, -.18)
  plot(c(50, 90), c(.5, 4.5), type="n", yaxt="n",
       xlab="Adults with a job (%)", ylab="")
  abline(v=seq(50, 90, 10), col="#E6EBF0")
  axis(2, at=4:1, labels=short, tick=FALSE, cex.axis=.87)
  for (g in 1:4) {
    values <- a$employment_population[match(paste(years, g), paste(a$YEAR, a$education))]
    stopifnot(!anyNA(values))
    lines(values, 5-g+offsets, col="#B8C3CC", lwd=2)
    points(values, 5-g+offsets, pch=19, col=year_cols, cex=1.5)
  }
  title("Employment fell in every education group in 2020", adj=0, col.main="#20354A", cex.main=1.0)
  legend("bottomright", legend=as.character(years), col=year_cols,
         pch=19, bty="n", horiz=TRUE, cex=.9)
  footer(); dev.off()
  open_plot("age.png", 1100)
  par(mfrow = c(1, 3), mar = c(4.0, 4.8, 3.1, .7), oma = c(4, 0, 3, 0))
  a <- s$age[s$age$YEAR %in% c(2019, 2020, 2024), ]
  for (ag in c("25-34", "35-49", "50-64")) {
    plot(c(2019, 2024), c(0, max(a$unemployment_rate) + 1), type = "n", xaxt = "n",
         xlab = "", ylab = if (ag == "25-34") "Unemployment rate (%)" else "")
    axis(1, at = c(2019, 2020, 2024), labels = c("2019", "2020", "2024"), cex.axis = .85)
    abline(h = seq(0, 20, 2), col = "#E6EBF0")
    for (g in 1:4) {
      z <- a[a$age_group == ag & a$education == g, ]; z <- z[order(z$YEAR), ]
      lines(z$YEAR, z$unemployment_rate, type = "b", pch = 19, col = cols[g], lwd = 2)
    }
    title(paste("Ages", ag), col.main = "#20354A")
  }
  mtext("The education gradient appears within each age group", outer = TRUE, side = 3, line = 1, font = 2, cex = 1.2)
  par(fig = c(0, 1, 0, 1), new = TRUE, mar = rep(0, 4))
  plot.new()
  legend("bottom", legend = short, col = cols, lty = 1, pch = 19, bty = "n", horiz = TRUE, cex = .8, inset = -.025, xpd = NA)
  dev.off()
}
