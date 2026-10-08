# Compare median pay and projected annual openings.
plot_growth <- function(analysis) {
  short <- c("Data science", "Operations research", "Financial & investment", "Actuarial work")
  labels <- short[match(analysis$soc, c("15-2051.00", "15-2031.00", "13-2051.00", "15-2011.00"))]
  stopifnot(!anyNA(labels))
  ord <- order(analysis$annual_openings_per_100_base_jobs)
  x <- analysis$annual_openings_per_100_base_jobs[ord]
  cols <- ifelse(analysis$growth_category[ord] == "Much faster than average (7% or higher)",
                 "#176D96", "#B76731")
  old <- par(mar=c(5.7, 10.5, 5.5, 2), las=1, family="sans", fg="#283441")
  on.exit(par(old))
  b <- barplot(x, horiz=TRUE, names.arg=labels[ord], col=cols, border=NA,
               xlim=c(0, 11), xlab="Projected annual openings per 100 jobs in 2024",
               cex.names=.9)
  text(x+.15, b, sprintf("%.1f", x), adj=0, col="#283441")
  title("Fast growth is not the same as a large job market", adj=0, line=3.8, cex.main=1.05)
  legend("top", inset=c(0,-.12), xpd=NA, bty="n", cex=.78,
         legend=c("2024–34 net growth: 7% or higher", "2024–34 net growth: 5% to 6%"),
         fill=c("#176D96", "#B76731"))
  mtext("Bar length: gross annual openings / base employment, not a growth rate or hiring probability",
        side=1, line=4.1, cex=.68)
}

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
