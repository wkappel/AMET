header <- "
###################################### SPATIAL PLOT ######################################
### AMET CODE: AQ_Plot_Spatial.R 
###
### This code is part of the AMET-AQ system.  The Plot Spatial code takes a MYSQL database
### query for a single species from one or more networks and plots the observation value, 
### model value, and difference between the model and ob for each site for each corresponding
### network.  Mutiple values for a site are averaged to a single value for plotting purposes.
### The map area plotted is dynamically generated from the input data.   
###
### Last modified by Wyat Appel: Feb 2022
##########################################################################################
"
## get some environmental variables and setup some directories
ametbase	<- Sys.getenv("AMETBASE")			# base directory of AMET
ametR		<- paste(ametbase,"/R_analysis_code",sep="")    # R directory

## source miscellaneous R input file 
source(paste(ametR,"/AQ_Misc_Functions.R",sep=""))     # Miscellanous AMET R-functions file

## Load Required Libraries 
if(!require(maps)){stop("Required Package maps was not loaded")}
if(!require(mapdata)){stop("Required Package mapdata was not loaded")}
library(ggplot2)
library(plotly)
library(gganimate)

if(!exists("quantile_min")) { quantile_min <- 0.001 }
if(!exists("quantile_max")) { quantile_max <- 0.950 }
if(!exists("near_zero_color")) { near_zero_color <- "grey50" }

### Retrieve units label from database table ###
network		<- network_names[1] # When using mutiple networks, units from network 1 will be used
#units_qs	<- paste("SELECT ",species," from project_units where proj_code = '",run_name1,"' and network = '",network,"'", sep="") # Create MYSQL query from units table
################################################

### Set file names and titles ###
filename_obs	<- paste(run_name1,species,pid,"spatialplot_obs.pdf",sep="_")           # Filename for obs spatial plot
filename_mod	<- paste(run_name1,species,pid,"spatialplot_mod.pdf",sep="_")           # Filename for model spatial plot
filename_diff	<- paste(run_name1,species,pid,"spatialplot_diff.pdf",sep="_")          # Filename for diff spatial plot
filename_anim	<- paste(run_name1,species,pid,"spatialplot.html",sep="_")         # Filename for diff spatial plot

filename_obs_anim    <- paste(run_name1,species,pid,"spatialplot_obs.html",sep="_")           # Filename for obs spatial plot
filename_mod_anim    <- paste(run_name1,species,pid,"spatialplot_mod.html",sep="_")           # Filename for model spatial plot
filename_diff_anim   <- paste(run_name1,species,pid,"spatialplot_diff.html",sep="_")          # Filename for diff spatial plot

if(!exists("dates")) { dates <- paste(start_date,"-",end_date) }
{
   if (custom_title == "") { title <- paste(run_name1,species,"for",network_label[1],"for",dates,sep=" ") }
   else { title <- custom_title }
}

## Create a full path to file
filename_obs      <- paste(figdir,filename_obs,sep="/")           # Filename for obs spatial plot
filename_mod      <- paste(figdir,filename_mod,sep="/")           # Filename for model spatial plot
filename_diff     <- paste(figdir,filename_diff,sep="/")          # Filename for diff spatial plot

filename_obs_anim      <- paste(figdir,filename_obs_anim,sep="/")           # Filename for obs spatial plot
filename_mod_anim      <- paste(figdir,filename_mod_anim,sep="/")           # Filename for model spatial plot
filename_diff_anim     <- paste(figdir,filename_diff_anim,sep="/")          # Filename for diff spatial plot

########################################
### Set NULL values and plot symbols ###
########################################
sinfo_obs       <- NULL						# Set list for obs values to NULL
sinfo_mod       <- NULL						# Set list for model values to NULL
sinfo_diff      <- NULL						# Set list for difference values to NULL
sinfo_rat	<- NULL
sinfo_obs_data  <- NULL
sinfo_mod_data  <- NULL
sinfo_diff_data <- NULL
sinfo_rat_data  <- NULL
sinfo_obs_anim  <- NULL                                         # Set list for obs values to NULL
sinfo_mod_anim  <- NULL                                         # Set list for model values to NULL
sinfo_diff_anim <- NULL                                         # Set list for difference values to NULL
sinfo_obs_data_anim  <- NULL
sinfo_mod_data_anim  <- NULL
sinfo_diff_data_anim <- NULL
diff_min        <- NULL
all_lats        <- NULL
all_lons        <- NULL
all_obs         <- NULL
all_mod         <- NULL
all_diff        <- NULL
all_rat	   	<- NULL
bounds          <- NULL						# Set map bounds to NULL
sub_title       <- NULL						# Set sub title to NULL
lev_lab         <- NULL
legend_names    <- NULL
legend_chars    <- NULL
plot.symbols<-as.integer(plot_symbols)
pick.symbol.name.fun<-function(x){
   master.symbol.df<-data.frame(plot.symbols=c(16,17,15,18,8,11,4),names=c("CIRCLE","TRIANGLE","SQUARE","DIAMOND","BURST","STAR","X"))
   as.character(master.symbol.df$names[x==master.symbol.df$plot.symbols])
}
pick.symbol2.fun<-function(x){
   master.symbol2.df<-data.frame(plot.symbols=c(16,17,15,18,8,11,4),plot.symbols2=c(1,2,0,5,8,11,4))
   as.integer(master.symbol2.df$plot.symbols2[x==master.symbol2.df$plot.symbols])
}
symbols<-apply(matrix(plot.symbols),1,pick.symbol.name.fun)
spch2 <- apply(matrix(plot.symbols),1,pick.symbol2.fun)
spch<-plot.symbols
########################################

rm_negs <- remove_negatives
remove_negatives <- 'n'      # Set remove negatives to false. Negatives are needed in the coverage calculation and will be removed automatically by Average
total_networks <- length(network_names)
k <- 1
for (j in 1:total_networks) {							# Loop through for each network
   Mod_Obs_Diff   <- NULL							# Set model/ob difference to NULL
   network        <- network_names[[j]]						# Determine network name from loop value
   network_number <- k 
   #########################
   ## Query the database ###
   #########################
   {
      if (Sys.getenv("AMET_DB") == 'F') {
         sitex_info       <- read_sitex(Sys.getenv("OUTDIR"),network,run_name1,species)
         data_exists      <- sitex_info$data_exists
         if (data_exists == "y") {
            aqdat_query.df   <- sitex_info$sitex_data
            aqdat_query.df   <- aqdat_query.df[with(aqdat_query.df,order(network,stat_id)),]
            units            <- as.character(sitex_info$units[[1]])
         }
      }
      else {
         query_result   <- query_dbase(run_name1,network,species)
         aqdat_query.df <- query_result[[1]]
         data_exists    <- query_result[[2]]
         if (data_exists == "y") { units <- query_result[[3]] }
      }

   }
   #######################

#   count <- sum(is.na(aqdat_query.df[,9]))
#   len   <- length(aqdat_query.df[,9])

#   if (count != len) {	# Continue if query returned non-missing data

   { 
      if (data_exists == "n") {
         total_networks <- (total_networks-1)
         sub_title<-paste(sub_title,network_label[j],"=No Data; ",sep="")      # Set subtitle based on network matched with the appropriate symbol
         if (total_networks == 0) { stop("Stopping because total_networks is zero. Likely no data found for query.") }
      }
      else {
         ####################################
         ## Compute Averages for Each Site ##
         ####################################
         legend_names <<- c(legend_names,network_label[j])
         legend_chars <<- c(legend_chars,spch[k])
         if (averaging == "n") { averaging <- "e" }
         ob_col_name <- paste(species,"_ob",sep="")
         mod_col_name <- paste(species,"_mod",sep="")
         aqdat_in.df <- data.frame(Network=I(aqdat_query.df$network),Stat_ID=I(aqdat_query.df$stat_id),lat=aqdat_query.df$lat,lon=aqdat_query.df$lon,Obs_Value=round(aqdat_query.df[[ob_col_name]],5),Mod_Value=round(aqdat_query.df[[mod_col_name]],5),Hour=aqdat_query.df$ob_hour,Start_Date=aqdat_query.df$ob_dates,Month=aqdat_query.df$month)
         if ((network == "NADP") || (network == "AMON")) {
            aqdat_in.df$precip_ob <- aqdat_query.df$precip_ob
            aqdat_in.df$precip_mod <- aqdat_query.df$precip_mod
         }
         aqdat_anim.df <- aqdat_in.df
	 aqdat.df <- Average(aqdat_in.df)
         ## Remove missing and zero concentration observations from dataset ##
         if ((rm_negs == "T") || (rm_negs == "t") || (rm_negs == "Y") || (rm_negs == "y")) {
            indic.nonzero <- aqdat_anim.df$Obs_Value >= 0
            aqdat_anim.df <- aqdat_anim.df[indic.nonzero,]
            indic.nonzero <- aqdat_anim.df$Mod_Value >= 0
            aqdat_anim.df <- aqdat_anim.df[indic.nonzero,]
         }
         ##############################################

	 Mod_Obs_Diff <- aqdat.df$Mod_Value-aqdat.df$Obs_Value
         Mod_Obs_Rat  <- aqdat.df$Mod_Value/aqdat.df$Obs_Value
         aqdat.df$Mod_Obs_Diff <- Mod_Obs_Diff
         aqdat.df$Mod_Obs_Rat  <- Mod_Obs_Rat
         ####################################

         ##################################################
         ## Store values for each network in array lists ##
         ##################################################
         sinfo_obs_data[[k]]<-list(lat=aqdat.df$lat,lon=aqdat.df$lon,plotval=aqdat.df$Obs_Value,date=aqdat.df$Start_Date,network=network)
         sinfo_mod_data[[k]]<-list(lat=aqdat.df$lat,lon=aqdat.df$lon,plotval=aqdat.df$Mod_Value,date=aqdat.df$Start_Date,network=network)
         sinfo_diff_data[[k]]<-list(lat=aqdat.df$lat,lon=aqdat.df$lon,plotval=aqdat.df$Mod_Obs_Diff,date=aqdat.df$Start_Date,network=network)
         sinfo_rat_data[[k]]<-list(lat=aqdat.df$lat,lon=aqdat.df$lon,plotval=aqdat.df$Mod_Obs_Rat,date=aqdat.df$Start_Date,network=network)

	 Mod_Obs_Diff <- aqdat_anim.df$Mod_Value-aqdat_anim.df$Obs_Value
         aqdat_anim.df$Mod_Obs_Diff <- Mod_Obs_Diff
         ####################################

         ##################################################
         ## Store values for each network in array lists ##
         ##################################################
#         if (k == 1) {
   	    sinfo_obs_data_anim[[k]]	<-list(lat=aqdat_anim.df$lat,lon=aqdat_anim.df$lon,plotval=aqdat_anim.df$Obs_Value,date=aqdat_anim.df$Start_Date,network=network)
            sinfo_mod_data_anim[[k]]	<-list(lat=aqdat_anim.df$lat,lon=aqdat_anim.df$lon,plotval=aqdat_anim.df$Mod_Value,date=aqdat_anim.df$Start_Date,network=network)
            sinfo_diff_data_anim[[k]]	<-list(lat=aqdat_anim.df$lat,lon=aqdat_anim.df$lon,plotval=aqdat_anim.df$Mod_Obs_Diff,date=aqdat_anim.df$Start_Date,network=network)
#	 }
#	 if (k > 1) {
#	    sinfo_obs_data_anim_tmp.df      <-data.frame(lat=aqdat_anim.df$lat,lon=aqdat_anim.df$lon,plotval=aqdat_anim.df$Obs_Value,date=aqdat_anim.df$Start_Date,network=network_number)
#            sinfo_mod_data_anim_tmp.df      <-data.frame(lat=aqdat_anim.df$lat,lon=aqdat_anim.df$lon,plotval=aqdat_anim.df$Mod_Value,date=aqdat_anim.df$Start_Date,network=network_number)
#            sinfo_diff_data_anim_tmp.df     <-data.frame(lat=aqdat_anim.df$lat,lon=aqdat_anim.df$lon,plotval=aqdat_anim.df$Mod_Obs_Diff,date=aqdat_anim.df$Start_Date,network=network_number)
#	    sinfo_obs_data_anim.df 	    <-rbind(sinfo_obs_data_anim.df,sinfo_obs_data_anim_tmp.df)
#	    sinfo_mod_data_anim.df          <-rbind(sinfo_mod_data_anim.df,sinfo_mod_data_anim_tmp.df)
#	    sinfo_diff_data_anim.df         <-rbind(sinfo_diff_data_anim.df,sinfo_diff_data_anim_tmp.df)
#	 }
         all_lats <- c(all_lats,aqdat.df$lat)
         all_lons <- c(all_lons,aqdat.df$lon)
         all_obs  <- c(all_obs,aqdat.df$Obs_Value)
         all_mod  <- c(all_mod,aqdat.df$Mod_Value)
         all_diff <- c(all_diff,aqdat.df$Mod_Obs_Diff)
         all_rat  <- c(all_rat,aqdat.df$Mod_Obs_Rat)
         ##################################################
#         sub_title<-paste(sub_title,symbols[k],"=",network_label[j],"; ",sep="")      # Set subtitle based on network matched with the appropriate symbol
         k <- k+1
      }
   }
}
#########################
## plot format options ##
#########################
bounds<-c(min(all_lats,bounds[1]),max(all_lats,bounds[2]),min(all_lons,bounds[3]),max(all_lons,bounds[4]))
plotsize<-1.50									# Set plot size
symb<-15										# Set symbol character
symbsiz<-1.1										# Set symbol size
if (length(unique(aqdat_in.df$Stat_ID)) > 3000) {
   symbsiz <- 0.9
}
if (length(unique(aqdat_in.df$Stat_ID)) > 10000) {
   symbsiz <- 0.7
}
#########################

####################################################################
### Determine intervals  to use for plotting ob and model values ###
####################################################################
levs <- NULL
if (length(num_ints) == 0) {
   num_ints <- 20
}
intervals <- num_ints
{
   if ((length(abs_range_min) == 0) || (length(abs_range_max) == 0)) {
      all_data <- c(all_obs,all_mod)
      levs <- pretty(c(0,quantile(all_data,quantile_max)),intervals,min.n=5)
   }
   else {
      levs <- pretty(c(abs_range_min,abs_range_max),intervals,min.n=5)
   }
}

#levs_interval		<- (max(levs)-min(levs))/(length(levs)-1)
#length_levs		<- length(levs)
#levs_legend		<- c(levs,max(levs)+levs_interval)
#leg_labels		<- levs
#lev_lab 		<- levs
#levs_max		<- length(levs)
#leg_labels[levs_max]	<- paste("> ",max(levs),sep="")
#leg_labels		<- c(leg_labels,"")
#levs[levs_max+1] 	<- 10000		# set the level maximum to 1000 in order to include all values
#colors 			<- NULL
#colors			<- all_colors(levs_max)
#leg_colors		<- colors
###########################################################################



#################################################
### Determine Color Scale for Difference Plot ###
#################################################
intervals <- num_ints
{
   if ((length(diff_range_min) == 0) || (length(diff_range_max) == 0)) {
      diff_max <- max(quantile(abs(all_diff),quantile_max))
      levs_diff <- pretty(c(-diff_max,diff_max),intervals,min.n=5)
      diff_range <- range(levs_diff)
      power <- abs(levs_diff[1]) - abs(levs_diff[2])
      if (abs(diff_range[1]) > diff_range[2]) {
         diff_range[2] <- abs(diff_range[1])
      }
      else {
         diff_range[1] <- -diff_range[2]
      }
   }
   else {
      levs_diff <- pretty(c(diff_range_min,diff_range_max),intervals,min.n=5)
      power <- abs(levs_diff[1]) - abs(levs_diff[2])
      diff_range <- range(levs_diff)
   }
   levs_diff <- signif(round(seq(diff_range[1],diff_range[2],power),5),2)
}
#####################################################################

for (k in 1:total_networks) {

   sinfo_obs[[k]]<-list(lat=sinfo_obs_data[[k]]$lat,lon=sinfo_obs_data[[k]]$lon,plotval=sinfo_obs_data[[k]]$plotval)			# Create list to be used with PlotSpatial function
   sinfo_mod[[k]]<-list(lat=sinfo_mod_data[[k]]$lat,lon=sinfo_mod_data[[k]]$lon,plotval=sinfo_mod_data[[k]]$plotval)			# Create model list to be used with PlotSpatial fuction
   sinfo_diff[[k]]<-list(lat=sinfo_diff_data[[k]]$lat,lon=sinfo_diff_data[[k]]$lon,plotval=sinfo_diff_data[[k]]$plotval)	# Create diff list to be used with PlotSpatial fuction

   sinfo_obs_anim[[k]]	<- list(lat=sinfo_obs_data_anim[[k]]$lat,lon=sinfo_obs_data_anim[[k]]$lon,plotval=sinfo_obs_data_anim[[k]]$plotval,date=sinfo_obs_data_anim[[k]]$date,network=sinfo_obs_data_anim[[k]]$network)
   sinfo_mod_anim[[k]]	<- list(lat=sinfo_mod_data_anim[[k]]$lat,lon=sinfo_mod_data_anim[[k]]$lon,plotval=sinfo_mod_data_anim[[k]]$plotval,date=sinfo_mod_data_anim[[k]]$date,network=sinfo_mod_data_anim[[k]]$network)
   sinfo_diff_anim[[k]]	<- list(lat=sinfo_diff_data_anim[[k]]$lat,lon=sinfo_diff_data_anim[[k]]$lon,plotval=sinfo_diff_data_anim[[k]]$plotval,date=sinfo_diff_data_anim[[k]]$date,network=sinfo_diff_data_anim[[k]]$network)
}

###########################
### plot text options   ###
###########################
{
   if (custom_title == "") {
      title_obs<-paste("Observed ",species, " for run ",run_name1," for ", dates,sep="")			# Title for obs spatial plot
      title_mod<-paste("Modeled ",species, " for run ",run_name1," for ", dates,sep="")				# Title for model spatial plot
      title_diff<-paste("Modeled - Observed ",species, " for run ",run_name1," for ", dates,sep="")		# Title for diff spatial plot
      title_rat<-paste("Modeled / Observed ",species, " for run ",run_name1," for ", dates,sep="")             # Title for diff spatial plot
   }
   else {
      title_obs  <- custom_title
      title_mod  <- custom_title
      title_diff <- custom_title
      title_rat <- custom_title
   }
}
###########################

##############################################
## Create PNG and PDF plots for NMB and NME ##
##############################################

for (i in 1:3) {
   if (i == 1) { 
      sinfo 		<- sinfo_obs
      sinfo_anim 	<- sinfo_obs_anim
      plot_range_min 	<- min(levs)
      plot_range_max 	<- max(levs)
      filename_ggplot 	<- filename_obs
      filename_anim	<- filename_obs_anim
      color_palette 	<- c("purple","violet","blue","green","yellow","orange","red","dark red") 
      color_direction 	<- -1
   }
   if (i == 2) { 
      sinfo 		<- sinfo_mod
      sinfo_anim 	<- sinfo_mod_anim
      plot_range_min 	<- min(levs)
      plot_range_max 	<- max(levs)
      filename_ggplot 	<- filename_mod 
      filename_anim	<- filename_mod_anim
      color_palette 	<- c("purple","violet","blue","green","yellow","orange","red","dark red")
      color_direction 	<- -1
   }
   if (i == 3) { 
      sinfo 		<- sinfo_diff
      sinfo_anim 	<- sinfo_diff_anim
      plot_range_min 	<- -diff_max
      plot_range_max 	<- diff_max
      filename_ggplot	<- filename_diff
      filename_anim	<- filename_diff_anim
      color_palette 	<- c("dark red","red","orange","yellow","white","green","blue","violet","purple")
      color_direction 	<- 1
   } 
#   filename_ggplot <- paste(figure,"_new.pdf",sep="")
   for (k in 1:total_networks) {
      library(sf)
      library(maps)
      us <- map_data("state")
      us2 <- st_as_sf(us,coords=c("long","lat"))
      plot_data <- data.frame(lat=sinfo[[k]]$lat,lon=sinfo[[k]]$lon,plotval=sinfo[[k]]$plotval)
      if (k == 1) {
         sp <- ggplot(data=us2) +
#         geom_sf() +
         geom_polygon(data=us, aes(x=long, y=lat, group=group), color="darkblue", fill="white", linewidth = .1 ) +
         geom_point(data = plot_data, shape=spch[k], aes(x=lon, y=lat, col = plotval),size=4) +
         geom_point(data = plot_data, shape=spch2[k] ,size=4,color="black",aes(x=lon,y=lat)) + 
#         scale_color_distiller(palette=color_palette,direction=color_direction,limits=c(plot_range_min,plot_range_max)) +
         theme(axis.text=element_text(size=10), legend.text=element_text(size=15), legend.key.size = unit(1.3,"cm")) +
         xlab('Longitude') + ylab('Latitude')
         sp_anim <- ggplot(data=us2) +
         geom_polygon(data=us, aes(x=long, y=lat, group=group), color="darkblue", fill="white", linewidth = .1 ) +
         geom_point(data = plot_data, shape=spch[k], aes(x=lon, y=lat, col = plotval, frame=date),size=4) +
         geom_point(data = plot_data, shape=spch2[k] ,size=4,color="black",aes(x=lon,y=lat)) +
#         scale_color_distiller(palette=color_palette,direction=color_direction,limits=c(plot_range_min,plot_range_max)) +
#	 scale_color_gradientn(colors=c(color_palette),limits=c(plot_range_min,plot_range_max)) +
         theme(axis.text=element_text(size=10), legend.text=element_text(size=15), legend.key.size = unit(1.3,"cm")) +
         xlab('Longitude') + ylab('Latitude')
         if (i < 3) {
            sp <- sp + scale_color_gradientn(colors=color_palette,limits=c(plot_range_min,plot_range_max))
         }
         if (i == 3) {
            sp <- sp + scale_color_gradientn(colors=color_palette,limits=c(plot_range_min,plot_range_max))
         }
      }
      else {
          sp <- sp +
          geom_point(data = plot_data, shape=spch[k], aes(lon, lat, col = plotval),size=4) +
          geom_point(data = plot_data, shape=spch2[k], size=4,color="black",aes(x=lon,y=lat))
      }
   }
   ggsave(filename=filename_ggplot,width=16,height=9)
   for (k in 1:total_networks) {
      plot_data_anim <- data.frame(lat=sinfo_anim[[k]]$lat,lon=sinfo_anim[[k]]$lon,plotval=sinfo_anim[[k]]$plotval,date=sinfo_anim[[k]]$date)
      if (k == 1) {
         sp_anim <- ggplot(data=us2) +
         geom_polygon(data=us, aes(x=long, y=lat, group=group), color="darkblue", fill="white", linewidth = .1 ) +
         geom_point(data = plot_data_anim, shape=spch[k], aes(x=lon, y=lat, col = plotval, frame=(date), group=date), size=5) +
         geom_point(data = plot_data_anim, shape=spch2[k] ,size=5,color="black",aes(x=lon,y=lat,frame=(date), group=date)) +
         scale_color_gradientn(colors=color_palette,limits=c(plot_range_min,plot_range_max)) +
         theme(axis.text=element_text(size=10), legend.text=element_text(size=15), legend.key.size = unit(1.3,"cm")) +
         xlab('Longitude') + ylab('Latitude') + labs(title=title,color=paste(species,"(",units,")"))
      }
      else {
         sp_anim <- sp_anim +
         geom_point(data = plot_data_anim, shape=spch[k], aes(x=lon, y=lat, col = plotval, frame=(date), group=date), size=5) +
         geom_point(data = plot_data_anim, shape=spch2[k] ,size=5,color="black",aes(x=lon,y=lat,frame=(date), group=date))
      }
      fig <- ggplotly(sp_anim) %>% animation_opts(transition=0,easing="elastic",redraw=FALSE)
      saveWidget(fig, file=filename_anim,selfcontained=T)
   }
}

#########################################   
