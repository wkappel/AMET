#!/bin/csh -f
# -----------------------------------------------------------------------
# Monthly Statistics Plot 
# -----------------------------------------------------------------------
# Purpose:
#
# THIS FILE CONTAINS CODE TO DRAW A CUSTOMIZED PLOTS OF
# NMB, NME, CORRELATION, and FB, FE and RMSE.
# The script is ideally used with a long time period, specifically
# a year.  Average monthly domain-wide statistics are calculated 
# and plotted.  
#
# Plot1: Model and Ob Means (sum for precip and deposition species)
# Plot2: NMB, NME and CORRELATION
# Plot3: Median Bias, Median Error and RMSE 
#
# Any one of the computed statistics can be plotted with a small
# change to the script.  The script works with multiple years as
# well. This script is new to the AMETv1.2 code and has been updated
# for AMETv1.3 and AMET_v14b.
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

  ###  Directory where figures and text output will be directed
  setenv AMET_OUT       $AMETBASE/output/$AMET_PROJECT/monthly_stat_plot
  
  ###  Start and End Dates of plot (YYYY-MM-DD) -- must match available dates in db or site compare files
  setenv AMET_SDATE "2018-07-01"
  setenv AMET_EDATE "2018-07-31"
 
  ### Process ID. This can be set to anything. It will be added to the file output name. Default is 1.
  ### The PID is particularly important if using the AMET web interface and is determined there through
  ### a random number generator.
  setenv AMET_PID 1

  ###  Custom title (if not set will autogenerate title based on variables 
  ###  and plot type)
  #  setenv AMET_TITLE "Scatterplot $AMET_PROJECT $AMET_SDATE - $AMET_EDATE"


  ###  Plot Type, options are "pdf", "png" or "both"
  setenv AMET_PTYPE both


  ### Species to Plot ###
  ### Acceptable Species Names: SO4,NO3,NH4,HNO3,TNO3,PM25,EC,OC,TC,O3,O3_1hrmax,O3_8hrmax
  ### SO2,CO,NO,SO4_dep,SO4_conc,NO3_dep,NO3_conc,NH4_dep,NH4_conc,precip,NOy 
  ### AE6 (CMAQv5.0) Species
  ### Na,Cl,Al,Si,Ti,Ca,Mg,K,Mn,Soil,Other,Ca_dep,Ca_conc,Mg_dep,Mg_conc,K_dep,K_conc

  setenv AMET_AQSPECIES SO4

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

  # Log File for R script
  setenv AMET_LOG monthly_stat_plot.log

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
  R CMD BATCH --no-save --slave $AMETBASE/R_analysis_code/AQ_Monthly_Stat_Plot.R $AMET_LOG
  setenv AMET_R_STATUS $status
  
  if($AMET_R_STATUS == 0) then
		echo
		echo "Statistics information"
		echo "-----------------------------------------------------------------------------------------"
		echo "Plots -----------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_AQSPECIES}_${AMET_PID}_plot1.$AMET_PTYPE"
                echo "Plots -----------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_AQSPECIES}_${AMET_PID}_stat_plot1.$AMET_PTYPE"
                echo "Plots -----------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_AQSPECIES}_${AMET_PID}_stat_plot2.$AMET_PTYPE"
		echo "Text  -----------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_AQSPECIES}_${AMET_PID}_stats.csv"
		echo "-----------------------------------------------------------------------------------------"
		exit 0
  else
     echo "The AMET R script did not produce any output, please check the LOGFILE $AMET_LOG for more details on the error."
     echo "Often, this indicates no data matched the specified criteria (e.g., wrong dates for project). Please check and re-run!"
  		exit 1  
  endif

