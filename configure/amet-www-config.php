<?php
//////////////////////////////////////////////////////////////////
// Filename: amet-www-config.php                                //
//                                                              //
// This file is required by the various AMET PHP programs.      // 
//                                                              //
// This file provides necessary MYSQL information to the file   //
// above so that data from Site Compare can be added to the     //
// system's MYSQL database.                                     // 
//								//	
// LAST UPDATE: 03/2025						//
//////////////////////////////////////////////////////////////////

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// AMET and MySQL Configuration
$amet_base="";                                          // Base directory where AMET-AQ is installed
$mysql_server="";	// Name of MYSQL server
$root_login="";		// Root login for MYSQL server
$root_pass="";		// Root password for MYSQL server
$mysql_config="$amet_base/configure/amet-config.R";

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// R executable path
$R_exe="/usr/bin/R";						// Path to R executable
$R_script="/usr/bin/Rscript";					// Path to R script executable
$R_lib=" /share/linux86_64/R-3.2.4/lib/R/library";              // Path to R library directory
#$R_proj_lib="/home/appel/linux/lib/proj4";                  	// Path to proj4 executable

//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
// Web paths
$http_server="";					// An expample if amet was on http://www.coastwx.com (www.coastwx.com)
$http_amet="";						// Extension from server root to amet
$cache_amet="$amet_base/web_interface/cache";		// Default AMET cache directory (needs to have read/write access for web server)
$http_cgi="cgi-bin";
//::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
?>
