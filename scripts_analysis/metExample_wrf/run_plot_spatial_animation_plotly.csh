#!/bin/csh -f
# -----------------------------------------------------------------------
# Spatial plot
# -----------------------------------------------------------------------
# Purpose:
#
# This is an example c-shell script to run the R-script that generates
# a series of spatial plots. It takes a single species from one or more
# networks and plots the observation value, model value, and 
# difference between the model and ob for each site for each 
# corresponding network.  Mutiple values for a site are averaged
# to a single value for plotting purposes.  The map area plotted
# is dynamicall generated from the input data.   
#
# Initial version:  Alexis Zubrow IE UNC - Nov, 2007
#
# Revised version:  Wyat Appel - 04/2025 
# -----------------------------------------------------------------------

  
  #--------------------------------------------------------------------------
  # These are the main controlling variables for the R script
  
  ###  Top of AMET directory
 #setenv AMETBASE       /home/AMETv16
  setenv AMET_DATABASE  amet
  setenv AMET_PROJECT   metExample_wrf
  setenv MYSQL_CONFIG   $AMETBASE/configure/amet-config.R

  ### Indicate this as a MET database query ###
  setenv Met_query     T
  setenv TIME_FORMAT   UTC

  ### Set the project name to be used for model-to-model comparisons ###
  #setenv AMET_PROJECT2 metExample_wrf 
 
  ###  Directory where figures and text output will be directed
  setenv AMET_OUT       $AMETBASE/output/$AMET_PROJECT/plot_spatial_animation_plotly

  ### T/F; Set to T if the model/obs pairs are loaded in the AMET database (i.e. by setting LOAD_SITEX = T)
  setenv AMET_DB  T

  ### IF AMET_DB = F, set location of site compare output files using the environment variable OUTDIR
  #setenv OUTDIR  $AMETBASE/output/$AMET_PROJECT/sitex_output/201807

  ###  Start and End Dates of plot (YYYY-MM-DD) -- must match available dates in db or site compare files
  setenv AMET_SDATE "2016-07-01"
  setenv AMET_EDATE "2016-07-31"

  ### Process ID. This can be set to anything. It will be added to the file output name. Default is 1.
  ### The PID is particularly important if using the AMET web interface and is determined there through
  ### a random number generator.
  setenv AMET_PID 1

  ### Custom title (if not set will autogenerate title based on variables 
  ###  and plot type)
  setenv AMET_TITLE "Spatial plot $AMET_PROJECT $AMET_SDATE - $AMET_EDATE"

  ###  Plot Type, script produces PDF and HTML files
  setenv AMET_PTYPE pdf

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
  setenv AMET_LOG plot_spatial_animation_plotly.log

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
  R CMD BATCH --no-save --slave $AMETBASE/R_analysis_code/AQ_Plot_Spatial_animation_plotly.R $AMET_LOG
  setenv AMET_R_STATUS $status
  
  if($AMET_R_STATUS == 0) then
  echo
                echo "Statistics information"
                echo "-----------------------------------------------------------------------------------------"
		echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_obs.png"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_mod.png"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_diff.png"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_diff_avg.png"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_diff_abs_avg.png"
		echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_obs.pdf"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_mod.pdf"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_diff.pdf"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_diff_avg.pdf"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_diff_abs_avg.pdf"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_obs.html"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_mod.html"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_diff.html"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_diff_avg.html"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_diff_abs_avg.html"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_anim_obs.html"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_anim_mod.html"
                echo "Plots -- ---------------------> $AMET_OUT/${AMET_PROJECT}_${AMET_METSPECIES}_${AMET_PID}_spatialplot_anim_diff.html"
                echo "-----------------------------------------------------------------------------------------"
                exit 0
  else
     echo "The AMET R script did not produce any output, please check the LOGFILE $AMET_LOG for more details on the error."
     echo "Often, this indicates no data matched the specified criteria (e.g., wrong dates for project). Please check and re-run!"
  		exit 1  
  endif

