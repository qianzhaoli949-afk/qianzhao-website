# All figures use the weighted summaries created by analyze.R.
draw_figures <- function(s) {
  dir.create("figures", showWarnings = FALSE)
  cols <- c("#AD4931", "#C28B20", "#25857D", "#345AA3")
  short <- c("Less than HS", "High school", "College / associate", "Bachelor's+")
  open_plot <- function(name, height = 1050) {
    png(file.path("figures", name), width = 1800, height = height, res = 180)
    par(mar = c(4.6, 4.7, 4.1, 1.3), family = "sans", las = 1,
        col.axis = "#445263", col.lab = "#243447", fg = "#243447")
  }
  footer <- function() mtext("Source: IPUMS CPS | Ages 25–64 | WTFINL weighted | Not seasonally adjusted",
                             side = 1, line = 3.4, cex = .7, col = "#526475")
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
  title("The pandemic widened an existing education gap", adj = 0, col.main = "#20354A")
  legend("topright", legend = short, col = cols, lty = 1, lwd = 2, bty = "n", cex = .82)
  footer(); dev.off()
  open_plot("annual.png")
  a <- s$annual
  mat <- sapply(c(2019, 2020, 2024), function(y) a$unemployment_rate[match(paste(y, 1:4), paste(a$YEAR, a$education))])
  bp <- barplot(t(mat), beside = TRUE, col = c("#B8C9DC", "#AD4931", "#25857D"),
                names.arg = short, ylim = c(0, max(mat) + 3), border = NA,
                ylab = "Annual unemployment rate (%)", cex.names = .85)
  text(bp, t(mat) + .35, sprintf("%.1f", t(mat)), cex = .78, col = "#243447")
  title("Rates fell, but remained above 2019 in 2024", adj = 0, col.main = "#20354A")
  legend("topright", legend = c("2019", "2020", "2024"), fill = c("#B8C9DC", "#AD4931", "#25857D"), bty = "n", horiz = TRUE)
  footer(); dev.off()
  open_plot("age.png", 1100)
  par(mfrow = c(1, 3), mar = c(4.0, 4.8, 3.1, .7), oma = c(4, 0, 3, 0))
  a <- s$age[s$age$YEAR %in% c(2019, 2020, 2024), ]
  for (ag in c("25-34", "35-49", "50-64")) {
    plot(c(2019, 2024), c(0, max(a$unemployment_rate) + 1), type = "n", xaxt = "n",
         xlab = "Year", ylab = if (ag == "25-34") "Unemployment rate (%)" else "")
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
