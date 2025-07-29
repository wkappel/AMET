header <- "
################################ KELLY PLOT - REGIONS ####################################
### AMET CODE: AQ_Kellyplot_region.R 
###
### This script is part of the AMET-AQ system. It essentially creates a grid plot of model
### NMB, NME, RMSE, MB, ME and correlation for a single network/species and multiple 
### simulations. The grid is plotted with NOAA climate region on the y-axis and simulation
### on the x-axis. Each shaded box in the grid is color coded to the performance range for 
### that particular region/simulation. This particular version of the code is designed to 
### work for multiple simulations.
###
### Note that this code does not currently work without the database, as database metadata 
### are needed to identify the NOAA climate regions by State.
###
### Original concept and some code developed by Jim Kelly of EPA.  
###
### Last updated by Wyat Appel: July 2025
###########################################################################################
"

# get some environmental variables and setup some directories
ametbase        <- Sys.getenv("AMETBASE")        		# base directory of AMET
ametR           <- paste(ametbase,"/R_analysis_code",sep="")    # R directory

## source miscellaneous R input file 
source(paste(ametR,"/AQ_Misc_Functions.R",sep=""))     # Miscellanous AMET R-functions file

## Load Required R Libraries
if(!require(reshape2))          { stop("Required Package reshape2 was not loaded") 	}
if(!require(data.table))        { stop("Required Package data.table was not loaded")	}
if(!require(ggplot2))           { stop("Required Package ggplot2 was not loaded") 	}	
if(!require(RColorBrewer))      { stop("Required Package RColorBrewer was not loaded")	}
if(!require(plotly))            { stop("Required Package plotly was not loaded") 	}
if(!require(dplyr))             { stop("Required Package dplyr was not loaded") 	}
if(!require(webshot))           { stop("Required Package webshot was not loaded")       }

## Set some defaults
network 	<- network_names[1]
network_name	<- network_label[1]
num_runs 	<- length(run_names)
if(!exists("dates")) { dates <- paste(start_date,"-",end_date) }
main.title <- get_title(run_names_title=run_names[1])
if (num_runs > 1) { main.title <- get_title(run_names_title="Multiple Runs") }

################################################
## Set output names and remove existing files ##
################################################
filename_nmb    <- paste(run_name1,species,pid,"Kellyplot_region_NMB",sep="_")
filename_nme    <- paste(run_name1,species,pid,"Kellyplot_region_NME",sep="_")
filename_rmse   <- paste(run_name1,species,pid,"Kellyplot_region_RMSE",sep="_")
filename_mb     <- paste(run_name1,species,pid,"Kellyplot_region_MB",sep="_")
filename_me     <- paste(run_name1,species,pid,"Kellyplot_region_ME",sep="_")
filename_corr   <- paste(run_name1,species,pid,"Kellyplot_region_Corr",sep="_")
filename_txt    <- paste(run_name1,species,pid,"Kellyplot_stats_data_region.csv",sep="_")      # Set output file name
filename_zip    <- paste(run_name1,species,pid,"Kellyplot_region.zip",sep="_")

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

################################################

season         <- NULL
region         <- NULL
sim_labels	<- NULL
sub_title	<- paste("Sim1:",run_names[1])

### Define NOAA climate regions database queries ###
region[1] <- " and (s.state='IL' or s.state='IN' or s.state='KY' or s.state='MO' or s.state='OH' or s.state='TN' or s.state='WV')"
region[2] <- " and (s.state='IA' or s.state='MI' or s.state='MN' or s.state='WI')"
region[3] <- " and (s.state='CT' or s.state='DE' or s.state='ME' or s.state='MD' or s.state='MA' or s.state='NH' or s.state='NJ' or s.state='NY' or s.state='PA' or s.state='RI' or s.state='VT')"
region[4] <- " and (s.state='ID' or s.state='OR' or s.state='WA')"
region[5] <- " and (s.state='AR' or s.state='KS' or s.state='LA' or s.state='MS' or s.state='OK' or s.state='TX')"
region[6] <- " and (s.state='AL' or s.state='FL' or s.state='GA' or s.state='SC' or s.state='NC' or s.state='VA')"
region[7] <- " and (s.state='AZ' or s.state='CO' or s.state='NM' or s.state='UT')"
region[8] <- " and (s.state='CA' or s.state='NV')"
region[9] <- " and (s.state='MT' or s.state='NE' or s.state='ND' or s.state='SD' or s.state='WY')"

### NOAA climate region names ###
region_names <- c("Ohio Valley","Upper Midwest","Northeast","Northwest","South","Southeast","Southwest","West","NRockiesPlains")
k <- 1

### Categorize each state into a climate region ###
state2region <- data.frame(state=c("IL","IN","KY","MO","OH","TN","WV","IA","MI","MN","WI","CT","DE","ME","MD","MA","NH","NJ","NY","PA","RI","VT","ID","OR","WA","AR","KS","LA","MS","OK","TX","AL","FL","GA","SC","NC","VA","AZ","CO","NM","UT","CA","NV","MT","NE","ND","SD","WY"),reg=c("Ohio Valley","Ohio Valley","Ohio Valley","Ohio Valley","Ohio Valley","Ohio Valley","Ohio Valley","Upper Midwest","Upper Midwest","Upper Midwest","Upper Midwest","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northeast","Northwest","Northwest","Northwest","South","South","South","South","South","South","Southeast","Southeast","Southeast","Southeast","Southeast","Southeast","Southwest","Southwest","Southwest","Southwest","West","West","NRockiesPlains","NRockiesPlains","NRockiesPlains","NRockiesPlains","NRockiesPlains"))

### Categorize each month into a season ###
month2season <- data.frame(month=c(1,2,3,4,5,6,7,8,9,10,11,12),season = c("Winter","Winter","Spring","Spring","Spring","Summer","Summer","Summer","Fall","Fall","Fall","Winter"))
for (s in 1:length(run_names)) {
   run_name <- run_names[s]
   query_result   <- query_dbase(run_name,network,species)
   aqdat_query.df <- query_result[[1]]
   data_exists    <- query_result[[2]]
   units          <- query_result[[3]]
   model_name     <- query_result[[4]] 

   if (data_exists == "n") {
      num_runs <- (num_runs-1)
      if (num_runs == 0) { stop("Stopping because num_runs is zero. Likely no data found for query.") }
   }

   ob_col_name <- paste(species,"_ob",sep="")
   mod_col_name <- paste(species,"_mod",sep="")
   aqdat.df <- data.frame(Network=I(aqdat_query.df$network),Stat_ID=I(aqdat_query.df$stat_id),lat=aqdat_query.df$lat,lon=aqdat_query.df$lon,month=aqdat_query.df$month,state=aqdat_query.df$state,Obs_Value=aqdat_query.df[[ob_col_name]],Mod_Value=aqdat_query.df[[mod_col_name]])
   aqdat.df$region <- state2region$reg[match(aqdat.df$state,state2region$state)]
   aqdat.df$region <- factor(aqdat.df$region, levels=c("Ohio Valley","Upper Midwest","Northeast","Northwest","South","Southeast","Southwest","West","NRockiesPlains"))

   for (r in 1:length(region_names)) {
      aqdat_sub.df <- subset(aqdat.df,aqdat.df$region == region_names[r])
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
         print(paste("Query returned no data for the",region_names[r]," region. Replacing with NAs.",sep=""))
      }
      {
         if (k == 1) {
            sinfo_data.df<-data.frame(NMB=stats_all.df$Percent_Norm_Mean_Bias,NME=stats_all.df$Percent_Norm_Mean_Err,MB=stats_all.df$Mean_Bias,ME=stats_all.df$Mean_Err,RMSE=stats_all.df$RMSE,COR=stats_all.df$Correlation,NUM_OBS=stats_all.df$NUM_OBS,region=region_names[r],simulation=run_names[s])
         }
         else {
            sinfo_data_temp.df <- data.frame(NMB=stats_all.df$Percent_Norm_Mean_Bias,NME=stats_all.df$Percent_Norm_Mean_Err,MB=stats_all.df$Mean_Bias,ME=stats_all.df$Mean_Err,RMSE=stats_all.df$RMSE,COR=stats_all.df$Correlation,NUM_OBS=stats_all.df$NUM_OBS,region=region_names[r],simulation=run_names[s])
            sinfo_data.df <- rbind(sinfo_data.df,sinfo_data_temp.df)
         }
      }
      k <- k+1
   }
   sim_labels <- c(sim_labels,paste("Sim",s,sep=""))
   if (s > 1) { sub_title <- paste(sub_title,"\n","Sim",s,": ",run_names[s],sep="") }
}

sinfo_data.df$simulation <- factor(sinfo_data.df$simulation, levels=run_names)

data_melted.df <- melt(sinfo_data.df,id=c("simulation","region"))
data_melted.df = as.data.table(data_melted.df)
data_melted.df$simulation = factor(data_melted.df$simulation, levels=rev(run_names),labels=rev(run_names))
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
      if (length(nmb_max) != 0) { nmb.max <- nmb_max }
      col.rng <- colorRampPalette(rev(brewer.pal(11, "RdBu")))(100)
      write.table(data.tmp,file=filename_txt,row.names=F,append=F,sep=",")
      axis.max <- nmb.max
      axis.min <- -nmb.max
      text.col <- "black"
   }
   if (stat_in == "NME") {
      nme.max <- max(data.tmp$value,na.rm=T)
      nme.min <- min(data.tmp$value,na.rm=T)
      if (length(nme_max) != 0) { nme.max <- nme_max }
      if (length(nme_min) != 0) { nme.min <- nme_min }
      col.rng <- colorRampPalette(brewer.pal(11, "YlOrBr"))(100)
      write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
      axis.max <- nme.max
      axis.min <- nme.min
      text.col <- "blue"
   }
   if (stat_in == "MB") {
      mb.max <- max(abs(quantile(data.tmp$value,quantile_max,na.rm=T)),abs(quantile(data.tmp$value,quantile_min,na.rm=T)),na.rm=T)
      if (length(mb_max) != 0) { mb.max <- mb_max }
      col.rng <- colorRampPalette(rev(brewer.pal(11, "RdBu")))(100)
      write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
      axis.max <- mb.max
      axis.min <- -mb.max
      text.col <- "black"
   }
   if (stat_in == "ME") {
      me.max    <- (max(data.tmp$value,na.rm=T))
      me.min    <- (min(data.tmp$value,na.rm=T))
      if (length(me_max) != 0) { me.max <- me_max }
      if (length(me_min) != 0) { me.min <- me_min }
      col.rng <- colorRampPalette(brewer.pal(11, "YlOrBr"))(100)
      write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
      axis.max <- me.max
      axis.min <- me.min
      text.col <- "blue"
   }
   if (stat_in == "RMSE") {
      rmse.max  <- (max(data.tmp$value,na.rm=T))
      rmse.min  <- (min(data.tmp$value,na.rm=T))
      if (length(rmse_min) != 0) { rmse.min <- rmse_min }
      if (length(rmse_max) != 0) { rmse.max <- rmse_max }
      col.rng <- colorRampPalette(brewer.pal(11, "YlOrBr"))(100)
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
      col.rng <- colorRampPalette(brewer.pal(11, "YlOrBr"))(100)
      write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
      axis.max <- cor.max
      axis.min <- cor.min
      text.col <- "black"
      stat_in <- "Correlation"
   }
   if (!exists("inc_kelly_stats")) { inc_kelly_stats <- "n" }
   data.tmp$round_value <- signif(data.tmp$value,3)
   data.orig$round_value <- signif(data.orig$value,3)

   plt <- plot_ly(data=data.tmp,x=~region,y=~simulation,z=~round_value,type="heatmap",zauto=FALSE,zmin=axis.min,zmax=axis.max,colors=col.rng,colorbar=list(title=paste(stat_in,stat_unit_in)),text=~paste(stat_in,": ",value," ",stat_unit_in,"<br>Simulation: ",simulation,"<br>Region: ",region,sep=""),hoverinfo='text') %>%
   layout(title=list(text=main.title,margin=list(l=0,r=0,t=0,b=200),font=list(size=25)),xaxis=list(title=list(text="Region",standoff=25),titlefont=list(size=25),tickfont=list(size=25),side="bottom"), yaxis=list(title=list(text="Simulation",standoff=25),titlefont=list(size=25),tickfont=list(size=20),side="left"),showlegend=TRUE,margin=list(l=400,r=200,b=150,t=100),hoverlabel=list(font=list(size=20)))
   if (inc_kelly_stats == "y") {
      plt <- plt %>% add_annotations(font=list(color=text.col,size=20),text=~round_value, x=~region, y=~simulation, showarrow=FALSE)
   }
   filename_out <- paste(filename[i],".html",sep="")
   saveWidget(plt, file=filename_out,selfcontained=T)
   if (png_from_html == "y") { plotly_IMAGE(plt, out_file=paste(filename[i],".png",sep=""), width = 2400, height = 1600, format="png") }
}
data.tmp <- data_melted.df[data_melted.df$variable == "NUM_OBS",]
write.table(data.tmp,file=filename_txt,row.names=F,col.names=F,append=T,sep=",")
####################################

