#!/bin/csh -f
# -----------------------------------------------------------------------
# Bar plot - CMAQv5.0 
# -----------------------------------------------------------------------
# Purpose:
#
# The code is interactive with the AMET_AQ system developed by Wyat
# Appel.  Data are queried from the MYSQL database for the CSN or
# SEARCH networks.  Data are then averaged for SO4, NO3, NH4, EC, OC
# and PM2.5 for the model and ob values. These averages are then plotted 
# on a stacked bar plot, along with the percent of the total PM2.5 that 
# each species comprises.
#
# Initial version:  Wyat Appel - Dec, 2012
#
# Revised version:  Wyat Appel - 04/2025
# -----------------------------------------------------------------------

  
  #--------------------------------------------------------------------------
  # These are the main controlling variables for the R script
  
  ###  Top of AMET directory
  setenv AMETBASE       /home/AMETv16
  setenv AMET_DATABASE  amet
  setenv AMET_PROJECT   aqExample
  setenv MYSQL_CONFIG   $AMETBASE/configure/amet-config.R

  ### T/F; Set to T if the model/obs pairs are loaded in the AMET database (i.e. by setting LOAD_SITEX = T)
  setenv AMET_DB  T

  ### IF AMET_DB = F, set location of site compare output files using the environment variable OUTDIR
  #setenv OUTDIR  $AMETBASE/output/$AMET_PROJECT/sitex_output

  ### Set the project name to be used for model-to-model comparisons ###
  setenv AMET_PROJECT2  aqExample

  ### IF AMET_DB = F, set location of site compare output files using the environment variable OUTDIR
  #setenv OUTDIR2  $AMETBASE/output/$AMET_PROJECT2/sitex_output
 
  ###  Directory where figures and text output will be directed
  setenv AMET_OUT       $AMETBASE/output/$AMET_PROJECT/stacked_barplot
  
  ###  Start and End Dates of plot (YYYY-MM-DD) -- must match available dates in db or site compare files
  setenv AMET_SDATE "2018-07-01"
  setenv AMET_EDATE "2018-07-31"

  ### Process ID. This can be set to anything. It will be added to the file output name. Default is 1.
  ### The PID is particularly important if using the AMET web interface and is determined there through
  ### a random number generator.
  setenv AMET_PID 1

  ###  Custom title (if not set will autogenerate title based on variables 
  ###  and plot type)
  #  setenv AMET_TITLE "CSN PM2.5 $AMET_PROJECT $AMET_SDATE - $AMET_EDATE"
  setenv AMET_TITLE ""

  ### Species to Plot ###
  ### Acceptable Species Names: PM_TOT,PM_FRM,PM25_TOT,PM25_FRM

  setenv AMET_AQSPECIES PM_TOT

  ### Observation Network to plot
  ### Set to 'T' to process that nework
  ### NOTE: all species are not available for every network
  ### See AMET User's guide for details on each network

#> Standard North America networks
  setenv AMET_AERONET           F
  setenv AMET_AMON              F
  setenv AMET_AQS_HOURLY        F
  setenv AMET_AQS_HOURLY_VOC    F
  setenv AMET_AQS_DAILY_O3      F
  setenv AMET_AQS_DAILY         F
  setenv AMET_AQS_DAILY_VOC     F
  setenv AMET_CASTNET_WEEKLY    F
  setenv AMET_CASTNET_HOURLY    F
  setenv AMET_CASTNET_DAILY_O3  F
  setenv AMET_CASTNET_DRYDEP    F
  setenv AMET_CASTNET_DRYDEP_O3 F
  setenv AMET_CSN               F
  setenv AMET_IMPROVE           T
  setenv AMET_NADP              F
  setenv AMET_NAPS_HOURLY       F
  setenv AMET_NAPS_DAILY_O3     F

#> Non-standard networks (should probably be set to F unless specifically required)
  setenv AMET_AIRNOW            F
  setenv AMET_AIRNOW_DAILY_O3   F
  setenv AMET_AMTIC             F
  setenv AMET_CAPMoN            F
  setenv AMET_EMEP_HOURLY       F
  setenv AMET_EMEP_DAILY        F
  setenv AMET_EMEP_DAILY_O3     F
  setenv AMET_EMEP_DEP          F
  setenv AMET_FLUXNET           F
  setenv AMET_MDN               F
  setenv AMET_NOAA_ESRL_O3      F
  setenv AMET_NYCCAS            F
  setenv AMET_PURPLEAIR_DAILY   F
  setenv AMET_PURPLEAIR_HOURLY  F
  setenv AMET_SEARCH_HOURLY     F
  setenv AMET_SEARCH_DAILY      F
  setenv AMET_TOAR              F
  setenv AMET_TOAR2_HOURLY      F
  setenv AMET_TOAR2_DAILY       F
  setenv AMET_TOAR2_DAILY_O3    F

  #  Plot Type, options are "pdf", "png", or "both"
  setenv AMET_PTYPE both

  # Log File for R script
  setenv AMET_LOG stacked_barplot.log


##--------------------------------------------------------------------------##
##                Most users will not need to change below here
##--------------------------------------------------------------------------##

  ## Set the input file for this R script
  setenv AMETRINPUT $AMETBASE/scripts_analysis/$AMET_PROJECT/input_files/all_scripts.input  
  setenv AMET_NET_INPUT $AMETBASE/scripts_analysis/$AMET_PROJECT/input_files/Network.input
  
  # Check for plot and text output directory, create if not present
  if (! -d $AMET_OUT) then
     mkdir -p $AMET_OUT
  endif

  # R-script execution command
  R CMD BATCH --no-save --slave $AMETBASE/R_analysis_code/AQ_Stacked_Barplot.R $AMET_LOG
  setenv AMET_R_STATUS $status
  
  if($AMET_R_STATUS == 0) then
		echo
		echo "Statistics information"
		echo "-----------------------------------------------------------------------------------------"
		echo "Plots ----------------------->" $AMET_OUT/${AMET_PROJECT}_${AMET_PID}_stacked_barplot.$AMET_PTYPE
                echo "Data File ------------------->" $AMET_OUT/${AMET_PROJECT}_${AMET_PID}_stacked_barplot_data.csv
		echo "-----------------------------------------------------------------------------------------"
		exit 0
  else
     echo "The AMET R script did not produce any output, please check the LOGFILE $AMET_LOG for more details on the error."
     echo "Often, this indicates no data matched the specified criteria (e.g., wrong dates for project). Please check and re-run!"
  		exit 1  
  endif
