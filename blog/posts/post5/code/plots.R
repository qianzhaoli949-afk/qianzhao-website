draw_figures <- function(geo,d) {
  colors <- c("#B35806","#F1A340","#FEE0B6","#D8DAEB","#998EC3","#542788")
  cuts <- c(-Inf,-4,-2,0,2,4,Inf)
  groups <- cut(d$change_pct,cuts,right=FALSE)
  png("results/figures/population-map.png",width=2100,height=1450,res=200)
  par(mar=c(1,1,4,1))
  box <- sf::st_bbox(geo)
  plot(sf::st_geometry(geo), col=colors[as.integer(groups)],border="white",lwd=.7,
       ylim=c(box["ymin"]-48000,box["ymax"]+10000))
  title("Pennsylvania's population change is uneven", adj=0, cex.main=1.2)
  mtext("April 1, 2020 estimates base to July 1, 2024 | Percent change",side=3,line=.6,adj=0,cex=.88)
  # Label selected reference counties with matching FIPS; not all 67 labels fit.
  chosen <- c("Philadelphia","Chester","Cumberland","Allegheny","Centre","Erie","Pike")
  at <- match(chosen,d$county)
  pts <- suppressWarnings(sf::st_coordinates(sf::st_point_on_surface(geo[at, ])))
  label_colors <- ifelse(as.integer(groups[at]) %in% c(1,6),"white","#172A3A")
  text(pts[,1],pts[,2],labels=chosen,cex=.62,col=label_colors,font=2)
  legend("bottom",legend=c("Below -4%","-4 to < -2%","-2 to < 0%","0 to < 2%","2 to < 4%","4% or more"),
         fill=colors,border=NA,ncol=3,bty="n",cex=.83,inset=.01,
         title="Population change (not an annual rate)")
  mtext("Source: Census Vintage 2024 estimates and 2024 cartographic county boundaries | CONUS Albers (EPSG:5070)",
        side=1,line=-.6,cex=.65)
  dev.off()
  # Selected locations connect the map's patterns to population accounting.
  chosen <- c("Cumberland","Chester","Pike","Centre","Allegheny","Philadelphia","Erie")
  z <- d[match(chosen,d$county), ]
  mat <- rbind(z$natural_change_per100,z$net_migration_per100,z$residual_per100)
  png("results/figures/components.png",width=2100,height=1300,res=200)
  par(mar=c(5.5,5,4.5,1),las=1)
  bp <- barplot(mat,beside=TRUE,col=c("#B35806","#542788","#92999F"),border=NA,
                names.arg=z$county,cex.names=.77,ylim=range(c(mat,0))*1.22,
                ylab="Change per 100 residents in the 2020 base")
  abline(h=0,col="#263746")
  title("Migration and natural change can pull in opposite directions",cex.main=1.02,line=2.8)
  legend("top",inset=c(0,-.11),xpd=NA,horiz=TRUE,bty="n",cex=.83,
         legend=c("Births minus deaths","Net migration","Residual adjustment"),
         fill=c("#B35806","#542788","#92999F"))
  mtext("Selected counties, not a statewide ranking | April 2020–July 2024 | Census Vintage 2024",side=1,line=3.7,cex=.72)
  dev.off()
}
