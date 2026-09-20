# Compare median pay and projected annual openings.
plot_careers <- function(careers) {
  short <- c("Data science", "Operations research",
             "Financial & investment analysis", "Actuarial work")
  labels <- short[match(careers$soc,
                       c("15-2051.00", "15-2031.00", "13-2051.00", "15-2011.00"))]
  if (anyNA(labels)) stop("Unexpected occupation in plot.")
  colors <- c("#176D96", "#636F7B", "#208470", "#B76731")
  old <- par(mar = c(5.4, 5.3, 4.2, 1.5), family = "sans", las = 1,
             col.axis = "#485563", col.lab = "#283441", fg = "#D6DEE5")
  on.exit(par(old))
  x <- careers$annual_projected_openings / 1000
  y <- careers$median_annual_pay_usd / 1000
  plot(x, y, type = "n", xlim = c(0, 30), ylim = c(78, 143),
       xaxs = "i", yaxs = "i", axes = FALSE,
       xlab = "Projected average annual openings (thousands)",
       ylab = "Median annual pay (USD thousands)")
  abline(h = seq(80, 140, 10), col = "#E7EDF2", lwd = 0.8)
  axis(1, at = seq(0, 30, 5), col = "#B9C5CF", lwd = 0, lwd.ticks = 0)
  axis(2, at = seq(80, 140, 10), labels = paste0("$", seq(80, 140, 10)),
       col = "#B9C5CF", lwd = 0, lwd.ticks = 0)
  points(x, y, pch = 21, cex = 2.0, bg = colors, col = "white", lwd = 1.5)
  # Place labels inward near the right edge.
  label_pos <- ifelse(x > 20, 2, 4)
  text(x, y + 3.5, labels = labels, pos = label_pos, offset = 0.35,
       cex = 0.88, font = 2, col = colors)
  title("A higher salary does not mean a larger job market",
        adj = 0, col.main = "#172A3A", cex.main = 1.13)
  mtext(paste0("Pay: ", unique(careers$wage_year), " | Openings: ",
               unique(careers$projection_period), " projections | United States"),
        side = 3, line = 0.65, adj = 0, col = "#657381", cex = 0.80)
}
