draw_figures <- function(d, scenarios) {
  dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
  blue <- "#28658A"; orange <- "#B85A35"; ink <- "#233747"
  start <- function(name, height = 1100) {
    png(file.path("results/figures", name), width = 1800, height = height, res = 180)
    par(mar=c(4.5,5,3.5,1.5), las=1, col.axis=ink, col.lab=ink, fg=ink)
  }
  note <- function(text) mtext(text, side=1, line=3.3, cex=.72, col=ink)
  start("prices-rates.png", 1400)
  par(mfrow=c(2,1), mar=c(3.5,5,3,1.5), oma=c(2,0,0,0))
  plot(d$date, d$real_price/1000, type="l", lwd=2.5, col=blue,
       xlab="", ylab="Thousands of 2024 Q4 dollars",
       main="New-home prices after adjusting for inflation")
  plot(d$date, d$rate, type="l", lwd=2.5, col=orange,
       xlab="", ylab="Mortgage rate (%)", main="Financing costs moved on a different path")
  mtext("2015–2024 | Quarterly | Census/HUD, Freddie Mac and BLS via FRED | Not seasonally adjusted",
        side=1, outer=TRUE, cex=.7)
  dev.off()
  start("payments.png")
  yr <- range(c(d$payment_real, d$payment_fixed_rate_real))
  plot(d$date, d$payment_real, type="l", lwd=2.5, col=orange,
       ylim=c(yr[1]*.92, yr[2]*1.15), xlab="", ylab="Monthly payment (2024 Q4 dollars)",
       main="Higher rates added to the new-buyer payment hurdle")
  lines(d$date, d$payment_fixed_rate_real, lwd=2.5, col=blue, lty=2)
  legend("topleft", c("Each quarter's price and rate", "Each quarter's price; rate fixed at 2019 Q4"),
         col=c(orange, blue), lty=c(1,2), lwd=2.5, bty="n", cex=.8)
  note("20% down; 30 years; principal and interest only | Authors' calculations from FRED series")
  dev.off()
  start("scenarios.png")
  par(mar=c(5.5,5,3.5,1.5))
  b <- barplot(scenarios$payment, col=c("#A4B8C7", blue, "#D9966E", orange),
               border=NA, ylim=c(0, max(scenarios$payment)*1.22),
               names.arg=c("2019 price\n2019 rate", "2024 price\n2019 rate", "2019 price\n2024 rate", "2024 price\n2024 rate"),
               cex.names=.85, ylab="Monthly payment (2024 Q4 dollars)",
               main="Separating real-price and rate changes: four scenarios")
  text(b, scenarios$payment, sprintf("$%s", format(round(scenarios$payment), big.mark=",")),
       pos=3, cex=.9, col=ink)
  mtext("Q4 endpoints | 2019 prices inflated to 2024 Q4 dollars | 20% down; 30-year loan",
        side=1, line=4.2, cex=.72)
  dev.off()
}
