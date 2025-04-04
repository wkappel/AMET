header <- "
####################### MODEL TO OBS DENSITY SCATTERPLOT ##########################
### AMET CODE: R_Scatterplot_density_ggplot.r 
###
### This script is part of the AMET-AQ system.  This script creates a two model-to-obs
### density scatterplots, a static png plot using ggplot2 and an interactive html plot
### using ggplotly. Higher density areas of the plot are shaded differently
### from lower density areas. This script will plot a single species for a single network
### using the R ggplot and plotly packages.  
###
### Last Updated by Wyat Appel: 03/2025
####################################################################################
"

# get some environmental variables and setup some directories
ametbase        <- Sys.getenv("AMETBASE")			# base directory of AMET
ametR           <- paste(ametbase,"/R_analysis_code",sep="")    # R directory

## source miscellaneous R input file 
source(paste(ametR,"/AQ_Misc_Functions.R",sep=""))     # Miscellanous AMET R-functions file

require(ggplot2)
require(plotly)
require(htmlwidgets)

### Set file names and titles ###
if(!exists("dates")) { dates <- paste(start_date,"-",end_date) }
{
   if (custom_title == "") { title <- paste(run_name1," ",species," for ",dates,sep="") }
   else { title <- custom_title }
}

filename_pdf <- paste(run_name1,species,pid,"scatterplot_density_ggplot.pdf",sep="_")             # Set PDF filename
filename_png <- paste(run_name1,species,pid,"scatterplot_density_ggplot.png",sep="_")             # Set PNG filename
filename_txt <- paste(run_name1,species,pid,"scatterplot_density_ggplot.csv",sep="_")       # Set output file name
filename_html <- paste(run_name1,species,pid,"scatterplot_density_ggplot.html",sep="_")

## Create a full path to file
filename_pdf <- paste(figdir,filename_pdf,sep="/")      # Set PDF filename
filename_png <- paste(figdir,filename_png,sep="/")      # Set PNG filenam
filename_txt <- paste(figdir,filename_txt,sep="/")      # Set output file name
filename_html <- paste(figdir,filename_html,sep="/")

#################################

axis.max      <- NULL
axis.min      <- NULL
number_bins   <- NULL
dens_zlim     <- NULL
network <- network_names[1]

run_name 	<- run_name1
network 	<- network_names[[1]]						# Set network
{
   if (Sys.getenv("AMET_DB") == 'F') {
      sitex_info       <- read_sitex(Sys.getenv("OUTDIR"),network,run_name1,species)
      data_exists      <- sitex_info$data_exists
      if (data_exists == "y") {
         aqdat_query.df   <- sitex_info$sitex_data
         units            <- as.character(sitex_info$units[[1]])
         model_name       <- "Model"
      }
   }
   else {
      query_result    <- query_dbase(run_name1,network,species)
      aqdat_query.df  <- query_result[[1]]
      data_exists     <- query_result[[2]]
      if (data_exists == "y") { units <- query_result[[3]] }
      model_name      <- query_result[[4]]
   }
}
if (data_exists == "n") { stop("Stopping because data_exists is false. Likely no data found for query.") }
ob_col_name <- paste(species,"_ob",sep="")
mod_col_name <- paste(species,"_mod",sep="")
aqdat.df <- data.frame(Network=aqdat_query.df$network,Stat_ID=aqdat_query.df$stat_id,lat=aqdat_query.df$lat,lon=aqdat_query.df$lon,Obs_Value=round(aqdat_query.df[[ob_col_name]],5),Mod_Value=round(aqdat_query.df[[mod_col_name]],5),Month=aqdat_query.df$month)      # Create dataframe of network values to be used to create a list

## Calculate stats using all pairs, regardless of averaging
data_all.df <- data.frame(network=I(aqdat_query.df$network),stat_id=I(aqdat_query.df$stat_id),lat=aqdat_query.df$lat,lon=aqdat_query.df$lon,ob_val=aqdat_query.df[[ob_col_name]],mod_val=aqdat_query.df[[mod_col_name]])
stats.df <-try(DomainStats(data_all.df))      # Compute stats using DomainStats function for entire domain
corr        <- NULL
rmse        <- NULL
nmb         <- NULL
nme         <- NULL
mb          <- NULL
me          <- NULL
med_bias    <- NULL
med_error   <- NULL
fb          <- NULL
fe          <- NULL
nmb         <- round(stats.df$Percent_Norm_Mean_Bias,1)
nme         <- round(stats.df$Percent_Norm_Mean_Err,1)
nmdnb       <- round(stats.df$Norm_Median_Bias,1)
nmdne       <- round(stats.df$Norm_Median_Error,1)
mb          <- round(stats.df$Mean_Bias,2)
me          <- round(stats.df$Mean_Err,2)
med_bias    <- round(stats.df$Median_Bias,2)
med_error   <- round(stats.df$Median_Error,2)
fb          <- round(stats.df$Frac_Bias,2)
fe          <- round(stats.df$Frac_Err,2)
corr        <- round(stats.df$Correlation,2)
rmse        <- round(stats.df$RMSE,2)
rmse_sys    <- round(stats.df$RMSE_systematic,2)
rmse_unsys  <- round(stats.df$RMSE_unsystematic,2)
index_agr   <- round(stats.df$Index_of_Agree,2)
#########################################################


##############################
### Write Data to CSV File ###
##############################
write.table(run_name1,file=filename_txt,append=F,col.names=F,row.names=F,sep=",")
write.table(dates,file=filename_txt,append=T,col.names=F,row.names=F,sep=",")
write.table("",file=filename_txt,append=T,col.names=F,row.names=F,sep=",")
write.table(network,file=filename_txt,append=T,col.names=F,row.names=F,sep=",")
write.table(aqdat_query.df,file=filename_txt,append=T,col.names=T,row.names=F,sep=",")
###############################

#######################################################
### If user sets axis maximum, compute axis minimum ###
#######################################################
axis.max <- max(c(axis.max,quantile(aqdat.df$Obs_Value,quantile_max),quantile(aqdat.df$Mod_Value,quantile_max)))
axis.min <- min(aqdat.df$Obs_Value,aqdat.df$Mod_Value)
if ((length(y_axis_max) > 0) || (length(x_axis_max) > 0)) {
   axis.max <- max(y_axis_max,x_axis_max)
   axis.min <- axis.max * 0.035
}
if ((length(y_axis_min) > 0) || (length(x_axis_min) > 0)) {
   axis.min <- min(y_axis_min,x_axis_min)
}

dens_zlim <- 0.5 
if(length(aqdat.df$Obs_Value > 50000)) { dens_zlim <- 1 }

if (length(density_zlim) > 0) {
   dens_zlim <- density_zlim 
}
#######################################################

axis.length <- (axis.max - axis.min)
x1 <- axis.max*0.12
x2 <- axis.max*0.02
x3 <- axis.max*0.14
x4 <- axis.max*0.10
y1 <- axis.max - (axis.length * 0.890)                    # define y for labels
y2 <- axis.max - (axis.length * 0.860)                    # define y for run name
y3 <- axis.max - (axis.length * 0.920)                    # define y for network 1
y4 <- axis.max - (axis.length * 0.950)                    # define y for network 2
y5 <- axis.max - (axis.length * 0.980)                    # define y for network 3
y6 <- axis.max - (axis.length * 0.700)                    # define y for species text
y7 <- axis.max - (axis.length * 0.660)                    # define y for timescale (averaging)
y8 <- axis.max - (axis.length * 0.740)
y9 <- axis.max - (axis.length * 0.780)
y10 <- axis.max - (axis.length * 0.110)
y11 <- axis.max - (axis.length * 0.140)
y12 <- axis.max - (axis.length * 0.170)
y13 <- axis.max - (axis.length * 0.200)
y14 <- axis.max - (axis.length * 0.230)
y15 <- axis.max - (axis.length * 0.260)
y16 <- axis.max - (axis.length * 0.290)
y17 <- axis.max - (axis.length * 0.320)
y18 <- axis.max - (axis.length * 0.070)
x <- c(x1,x2,x3)
y <- c(y1,y2,y3,y4,y5,y6,y7,y8,y9,y10,y11,y12,y13,y14,y15,y16,y17,y18)  # set vector of y offsets


#########################################################
########## MAKE SCATTERPLOT: GGPLOT and PLOTLY ##########
#########################################################
y.x.lm <- lm(aqdat.df$Mod_Value~aqdat.df$Obs_Value)$coeff

options(bitmapType='cairo')

#sp <- ggplot(aqdat.df,aes(x=Obs_Value,y=Mod_Value)) + stat_density_2d(aes(fill = ..level..), geom="polygon") + scale_fill_gradient(low="blue", high="red") + geom_abline(intercept = 0, slope=1)
print(axis.max)
sp <- ggplot(aqdat.df,aes(x=Obs_Value,y=Mod_Value)) + geom_hex(bins=100) + scale_fill_gradientn(colours=c("light blue","blue","dark green","yellow","orange","red")) + geom_abline(intercept = 0, slope=1) + xlim(0,axis.max) + ylim(0,axis.max) + geom_smooth(method=lm, linetype="dashed", color="black") + labs(title=title,x=network,y=model_name) + scale_y_continuous(expand=c(0,0), limits=c(0,axis.max), breaks = pretty(c(0,axis.max), n = 10)) + scale_x_continuous(expand=c(0,0), limits=c(0,axis.max), breaks = pretty(c(0,axis.max), n = 10)) + theme(legend.justification=c(1,0), legend.position=c(0.98,0.02), legend.background=element_blank(), legend.key=element_blank(), plot.title=element_text(hjust=0.5))
p <- ggplotly(sp, width=1250, height=1250)
sp <- sp + annotate("text",0.02*(axis.max),0.97*(axis.max),label=paste("Y =",signif(y.x.lm[1],2),"+",signif(y.x.lm[2],2),"* X"),hjust=0,vjust=1,size=5)
sp <- sp + annotate("text",x[1],y[18],label=paste("(",units,")                          (%)",sep=""),hjust=.55,vjust=1,size=3)
sp <- sp + annotate("text",x[2],y[10],label=paste("r = ",sprintf("%.2f",corr),"                    NMB = ",sprintf("%.1f",nmb)),hjust=0,vjust=1,size=3)
sp <- sp + annotate("text",x[2],y[11],label=paste("RMSE = ",sprintf("%.2f",rmse),"           NME = ",sprintf("%.1f",nme)),hjust=0,vjust=1,size=3)
sp <- sp + annotate("text",x[2],y[12],label=paste("RMSE[s] = ",sprintf("%.2f",rmse_sys),"      NMdnB = ",sprintf("%.1f",nmdnb)),hjust=0,vjust=1,size=3)
sp <- sp + annotate("text",x[2],y[13],label=paste("RMSE[u] = ",sprintf("%.2f",rmse_unsys),"      NMdnE = ",sprintf("%.1f",nmdne)),hjust=0,vjust=1,size=3)
sp <- sp + annotate("text",x[2],y[14],label=paste("MB = ",sprintf("%.2f",mb),"                FB = ",sprintf("%.1f",fb)),hjust=0,vjust=1,size=3)
sp <- sp + annotate("text",x[2],y[15],label=paste("ME = ",sprintf("%.2f",me),"                FE = ",sprintf("%.1f",fe)),hjust=0,vjust=1,size=3)
sp <- sp + annotate("text",x[2],y[16],label=paste("MdnB = ",sprintf("%.2f",med_bias)),hjust=0,vjust=1,size=3)
sp <- sp + annotate("text",x[2],y[17],label=paste("MdnE = ",sprintf("%.2f",med_error)),hjust=0,vjust=1,size=3)

ggsave(filename_pdf,height=8,width=8)

### Create new y plot values for plotly version ###
y9  <- axis.max - (axis.length * 0.030)
y10 <- axis.max - (axis.length * 0.080)
y11 <- axis.max - (axis.length * 0.100)
y12 <- axis.max - (axis.length * 0.120)
y13 <- axis.max - (axis.length * 0.140)
y14 <- axis.max - (axis.length * 0.160)
y15 <- axis.max - (axis.length * 0.180)
y16 <- axis.max - (axis.length * 0.200)
y17 <- axis.max - (axis.length * 0.220)
y18 <- axis.max - (axis.length * 0.240)

p <- p %>% layout(annotations=list(xanchor="left",align="left",text=paste("Y =",signif(y.x.lm[1],2),"+",signif(y.x.lm[2],2),"* X"),x=x2,y=y9,showarrow=FALSE))
p <- p %>% layout(annotations=list(text=paste("(",units,")                          (%)",sep=""),x=x[3],y=y10,showarrow=FALSE,align="left"))
p <- p %>% layout(annotations=list(xanchor="left",align="left",text=paste("r = ",sprintf("%.2f",corr),"                    NMB = ",sprintf("%.1f",nmb)),x=x2,y=y11,showarrow=FALSE))
p <- p %>% layout(annotations=list(xanchor="left",align="left",text=paste("RMSE = ",sprintf("%.2f",rmse),"             NME = ",sprintf("%.1f",nme)),x=x2,y=y12,showarrow=FALSE))
p <- p %>% layout(annotations=list(xanchor="left",align="left",text=paste("RMSE[s] = ",sprintf("%.2f",rmse_sys),"        NMdnB = ",sprintf("%.1f",nmdnb)),x=x2,y=y13,showarrow=FALSE))
p <- p %>% layout(annotations=list(xanchor="left",align="left",text=paste("RMSE[u] = ",sprintf("%.2f",rmse_unsys),"        NMdnE = ",sprintf("%.1f",nmdne)),x=x2,y=y14,showarrow=FALSE))
p <- p %>% layout(annotations=list(xanchor="left",align="left",text=paste("MB = ",sprintf("%.2f",mb),"                FB = ",sprintf("%.1f",fb)),x=x2,y=y15,showarrow=FALSE))
p <- p %>% layout(annotations=list(xanchor="left",align="left",text=paste("ME = ",sprintf("%.2f",me),"                  FE = ",sprintf("%.1f",fe)),x=x2,y=y16,showarrow=FALSE))
p <- p %>% layout(annotations=list(xanchor="left",align="left",text=paste("MdnB = ",sprintf("%.2f",med_bias)),x=x2,y=y17,showarrow=FALSE))
p <- p %>% layout(annotations=list(xanchor="left",align="left",text=paste("MdnE = ",sprintf("%.2f",med_error)),x=x2,y=y18,showarrow=FALSE))

saveWidget(p, file=filename_html,selfcontained=T)

### Convert pdf file to png file ###
#dev.off()
if ((ametptype == "png") || (ametptype == "both")) {
   convert_command<-paste("convert -flatten -density ",png_res,"x",png_res," ",filename_pdf," png:",filename_png,sep="")
   system(convert_command)

   if (ametptype == "png") {
      remove_command <- paste("rm ",filename_pdf,sep="")
      system(remove_command)
   }
}
####################################
