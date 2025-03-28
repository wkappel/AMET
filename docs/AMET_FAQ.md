# Frequently Asked Questions for Upgrading to the Latest AMET Version

## Table of Contents:
* [Do I need to update from v1.5 to v1.6?](#why_update_v15_v16)
* [What do I need to do to update from v1.5 to v1.6?](#update_v15_v16)
* [What differences should I expect with v1.6 compared to v1.5?](#diff_v15_v16)
* [Technical support for AMET](#tech_support)

<a id=why_update_v15_v16></a>
## What changed and should I update to AMET v1.6?
AMETv1.6 is an incremental update from version 1.5. It includes important enhancements and new analysis scripts. **Users are encouraged to update to the latest version of the AMET-AQ observation files. Updating both the AMET version and AMET-AQ observation files together will insure all the AQ species matching between CMAQ and the observations is done correctly.**

**AMET-MET and AMET-AQ are backward compatible. No changes have been made to the underlying database structure.** New R_db_scripts and R_analysis_scripts will operate using old cshell wrappers (scripts_db and scripts_analysis). New scripts_db and scripts_analysis may not work with the old R_db_scripts and R_analysis_scripts, but that scenario is not likely or sensible. A users should look through the following MET and AQ updates/bug fixes and new features below to see if they are relevant, but an **update should be seamless and not interfere with prior AMET work or operation.**

#### AQ Updates v1.6

-	Support added for AirNow ozone and PM2.5 data
-	Support added for AMTIC HAPS data
-	Support added for PurpleAir PM2.5 data
-	Support added for numerous additional AQS VOC species
-	Updated batch scripts to incorporate new analysis scripts
-	Updated AQ_species_list.input file:
       - to include AirNow 
       - to include AMTIC
       - to include PurpleAir
       - to include AQS VOC species
-	Updated AMET-AQ observation files (see notes in [AMET_Release_Observation_Files_Readme.txt](https://github.com/USEPA/AMET/files/8655699/AMET_Release_Observation_Files_Readme.txt))
-	Numerous minor bug fixes
-	Updated processing for AMON data to properly adjust for travel blank (when available) or use a fixed value for the blank correction (value depends on year). Also updated the AMON input data file to include a POCode based on the replicate value to avoid records being overwritten when loaded into the database

#### New AQ Features v1.6

-	New analysis scripts
       - AQ_Histogram_plotly.R
       - AQ_Kellyplot_region_plotly.R
       - AQ_Kellyplot_season_plotly.R
       - AQ_Kellyplot_plotly.R
       - AQ_Scatterplot_density_ggplot.R (enhanced)
       - AQ_Timeseries_bysite.R
       - AQ_Timeseries_bysite_plotly.R
-	New analysis script options
       - Added popup time series option to AQ_Plot_Spatial_leaflet.R script. Combined the multiple plots into a single plot with selectable metrics
       - Added option to aggregate sites by parameter occruence code (POC) and common grid cell

#### MET Updates v1.6

-	

#### New MET Features v1.6

-	
 

<a id=update_v15_v16></a>
## What do I need to do to update from v1.5 to v1.6?
Obtain and install the AMETv1.6 code from the AMET repository. If intending to use the AMET-AQ side of AMET, also obtain the latest versions of the AMET observation files.

<a id=diff_v15_v16></a>
## What differences should I expect with v1.6 compared to v1.5?
On the air quality side of AMET, there should be no differences in the analysis scripts between AMET 1.5 and 1.6 aside from various bug fixes. There are several new analysis scripts avaiable, and these new scripts have been added to the batch scripting capability in AMET-AQ, so users can expect several new analysis plots when using the AMET-AQ batch scripts.  

The air quality species processed through AMET have changed between 1.5 and 1.6, with additional species and networks available to be processed through AMET in 1.6.

<a id=tech_support></a>
## Technical support for AMET
Technical support for AMET should be directed to the [CMAS Center User Forum](https://forum.cmascenter.org/). 
 [**Please read and follow these steps**](https://forum.cmascenter.org/t/please-read-before-posting/1321) prior to submitting new questions to the User Forum.
