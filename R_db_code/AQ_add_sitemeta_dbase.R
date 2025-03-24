#!/usr/bin/perl
##---------------------------------------------------------------
#	Surface Station Update Script 				#
#								#
#	PURPOSE: To update the surface station			#
#		database information (id,lat,lon,elev,etc)	#
#								#
#	LAST UPDATE 12/2023					#
#----------------------------------------------------------------

#amet_base <- Sys.getenv('AMETBASE')
#if (!exists("amet_base")) {
#   stop("Must set AMETBASE environment variable")
#}
obs_data_dir           <- Sys.getenv('AMET_OBS')
if (!exists("obs_data_dir")) {
   stop("Must set AMET_OBS environment variable")
}

dbase <-Sys.getenv('AMET_DATABASE')
if (!exists("dbase")) {
   stop("Must set AMET_DATABASE environment variable")
}

config_file     <- Sys.getenv("MYSQL_CONFIG")   # MySQL configuration file
if (!exists("config_file")) {
   stop("Must set MYSQL_CONFIG environment variable")
}
source(config_file)

# LOAD Required R Modules
suppressMessages(if(!require(RMySQL)){stop("Required Package RMySQL was not loaded")})
require(stringr)

## Get a couple of environment variables
obs_data_dir   <- Sys.getenv('AMET_OBS')
site_meta_data <- Sys.getenv('SITES_META_LIST')

source(site_meta_data)

args              <- commandArgs(2)
mysql_login       <- args[1]
mysql_pass        <- args[2]

### Use MySQL login/password from config file if requested ###
if (mysql_login == 'config_file') { mysql_login <- amet_login }
if (mysql_pass == 'config_file')  { mysql_pass  <- amet_pass  }
##############################################################

con   <- dbConnect(MySQL(),user=mysql_login,password=mysql_pass,dbname=dbase,host=mysql_server)
if (!exists("con")) {
   stop("Your MySQL server was not found or login or passwords incorrect, please check to see if server is running or passwords are correct.")
}

for (j in 1:length(site_file)) {											# For each network
   file_in <- paste(obs_data_dir,"/site_metadata_files/",site_file[j],sep="")
   if (file.exists(file_in)) {
      print(paste("\n\nReading site file:",file_in))
#   site_data <- read.csv(paste(amet_base,"/obs/AQ/site_files/",site_file[j],sep=""),stringsAsFactors=F,colClasses="character")
      site_data <- read.csv(file_in,stringsAsFactors=F,colClasses="character")
#   site_data <- read.csv(paste("/work/MOD3EVAL/cmaq_exp/post_data/NLCD_landuse/site_metadata_files_with_landuse/",site_file[j],sep=""),stringsAsFactors=F,colClasses="character")
      col_names <- colnames(site_data)
      if(!"state" %in% col_names)		{ site_data$state <- "NULL" }
      if(!"city" %in% col_names) 		{ site_data$city  <- "NULL" }
      if(!"county" %in% col_names) 	{ site_data$county <- "NULL" }
      if(!"country" %in% col_names)        { site_data$country <- "NULL" }
      if(!"landuse" %in% col_names) 	{ site_data$landuse <- "NULL" }
      if(!"loc_setting" %in% col_names) 	{ site_data$loc_setting <- "NULL" }
      if(!"start_date" %in% col_names) 	{ site_data$start_date <- "NULL" }
      if(!"end_date" %in% col_names) 	{ site_data$end_date <- "NULL" }
      if(!"elevation" %in% col_names) 	{ site_data$elevation <- "NULL" }
      if(!"GMT_offset" %in% col_names) 	{ site_data$GMT_offset <- "NULL" }
      if(!"near_road" %in% col_names)     { site_data$near_road <- "NULL" }
      if(!"monitor_type" %in% col_names)     { site_data$monitor_type <- "NULL" }
      if(!"co_network" %in% col_names)     { site_data$co_network <- "NULL" }
      if(!"NLCD2011.ImperviousSurface" %in% col_names)     { site_data$NLCD2011.ImperviousSurface <- "NULL" }
      if(!"NLCD2011.ImperviousSurface.Location.Setting" %in% col_names)     { site_data$NLCD2011.ImperviousSurface.Location.Setting <- "NULL" }
      if(!"NLCD2006.ImperviousSurface" %in% col_names)     { site_data$NLCD2006.ImperviousSurface <- "NULL" }
      if(!"NLCD2006.ImperviousSurface.Location.Setting" %in% col_names)     { site_data$NLCD2006.ImperviousSurface.Location.Setting <- "NULL" }
      if(!"NLCD2001.ImperviousSurface" %in% col_names)     { site_data$NLCD2001.ImperviousSurface <- "NULL" }
      if(!"NLCD2001.ImperviousSurface.Location.Setting" %in% col_names)     { site_data$NLCD2001.ImperviousSurface.Location.Setting <- "NULL" }
      if(!"daily_o3_jandec" %in% col_names) {site_data$daily_o3_jandec <- "NULL" }
      if(!"daily_o3_maysep" %in% col_names) {site_data$daily_o3_maysep <- "NULL" }
      if(!"daily_pm_mass_and_specs_jandec" %in% col_names) {site_data$daily_pm_mass_and_specs_jandec <- "NULL" }
      if(!"daily_pm_mass_only_jandec" %in% col_names) {site_data$daily_pm_mass_only_jandec <- "NULL" }
      if(!"daily_pm_specs_only_jandec" %in% col_names) {site_data$daily_pm_specs_only_jandec <- "NULL" }
      if(!"daily_voc_benz_jandec" %in% col_names) {site_data$daily_voc_benz_jandec <- "NULL" }
      if(!"daily_voc_etha_jandec" %in% col_names) {site_data$daily_voc_etha_jandec <- "NULL" }
      if(!"daily_voc_ethy_jandec" %in% col_names) {site_data$daily_voc_ethy_jandec <- "NULL" }
      if(!"daily_voc_isop_jandec" %in% col_names) {site_data$daily_voc_isop_jandec <- "NULL" }
      if(!"hourly_co_jandec" %in% col_names) {site_data$hourly_co_jandec <- "NULL" }
      if(!"hourly_etha_jandec" %in% col_names) {site_data$hourly_etha_jandec <- "NULL" }
      if(!"hourly_ethy_jandec" %in% col_names) {site_data$hourly_ethy_jandec <- "NULL" }
      if(!"hourly_isop_jandec" %in% col_names) {site_data$hourly_isop_jandec <- "NULL" }
      if(!"hourly_no_jandec" %in% col_names) {site_data$hourly_no_jandec <- "NULL" }
      if(!"hourly_no2_jandec" %in% col_names) {site_data$hourly_no2_jandec <- "NULL" }
      if(!"hourly_nox_jandec" %in% col_names) {site_data$hourly_nox_jandec <- "NULL" }
      if(!"hourly_noy_jandec" %in% col_names) {site_data$hourly_noy_jandec <- "NULL" }
      if(!"hourly_o3_jandec" %in% col_names) {site_data$hourly_o3_jandec <- "NULL" }
      if(!"hourly_pm10_jandec" %in% col_names) {site_data$hourly_pm10_jandec <- "NULL" }
      if(!"hourly_pm25_jandec" %in% col_names) {site_data$hourly_pm25_jandec <- "NULL" }
      if(!"hourly_so2_jandec" %in% col_names) {site_data$hourly_so2_jandec <- "NULL" }
      if(!"hourly_tolu_jandec" %in% col_names) {site_data$hourly_ethy_jandec <- "NULL" }

      indic.na  <- is.na(site_data)                                                  # determine which obs are missing (less than 0); 
      site_data[indic.na] <- -999                                                    # replace any missing values (which are now NAs) with -999
#      if (site_data$network == "NAPS") {
#         print(site_data$stat_id)
#      }
      for (i in 1:length(site_data$stat_id)) {
         ###################################################
         ### Set completely missing Latitude/Longitude value
         ### to 0 to prevent MySQL command from failing
         ###################################################
         if(site_data$lat[i] == "") {
            site_data$lat[i] <- 0
         }
         if(site_data$lon[i] == "") {
            site_data$lon[i] <- 0
         }
         ###################################################
         cat(paste("Inserting metadata for station ",site_data$stat_id[i]," for ",site_data$network[i]," network\n ",sep=""))					# Update user on progress
         q1 <- "REPLACE INTO site_metadata"									# Set part of the MYSQL query
         q2 <- "         (stat_id, num_stat_id, stat_name, network, monitor_type, co_network, state, city, county, country, landuse, loc_setting, start_date, end_date, lat, lon, elevation, GMT_Offset,near_road,NLCD2011_Imperv_Surf_Frac,NLCD2011_Imperv_Surf_Loc_Setting,NLCD2006_Imperv_Surf_Frac,NLCD2006_Imperv_Surf_Loc_Setting,NLCD2001_Imperv_Surf_Frac,NLCD2001_Imperv_Surf_Loc_Setting,daily_o3_jandec,daily_o3_maysep,daily_pm_mass_and_specs_jandec,daily_pm_mass_only_jandec,daily_pm_specs_only_jandec,daily_voc_benz_jandec,daily_voc_etha_jandec,daily_voc_ethy_jandec,daily_voc_isop_jandec,hourly_co_jandec,hourly_etha_jandec,hourly_ethy_jandec,hourly_isop_jandec,hourly_no_jandec,hourly_no2_jandec,hourly_nox_jandec,hourly_noy_jandec,hourly_o3_jandec,hourly_pm10_jandec,hourly_pm25_jandec,hourly_so2_jandec,hourly_tolu_jandec)"	# Set part of the MYSQL query
	 q3 <- paste(" VALUES  ('",site_data$stat_id[i],"', '",i,"', '",site_data$stat_name[i],"', '",site_data$network[i],"', '",site_data$monitor_type[i],"', '",site_data$co_network[i],"', '",site_data$state[i],"', '",site_data$city[i],"', '",site_data$county[i],"', '",site_data$country[i],"', '",site_data$landuse[i],"', '",site_data$loc_setting[i],"', '",site_data$start_date[i],"', '",site_data$end_date[i],"', ",site_data$lat[i],", ",site_data$lon[i],", ",site_data$elevation[i],", ",site_data$GMT_offset[i],", '",site_data$near_road[i],"',",site_data$NLCD2011.ImperviousSurface[i],",'",site_data$NLCD2011.ImperviousSurface.Location.Setting[i],"',",site_data$NLCD2006.ImperviousSurface[i],",'",site_data$NLCD2006.ImperviousSurface.Location.Setting[i],"',",site_data$NLCD2001.ImperviousSurface[i],",'",site_data$NLCD2001.ImperviousSurface.Location.Setting[i],"','",site_data$daily_o3_jandec[i],"','",site_data$daily_o3_maysep[i],"','",site_data$daily_pm_mass_and_specs_jandec[i],"','",site_data$daily_pm_mass_only_jandec[i],"','",site_data$daily_pm_specs_only_jandec[i],"','",site_data$daily_voc_benz_jandec[i],"','",site_data$daily_voc_etha_jandec[i],"','",site_data$daily_voc_ethy_jandec[i],"','",site_data$daily_voc_isop_jandec[i],"','",site_data$hourly_co_jandec[i],"','",site_data$hourly_etha_jandec[i],"','",site_data$hourly_ethy_jandec[i],"','",site_data$hourly_isop_jandec[i],"','",site_data$hourly_no_jandec[i],"','",site_data$hourly_no2_jandec[i],"','",site_data$hourly_nox_jandec[i],"','",site_data$hourly_noy_jandec[i],"','",site_data$hourly_o3_jandec[i],"','",site_data$hourly_pm10_jandec[i],"','",site_data$hourly_pm25_jandec[i],"','",site_data$hourly_so2_jandec[i],"','",site_data$hourly_tolu_jandec[i],"')",sep="")
         query <- paste(q1,q2,q3,sep="")											# Set the MYSQL query
         add_site_list_log <- try(dbSendQuery(con,query))									# Add the site list to the database
         if (class(add_site_list_log)=="try-error") {
            print(paste("Failed to add sites to database with the error: ",add_site_list_log,".",sep=""))
         }
      }	
   }
}
