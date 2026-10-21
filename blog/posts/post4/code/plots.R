draw_figures <- function(d, affordability) {
  dir.create("results/figures", recursive = TRUE, showWarnings = FALSE)
  blue <- "#28658A"; orange <- "#B85A35"; ink <- "#233747"
  start <- function(name, height = 1100) {
    png(file.path("results/figures", name), width = 1800, height = height, res = 180)
    par(mar=c(6,5,3.5,1.5), las=1, col.axis=ink, col.lab=ink, fg=ink)
  }
  note <- function(text) mtext(text, side=1, line=4.7, cex=.72, col=ink)
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
  note("20% down; 30 years; principal and interest only | Calculations from FRED series")
  dev.off()
  start("affordability.png")
  share <- 100 * affordability$payment_share
  plot(affordability$year, share, type="o", pch=16, lwd=2.5, col=blue,
       xlim=c(2015, 2025), ylim=c(min(share)-3, max(share)+4),
       xlab="Year (fourth quarter)", ylab="Annual payment / median household income (%)",
       main="The modeled payment took a larger share of median income")
  selected <- affordability$year %in% c(2019, 2024)
  points(affordability$year[selected], share[selected], pch=16, cex=1.5, col=orange)
  text(affordability$year[selected], share[selected],
       sprintf("%.1f%%", share[selected]), pos=3, offset=.8, col=ink)
  note("Q4 new-home payment annualized / same-year U.S. median household income | Census H-5 and FRED")
  dev.off()
}
