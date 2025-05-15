Atmospheric Model Evaluation Tool
======

## AMETv1.6

Atmospheric Model Evaluation Tool (AMET) website: (https://www.epa.gov/cmaq/atmospheric-model-evaluation-tool)

The Atmospheric Model Evaluation Tool (AMET) is a suite of software designed to facilitate the analysis and evaluation of predictions from meteorological and air quality models. AMET matches the model output for particular locations to the corresponding observed values from one or more networks of monitors. These pairings of values (model and observation) are then used to statistically and graphically analyze the model’s performance.

[Frequently asked questions for upgrading to the latest AMET version](docs/AMET_FAQ.md) - Updated for v1.6 release.

## AMETv1.6

- General Updates for v1.6
    - Moved from using RMySQL to RMariaDB, as R is moving away from RMySQL

- AQ Updates v1.6
    - Support added for AirNow ozone and PM2.5 data 
    - Support added for AMTIC HAPS data
    - Support added for PurpleAir PM2.5 data
    - Support added for numerous additional AQS VOC species
    - Updated batch scripts to incorporate new analysis scripts
    - Updated AQ_species_list.input file:
       - to include AirNow
       - to include AMTIC
       - to include PurpleAir
       - to include AQS VOC species
   - Updated AMET-AQ observation files (see notes in AMET_Release_Observation_Files_Readme.txt)
   - Numerous minor bug fixes
   - Updated processing for AMON data to properly adjust for travel blank (when available) or use a fixed value for the blank correction (value depends on year). Also updated the AMON input data file to include a POCode based on the replicate value to avoid records being overwritten when loaded into the database
- New AQ Features v1.6
  - New analysis scripts:
    - AQ_Histogram_plotly.R
    - AQ_Kellyplot_region_plotly.R
    - AQ_Kellyplot_season_plotly.R
    - AQ_Kellyplot_plotly.R
    - AQ_Scatterplot_density_ggplot.R (enhanced)
    - AQ_Timeseries_bysite.R
    - AQ_Timeseries_bysite_plotly.R
  - New analysis script options
    - Added popup time series option to AQ_Plot_Spatial_leaflet.R script. Combined the multiple plots into a single plot with selectable metrics
    - Added option to aggregate sites by parameter occruence code (POC) and common grid cell
- MET Updates v1.6

- New MET Features v1.6



## Getting the AMET Repository
This AMET Git archive is organized with each official public release stored as a branch on the main USEPA/AMET repository.
To clone code from the AMET Git archive, specify the branch (i.e. version number) and issue the following command from within
a working directory on your server:
```
git clone -b 1.6 https://github.com/USEPA/AMET.git AMET_v16
```

Earlier release versions of AMET that are currently available on Git Hub include:

* [v1.2 (July 2013)](https://github.com/USEPA/AMET/tree/1.2)
* [v1.3 (July 2017)](https://github.com/USEPA/AMET/tree/1.3)
* [v1.4 (August 2018)](https://github.com/USEPA/AMET/tree/1.4)
* [v1.5 (August 2022)](https://github.com/USEPA/AMET/tree/1.5)

## EPA Disclaimer
The United States Environmental Protection Agency (EPA) GitHub project code is provided on an "as is" basis and the user assumes responsibility for its use. EPA has relinquished control of the information and no longer has responsibility to protect the integrity , confidentiality, or availability of the information. Any reference to specific commercial products, processes, or services by service mark, trademark, manufacturer, or otherwise, does not constitute or imply their endorsement, recommendation or favoring by EPA. The EPA seal and logo shall not be used in any manner to imply endorsement of any commercial product or activity by EPA or the United States Government.    [<img src="https://licensebuttons.net/p/mark/1.0/88x31.png" width="50" height="15">](https://creativecommons.org/publicdomain/zero/1.0/)
 

