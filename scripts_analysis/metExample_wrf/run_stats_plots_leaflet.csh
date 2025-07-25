#!/bin/csh -f
# -----------------------------------------------------------------------
# Stats plots using leaflet R package
# -----------------------------------------------------------------------
# Purpose:
#
# This code creates a single html spatial plot of NMB, NME, MB, ME
# FB, FE, RMSE and correlation, selectable via the legend. In addition, csv 
# files of all the available statistics in AMET are created for the domain
# as a whole and for each individual site. The script accepts
# mulitple networks, but only a single species and single model
# simulation. The output from this plot is a set of interactive html plots
# created using the R leaflet package. With this version, the different
# networks are not selectable. For that functionality, use the 
# run_stats_plots_leaflet_network.csh script.
#
# Initial version:  Wyat Appel - 04/2025 
# -----------------------------------------------------------------------

  
  #--------------------------------------------------------------------------
  # These are the main controlling variables for the R script
  
  ###  Top of AMET directory
  #setenv AMETBASE       /home/AMETv16
  setenv AMET_DATABASE  amet
  setenv AMET_PROJECT   metExample_wrf
  setenv MYSQL_CONFIG   $AMETBASE/configure/amet-config.R

  ### Indicate this as a MET database query ###
  Met_query     <- "T"
  TIME_FORMAT   <- "UTC"
 
  ### T/F; Set to T if the model/obs pairs are loaded in the AMET database (i.e. by setting LOAD_SITEX = T)
  setenv AMET_DB  T

  ### IF AMET_DB = F, set location of site compare output files using the environment variable OUTDIR
  #setenv OUTDIR  $AMETBASE/output/$AMET_PROJECT/sitex_output/201807

  ###  Directory where figures and text output will be directed
  setenv AMET_OUT       $AMETBASE/output/$AMET_PROJECT/stats_plots_leaflet
  
  ###  Start and End Dates of plot (YYYY-MM-DD) -- must match available dates in db or site compare files
  setenv AMET_SDATE "2016-07-01"
  setenv AMET_EDATE "2016-07-31"

  ### Process ID. This can be set to anything. It will be added to the file output name. Default is 1.
  ### The PID is particularly important if using the AMET web interface and is determined there through
  ### a random number generator.
  setenv AMET_PID 1

  ###  Plot Type, options are "html"
  setenv AMET_PTYPE html 

  ### Species to Plot ###
  ### Acceptable Species Names: T, WVMR, SRAD, Wind_Speed, PCP1H, PSFC

  setenv AMET_METSPECIES        WVMR

  ### Observation Network to plot
  ### Set to 'T' to process that nework
  ### NOTE: all species are not available for every network
  ### See AMET User's guide for details on each network

#> Met networks
  setenv AMET_ALL       F
  setenv AMET_METAR     T
  setenv AMET_SRAD      F
  setenv AMET_BSRN      F
  setenv AMET_AIRNOW    F
  setenv AMET_ASOS      F
  setenv AMET_MARITIME  F
  setenv AMET_SAO       F
  setenv AMET_OTHER_MTR F

  # Log File for R script
  setenv AMET_LOG stats_plots_leaflet.log

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
  R CMD BATCH --no-save --slave $AMETBASE/R_analysis_code/AQ_Stats_Plots_leaflet.R $AMET_LOG
  setenv AMET_R_STATUS $status
  
  if($AMET_R_STATUS == 0) then
		echo
		echo "Statistics information"
		echo "-----------------------------------------------------------------------------------------"
                echo "-----------------------------------------------------------------------------------------"
                echo "Plots -----------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_stats_plot.$AMET_PTYPE"
                echo "Data File -------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_stats_data.csv"
                echo "Data File -------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_sites_stats.csv"
                echo "Data File -------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_stats.csv"
		echo "-----------------------------------------------------------------------------------------"
		exit 0
  else
     echo "The AMET R script did not produce any output, please check the LOGFILE $AMET_LOG for more details on the error."
     echo "Often, this indicates no data matched the specified criteria (e.g., wrong dates for project). Please check and re-run!"
  		exit 1  
  endif

