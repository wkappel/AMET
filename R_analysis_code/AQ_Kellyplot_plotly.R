header <- "
######################################## KELLY PLOT ########################################
### AMET CODE: AQ_Kellyplot.R
###
### This script is part of the AMET-AQ system. It essentially creates a grid plot of model NMB, 
### NME, RMSE, MB, ME and correlation for a single network/species and multiple simulations. 
### The grid is plotted with NOAA climate region on the y-axis and season on the x-axis. Each 
### shaded box in the grid is color coded to the performance range for that particular 
### region/season. This particular version of the code is designed to work for an annual 
### simulation to provide values for each season.
###
### Note that this code does not currently work without the database, as database metadata are
### needed to identify the NOAA climate regions.
###
### Original concept and some code developed by Jim Kelly of EPA.
###
### Last updated by Wyat Appel: Jun 2020
#############################################################################################
"

# get some environmental variables and setup some directories
ametbase        <- Sys.getenv("AMETBASE")        		# base directory of AMET
ametR           <- paste(ametbase,"/R_analysis_code",sep="")    # R directory

## source miscellaneous R input file 
source(paste(ametR,"/AQ_Misc_Functions.R",sep=""))     # Miscellanous AMET R-functions file

require(reshape2)
require(data.table)
require(ggplot2)
require(RColorBrewer)
require(plotly)
require(dplyr)

network <- network_names[1]
network_name <- network_label[1]
num_runs <- 1

################################################
## Set output names and remove existing files ##
################################################
filename_nmb    <- paste(run_name1,species,pid,"Kellyplot_NMB",sep="_")
filename_nme    <- paste(run_name1,species,pid,"Kellyplot_NME",sep="_")
filename_rmse   <- paste(run_name1,species,pid,"Kellyplot_RMSE",sep="_")
filename_mb     <- paste(run_name1,species,pid,"Kellyplot_MB",sep="_")
filename_me     <- paste(run_name1,species,pid,"Kellyplot_ME",sep="_")
filename_corr   <- paste(run_name1,species,pid,"Kellyplot_Corr",sep="_")
filename_txt    <- paste(run_name1,species,pid,"Kellyplot_stats_data.csv",sep="_")      # Set output file name
filename_zip    <- paste(run_name1,species,pid,"Kellyplot.zip",sep="_")

## Create a full path to file
filename        <- NULL
filename[1]     <- paste(figdir,filename_nmb,sep="/")
filename[2]     <- paste(figdir,filename_nme,sep="/")
filename[5]     <- paste(figdir,filename_rmse,sep="/")
filename[3]     <- paste(figdir,filename_mb,sep="/")
filename[4]     <- paste(figdir,filename_me,sep="/")
filename[6]     <- paste(figdir,filename_corr,sep="/")
filename_txt    <- paste(figdir,filename_txt,sep="/")
filename_zip    <- paste(figdir,filename_zip,sep="/")
#################################################

method <- "Mean"
if (use_median == "y") {
   method <- "Median"
}

if(!exists("dates")) { dates <- paste(start_date,"-",end_date) }
{
   if (custom_title == "") { title <- paste(run_name1,network,species,"for",dates,sep=" ") }
   else { title <- custom_title }
}

################################################

season         <- NULL
region         <- NULL

### Define NOAA climate region database queries ###
region[1] <- " and (s.state='IL' or s.state='IN' or s.state='KY' or s.state='MO' or s.state='OH' or s.state='TN' or s.state='WV')"
region[2] <- " and (s.state='IA' or s.state='MI' or s.state='MN' or s.state='WI')"
region[3] <- " and (s.state='CT' or s.state='DE' or s.state='ME' or s.state='MD' or s.state='MA' or s.state='NH' or s.state='NJ' or s.state='NY' or s.state='PA' or s.state='RI' or s.state='VT')"
region[4] <- " and (s.state='ID' or s.state='OR' or s.state='WA')"
region[5] <- " and (s.state='AR' or s.state='KS' or s.state='LA' or s.state='MS' or s.state='OK' or s.state='TX')"
region[6] <- " and (s.state='AL' or s.state='FL' or s.state='GA' or s.state='SC' or s.state='NC' or s.state='VA')"
region[7] <- " and (s.state='AZ' or s.state='CO' or s.state='NM' or s.state='UT')"
region[8] <- " and (s.state='CA' or s.state='NV')"
region[9] <- " and (s.state='MT' or s.state='NE' or s.state='ND' or s.state='SD' or s.state='WY')"

region_names <- c("Ohio Valley","Upper Midwest","Northeast","Northwest","South","Southeast","Southwest","West","NRockiesPlains")

### Define season database queries ###
season[4] <- " and (d.month = 12 or d.month = 1 or d.month = 2)"
season[1] <- " and (d.month = 3 or d.month = 4 or d.month = 5)"
season[2] <- " and (d.month = 6 or d.month = 7 or d.month = 8)"
season[3] <- " and (d.month = 9 or d.month = 10 or d.month = 11)"

season_names <- c("Spring","Summer","Fall","Winter")
k <- 1

query_result   <- query_dbase(run_name1,network,species)
aqdat_query.df <- query_result[[1]]
data_exists    <- query_result[[2]]
units          <- query_result[[3]]
model_name     <- query_result[[4]] 

if (data_exists == "n") { stop("Stopping because query returned no data. Check for errors in your query setup.") }

ob_col_name <- paste(species,"_ob",sep="")
mod_col_name <- paste(species,"_mod",sep="")
aqdat.df <- data.frame(Network=I(aqdat_query.df$network),Stat_ID=I(aqdat_query.df$stat_id),lat=aqdat_query.df$lat,lon=aqdat_query.df$lon,month=aqdat_query.df$month,state=aqdat_query.df$state,Obs_Value=aqdat_query.df[[ob_col_name]],Mod_Value=aqdat_query.df[[mod_col_name]])
state2region <- data.frame(state=c("IL","IN","KY","MO","OH","TN","WV","IA","MI","MN","WI","CT","DE","ME","MD","MA","NH","NJ","NY","PA","RI","VT","ID","OR","WA","AR","KS","LA","MS","OK","TX","AL","FL","GA","SC","NC","VA","AZ","CO","NM","UT","CA","NV","MT","NE","ND","SD","WY"),reg=c("Ohio Valley","Ohio Valley","Ohio Valley","Ohio Valley","Ohio Valley","Ohio Valley","Ohio Valley","Upper Midwest","Upper Midwest","Upper Midwest","Upper Midwest","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northwest","Northwest","Northwest","South","South","South","South","South","South","Southeast","Southeast","Southeast","Southeast","Southeast","Southeast","Southwest","Southwest","Southwest","Southwest","West","West","NRockiesPlains","NRockiesPlains","NRockiesPlains","NRockiesPlains","NRockiesPlains"))
month2season <- data.frame(month=c(1,2,3,4,5,6,7,8,9,10,11,12),season = c("Winter","Winter","Spring","Spring","Spring","Summer","Summer","Summer","Fall","Fall","Fall","Winter"))
aqdat.df$region <- state2region$reg[match(aqdat.df$state,state2region$state)]
aqdat.df$season <- month2season$season[match(aqdat.df$month, month2season$month)]
aqdat.df$region <- factor(aqdat.df$region, levels=c("Ohio Valley","Upper Midwest","Northeast","Northwest","South","Southeast","Southwest","West","NRockiesPlains"))
aqdat.df$season <- factor(aqdat.df$season, levels=c("Winter", "Spring", "Summer","Fall"))

for (r in 1:length(region_names)) {
   for (s in 1:length(season_names)) {
      aqdat_sub.df <- subset(aqdat.df,aqdat.df$region == region_names[r])
      aqdat_sub.df <- subset(aqdat_sub.df,aqdat_sub.df$season == season_names[s])
#      if (length(aqdat_sub.df$Network) == 0) { stop("Stopping because query returned no data for at least one climate region and/or season. Check for data completeness.") }
      data_all.df <- data.frame(network=I(aqdat_sub.df$Network),stat_id=I(aqdat_sub.df$Stat_ID),lat=aqdat_sub.df$lat,lon=aqdat_sub.df$lon,ob_val=aqdat_sub.df$Obs_Value,mod_val=aqdat_sub.df$Mod_Value)
      stats_all.df <-try(DomainStats(data_all.df,rm_negs="T"))       # Compute stats using DomainStats function for entire domain
      if (is.null(stats_all.df$Mean_Bias)) { 
         stats_all.df$Percent_Norm_Mean_Bias <- NA
         stats_all.df$Percent_Norm_Mean_Err <- NA
         stats_all.df$Mean_Bias <- NA 
         stats_all.df$Mean_Err <- NA
         stats_all.df$RMSE <- NA
         stats_all.df$Correlation <- NA
         stats_all.df$NUM_OBS <- NA
         print(paste("Query returned no data for ",season_names[s]," ",region_names[r],". Replacing with NAs.",sep=""))
      }
      {
      if (k == 1) {
         sinfo_data.df<-data.frame(NMB=stats_all.df$Percent_Norm_Mean_Bias,NME=stats_all.df$Percent_Norm_Mean_Err,MB=stats_all.df$Mean_Bias,ME=stats_all.df$Mean_Err,RMSE=stats_all.df$RMSE,COR=stats_all.df$Correlation,NUM_OBS=stats_all.df$NUM_OBS,region=region_names[r],season=season_names[s])
      }
      else {
         sinfo_data_temp.df <- data.frame(NMB=stats_all.df$Percent_Norm_Mean_Bias,NME=stats_all.df$Percent_Norm_Mean_Err,MB=stats_all.df$Mean_Bias,ME=stats_all.df$Mean_Err,RMSE=stats_all.df$RMSE,COR=stats_all.df$Correlation,NUM_OBS=stats_all.df$NUM_OBS,region=region_names[r],season=season_names[s])
         sinfo_data.df <- rbind(sinfo_data.df,sinfo_data_temp.df)
      }
      }
      k <- k+1
   }
}

data_melted.df <- melt(sinfo_data.df,id=c("season","region"))
data_melted.df = as.data.table(data_melted.df)
data_melted.df$season = factor(data_melted.df$season, levels=c('Fall','Winter','Spring','Summer'),labels=c('Fall','Winter','Spring','Summmer'))
data_melted.df$region = factor(data_melted.df$region, levels=rev(c("Northeast","Ohio Valley","Upper Midwest","Southeast","South","NRockiesPlains","Southwest","West","Northwest")))


if ((!exists("mb_max")) || (!exists("me_min")) || (!exists("me_max")) || (!exists("rmse_min")) || (!exists("rmse_max"))) { print("Some plotting options not set, defaulting to NULL. You can specifiy mb_max, me_min, me_max, rmse_min and rmse_max in the configure file.") }
if(!exists("nmb_max")) { nmb_max <- NULL }
if(!exists("nme_max")) { nme_max <- NULL }
if(!exists("mb_max")) { mb_max <- NULL }
if(!exists("me_min")) { me_min <- NULL }
if(!exists("me_max")) { me_max <- NULL }
if(!exists("rmse_min")) { rmse_min <- NULL }
if(!exists("rmse_max")) { rmse_max <- NULL }

stats <- c("NMB","NME","MB","ME","RMSE","COR")
stat_unit <- c("%","%",units,units,units,"")
for (i in 1:6) {
   stat_in <- stats[i]
   stat_unit_in <- stat_unit[i]
   data.tmp <- data_melted.df[data_melted.df$variable == stat_in,]
   data.orig <- data_melted.df[data_melted.df$variable == stat_in,]
   if (stat_in == "NMB") {
      nmb.val <- max(abs(data.tmp$value),na.rm=T)
      nmb.max <- signif(nmb.val,1)
      nmb.min <- signif(min(abs(data.tmp$value),na.rm=T),1)
      int <- ceiling((2*nmb.max)/10)
      nmb.max <- 5*int
      if (int <= 0) { int <- 1 }
      while ((nmb.max/int) > 6) { nmb.max <- nmb.max-int }
      if (int < 1) { int <- 1 }
      if (length(nmb_max) != 0) { nmb.max <- nmb_max }
      if (length(nmb_int) != 0) { int <- nmb_int }
      data.tmp <- binval(dt=data.tmp,mn=-nmb.max,mx=nmb.max,sp=int)
      nlab     <- data.tmp[,length(levels(fac))]
      col.rng  <- rev(brewer.pal(nlab,'RdBu'))
      col.rng[ceiling(nlab/2)] <- 'grey70'
      alp <- 1
      write.table(data.tmp,file=filename_txt,row.names=F,append=F,sep=",")
      axis.max <- nmb.max
      axis.min <- -nmb.max
      text.col <- "black"
   }
   if (stat_in == "NME") {
      nme.val <- max(abs(data.tmp$value),na.rm=T)
      nme.max <- ceiling(max(data.tmp$value,na.rm=T))
      nme.min <- floor(min(data.tmp$value,na.rm=T))
      nme.range <- nme.max-nme.min
      if (nme.range < 1) { int <- ceiling(100*(signif((nme.range)/9,2)))/100 }
      if (nme.range >= 1) { int <- ceiling(10*(signif((nme.range)/9,2)))/10 }
      if (nme.range > 100) { int <- signif((nme.range)/9,1) }
      nme.max <- nme.min+(9*int)
      if (int < 1) { int <- 1 }
      if (length(nme_max) != 0) { nme.max <- nme_max }
      if (length(nme_int) != 0) { int <- nme_int }
      if (length(nme_min) != 0) { nme.min <- nme_min }
      data.tmp <- binval(dt=data.tmp,mn=nme.min,mx=nme.max,sp=int)
      nlab     <- data.tmp[,length(levels(fac))]
      col.rng  <- rev(brewer.pal(nlab,'YlOrBr'))
      if (nlab > 9) { col.rng <- c("salmon4",col.rng) }
      alp <- 1
      write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
      axis.max <- nme.max
      axis.min <- nme.min
      text.col <- "blue"
   }
   if (stat_in == "MB") {
      mb.val <- max(abs(quantile(data.tmp$value,quantile_max,na.rm=T)),abs(quantile(data.tmp$value,quantile_min,na.rm=T)),na.rm=T)
      if (mb.val < 1) { mb.max <- signif(mb.val,2) }
      if (mb.val >= 1) { mb.max <- signif(mb.val,1) }
      int <- signif((2*mb.max)/10,2)
      mb.max <- 5*int
      if (mb.max < mb.val) { mb.max <- mb.max+int }
      if (length(mb_max) != 0) { mb.max <- mb_max }
      if (length(mb_int) != 0) { int <- mb_int }
      data.tmp <- binval(dt=data.tmp,mn=-mb.max,mx=mb.max,sp=int)
      nlab     <- data.tmp[,length(levels(fac))]
      col.rng  <- rev(brewer.pal(nlab,'RdBu'))
      col.rng[ceiling(nlab/2)] <- 'grey70'
      alp <- 1
      write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
      axis.max <- mb.max
      axis.min <- -mb.max
      text.col <- "black"
   }
   if (stat_in == "ME") {
      me.max    <- (max(data.tmp$value,na.rm=T))
      me.min    <- (min(data.tmp$value,na.rm=T))
      {
         if (me.max < 1) { me.max <- ceiling(me.max*10)/10 }
         else if (me.max < 10) { me.max <- ceiling(me.max*10)/10 }
         else if (me.max < 100) { me.max <- ceiling(me.max*100)/100 }
      }
      {
         if (me.min < 1) { me.min <- floor(me.min*10)/10 }
         else if (me.min < 10) { me.min <- floor(me.min*10)/10 }
         else if (me.min < 100) { me.min <- floor(me.min*100)/100 }
      }
      if (length(me_min) != 0) { me.min <- me_min }
      if (length(me_max) != 0) { me.max <- me_max }
      me.range  <- me.max-me.min
      int <- signif((me.range/9),2)
      me.max <- me.min+(9*int)
      data.tmp  <- binval(dt=data.tmp,mn=me.min,mx=me.max,sp=int)
      nlab      <- data.tmp[,length(levels(fac))]
      col.rng   <- rev(brewer.pal(nlab,'YlOrBr'))
      if (nlab > 9) { col.rng <- c("salmon4",col.rng) } 
      alp <- 1
      write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
      axis.max <- me.max
      axis.min <- me.min
      text.col <- "blue"
   }
   if (stat_in == "RMSE") {
      rmse.max  <- (max(data.tmp$value,na.rm=T))
      rmse.min  <- (min(data.tmp$value,na.rm=T))
      {
         if (rmse.max < 1) { rmse.max <- ceiling(rmse.max*10)/10 }
         else if (rmse.max < 10) { rmse.max <- ceiling(rmse.max*10)/10 }
         else if (rmse.max < 100) { rmse.max <- ceiling(rmse.max*100)/100 }
      }
      {
         if (rmse.min < 1) { rmse.min <- floor(rmse.min*10)/10 }
         else if (rmse.min < 10) { rmse.min <- floor(rmse.min*10)/10 }
         else if (rmse.min < 100) { rmse.min <- floor(rmse.min*100)/100 }
      }
      if (length(rmse_min) != 0) { rmse.min <- rmse_min }
      if (length(rmse_max) != 0) { rmse.max <- rmse_max }
      rmse.range <- rmse.max-rmse.min
      int <- signif((rmse.range/9),2)
      rmse.max <- rmse.min+(9*int)
      data.tmp <- binval(dt=data.tmp,mn=rmse.min,mx=rmse.max,sp=int)
      nlab     <- data.tmp[,length(levels(fac))]
      col.rng  <- rev(brewer.pal(nlab,'YlOrBr'))
      if (nlab > 9) { col.rng <- c("salmon4",col.rng) }
      alp <- 0.9
      write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
      axis.max <- rmse.max
      axis.min <- rmse.min
      text.col <- "blue"
   }
   if (stat_in == "COR") {
      cor.max   <- (ceiling(10*(max(data.tmp$value,na.rm=T))))/10
      cor.min   <- (floor(10*((min(data.tmp$value,na.rm=T)))))/10
      if (length(cor_min) != 0) { cor.min <- cor_min }
      if (length(cor_max) != 0) { cor.max <- cor_max }
      cor.range <- cor.max-cor.min
      int <- signif((cor.range/8),1)
      if (length(cor_int) != 0) { int <- cor_int }
      data.tmp <- binval(dt=data.tmp,mn=cor.min,mx=cor.max,sp=int)
      nlab      <- data.tmp[,length(levels(fac))]
      col.rng   <- rev(brewer.pal(nlab,'YlOrBr'))
      alp <- 0.9
      write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
      axis.max <- cor.max
      axis.min <- cor.min
      text.col <- "black"
      stat_in  <- "Correlation"
   }
#   pdf(file=paste(filename[i],".pdf",sep=""),width=8,height=8)
   if (!exists("inc_kelly_stats")) { inc_kelly_stats <- "n" }
   data.tmp$round_value <- signif(data.tmp$value,2)
   data.orig$round_value <- signif(data.orig$value,2)
   plt <- plot_ly(data=data.tmp,x=~season,y=~region,z=~value,type="heatmap",zauto=FALSE,zmin=axis.min,zmax=axis.max,colors=col.rng,colorbar=list(title=paste(stat_in,stat_unit_in)),text=~paste(stat_in,": ",value," ",stat_unit_in,"<br>Season: ",season,"<br>Region: ",region,sep=""),hoverinfo='text') %>%
      layout(title=list(text=title,margin=list(l=0,r=0,t=0,b=200),font=list(size=25)),xaxis=list(title=list(text="Season",standoff=25),titlefont=list(size=25),tickfont=list(size=25),side="bottom"), yaxis=list(title=list(text="Region",standoff=25),titlefont=list(size=25),tickfont=list(size=20),side="left"),showlegend=TRUE,margin=list(l=300,r=200,b=150,t=100),hoverlabel=list(font=list(size=20)))
   if (inc_kelly_stats == "y") {
      plt <- plt %>% add_annotations(font=list(color=text.col,size=20),text=~value, x=~season, y=~region, showarrow=FALSE)
   }
   saveWidget(plt, file=paste(filename[i],".html",sep=""),selfcontained=T)
#   ggsave(plt,file=paste(filename[i],".pdf",sep=""),dpi=600,width=10,height=8)
#   plt

   ### Convert pdf file to png file ###
   #dev.off()
#   if ((ametptype == "png") || (ametptype == "both")) {
#      convert_command<-paste("convert -flatten -density ",png_res,"x",png_res," ",filename[i],".pdf"," png:",filename[i],".png",sep="")
#      system(convert_command)

#      if (ametptype == "png") {
#         remove_command <- paste("rm ",filename[i],".pdf",sep="")
#         system(remove_command)
#      }
#   }
}
data.tmp <- data_melted.df[data_melted.df$variable == "NUM_OBS",]
write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")

####################################

