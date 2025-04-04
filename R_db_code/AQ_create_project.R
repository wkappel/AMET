##------------------------------------------------------
#       AMET AQ Database Table Creation                 #
#                                                       #
#       PURPOSE: To create a MYSQL table usable for     #
#               the AMET-AQ system                      #
#							#
#       Last Update: 02/2025 by Wyat Appel              #
#--------------------------------------------------------

######################################################################################

suppressMessages(require(RMySQL))	# Use RMYSQL package

amet_base <- Sys.getenv('AMETBASE')
if (!exists("amet_base")) {
   stop("Must set AMETBASE environment variable")
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

project_id	<- Sys.getenv('AMET_PROJECT')
model		<- Sys.getenv('MODEL_TYPE')
user_name	<- Sys.getenv('USER_NAME')
email		<- Sys.getenv('EMAIL_ADDR')
description	<- Sys.getenv('RUN_DESCRIPTION')
delete_table	<- Sys.getenv('DELETE_PROJECT')
remake_table	<- Sys.getenv('REMAKE_PROJECT')
update_table	<- Sys.getenv('UPDATE_PROJECT')
rename_table	<- Sys.getenv('RENAME_PROJECT')
#if (!exists("rename_table")) {
if (rename_table == "") {
  cat(paste("\n*** RENAME_TABLE environment variable not set. Defaulting to F. If you'd like to rename a project, use setenv RENAME_TABLE T and setenv NEW_AMET_PROJECT_NAME XXXXXXXXXXXXXXX. ***\n",sep=""))
  rename_table <- "F"
}

log_id		<- project_id
project_id 	<- gsub("[.]","_",project_id)
project_id      <- gsub("[-]","_",project_id)

if (log_id != project_id) {
   print("*** Requested project name has been altered to conform with database naming requirements. This likely means that periods and dashes have been replaced with underscores. ***")
}

args              <- commandArgs(2)
mysql_login       <- args[1]
mysql_pass        <- args[2]

### Use MySQL login/password from config file if requested ###
if (mysql_login == 'config_file') { mysql_login <- amet_login }
if (mysql_pass == 'config_file')  { mysql_pass  <- amet_pass  }
##############################################################

con             <- dbConnect(MySQL(),user=mysql_login,password=mysql_pass,dbname=dbase,host=mysql_server)
MYSQL_tables    <- dbListTables(con)

##################################################
### Function to create a AMET AQ project table ###
##################################################
create_table<-function()
{
   aq_new_1 <- paste("create table ",project_id," (proj_code varchar(100), POCode varchar(5), valid_code character(10), invalid_code character(10), replicate varchar(10), network varchar(25), stat_id varchar(25), stat_id_POCode varchar(100), lat double, lon double, i integer(4), j integer(4), ob_dates date, ob_datee date, ob_hour integer(2), month integer(2), precip_ob double, precip_mod double)",sep="")
   aq_new_2 <- paste("alter table ",project_id," add UNIQUE(network, stat_id,POCode,ob_dates,ob_datee,ob_hour)",sep="")
   aq_new_3 <- paste("alter table ",project_id," add INDEX(month)",sep="")
   create_table_log1 <- dbSendQuery(con,aq_new_1)
   create_table_log2 <- dbSendQuery(con,aq_new_2)
   create_table_log3 <- dbSendQuery(con,aq_new_3)
   cat(paste("\nThe project table ",project_id," has been created \n",sep=""))
}
##################################################

exists <- "n"
cat(paste("\nActive MySQL database = ",dbase,"\n",sep=""))
cat(paste("Project ID = ",project_id,"\n\n",sep=""))
if (length(MYSQL_tables) != 0) {
   cat("List of existing projects in dbase\n")
   cat(paste(MYSQL_tables,"\n",sep=""))
   if (project_id %in% MYSQL_tables) {
      cat ("\nThe project ID name you provided already exists.  Would you like to delete the existing project id (y/n)? \n")
      cat(paste(delete_table,"\n"))
      if ((delete_table == 'y') || (delete_table == 'Y') || (delete_table == 't') || (delete_table == 'T')) {
         drop <- paste("drop table ",project_id,sep="")
         mysql_result <- dbSendQuery(con,drop)
         drop2 <- paste("delete from aq_project_log where proj_code = '",project_id,"'",sep="")
         mysql_result <- dbSendQuery(con,drop2)
         cat("The following MySQL database tables have been successfully removed from the database. \n")
      }
      else {
         cat(paste("\nWould you like to update the description of the existing project ",project_id," (y/n)? \n",sep=""))
         cat(paste(update_table,"\n"))
         if ((update_table == 'y') || (update_table == 'Y') || (update_table == 't') || (update_table == 'T')) {
            cat(paste("\n\nModel = ",model,"\n",sep=""))
            cat(paste("\n\n user name = ",user_name,"\n",sep=""))
            cat(paste("\n\n email = ",email,"\n",sep=""))
            cat(paste("\n\n Project Description = ",description,"\n",sep=""))
            current_date <- Sys.Date()
	    current_time <- Sys.time()
	    current_time <- substr(current_time,12,19)
	    year <- substr(current_date,1,4)
	    mon  <- substr(current_date,6,7)
            day  <- substr(current_date,9,10)
            proj_time <- current_time
            proj_date <- paste(year,mon,day,sep="")
            cat(paste("\nproj_date=",proj_date))
            table_query <- paste("REPLACE INTO aq_project_log (proj_code, model, user_id, email, description, proj_date, proj_time) VALUES ('",project_id,"','",model,"','",user_name,"','",email,"','",description,"',",proj_date,",'",proj_time,"')",sep="")
            mysql_result <- dbSendQuery(con,table_query)
            #####################################################################################################################################
            ### This section automatically updates the min and max dates in the project_log table each time the add_aq2dbase.R script is run  ###
            #####################################################################################################################################
            cat("\nUpdating project log...")
            query_all <- paste("SELECT proj_code,model,user_id,passwd,email,description,DATE_FORMAT(proj_date,'%Y%m%d'),proj_time,DATE_FORMAT(min_date,'%Y%m%d'),DATE_FORMAT(max_date,'%Y%m%d') from aq_project_log where proj_code='",project_id,"' ",sep="")    # set query for project log table for all information regarding current project
            info_all <- dbGetQuery(con,query_all)
            model        <- info_all[,2]
            user_id      <- info_all[,3]
            password     <- info_all[,4]
            email        <- info_all[,5]
            description  <- info_all[,6]
            proj_date    <- info_all[,7]
            proj_time    <- info_all[,8]
            min_date_old <- info_all[,9]
            max_date_old <- info_all[,10]
            if ((is.na(min_date_old)) || (min_date_old == '00000000')) {        # override the initial value of 0 for the earliest date record
               query_date_min <- paste("select min(ob_dates) from ",project_id,";",sep="")
               info_date_min <- dbGetQuery(con,query_date_min)
               min_date <- info_date_min[,1]
            }
            if ((is.na(max_date_old)) || (max_date_old == '00000000')) {        # override the initial value of 0 for the earliest date record
               query_date_max <- paste("select max(ob_datee) from ",project_id,";",sep="")
               info_date_max <- dbGetQuery(con,query_date_max)
               max_date <- info_date_max[,] 
            }   
            query_dates <- paste("REPLACE INTO aq_project_log (proj_code,model,user_id,passwd,email,description,proj_date,proj_time,min_date,max_date) values ('",project_id,"','",model,"','",user_id,"','",password,"','",email,"','",description,"','",proj_date,"','",proj_time,"','",min_date,"','",max_date,"')",sep="")                    # put first and last dates into project log
            mysql_result <- dbSendQuery(con,query_dates)
            cat("done updating project start and end dates.\n")
            cat("\nThe following existing project description has been successfully updated.  Please review the following for accuracy, then use the link below to advance to the next step.")
#######################################################################################################################################
         }
         else {
            cat(paste("\nWould you like to rename the existing project (y/n)? \n",sep=""))
            cat(paste(rename_table,"\n"))
            if ((rename_table == 'y') || (rename_table == 'Y') || (rename_table == 't') || (rename_table == 'T')) {
               new_project_id <- Sys.getenv('NEW_AMET_PROJECT_NAME')
               cat(paste("\nRenaming project ",project_id," to ",new_project_id, ". This could take a while if data are already loaded.\n", sep=""))
               table_query1 <- paste("update project_units set proj_code = '",new_project_id,"' where proj_code = '",project_id,"';",sep="")
               table_query2 <- paste("update aq_project_log set proj_code = '",new_project_id,"' where proj_code = '",project_id,"';",sep="")
               table_query3 <- paste("update ",project_id," set proj_code = '",new_project_id,"' where proj_code = '",project_id,"';",sep="")
               table_query4 <- paste("rename table ",project_id," to ",new_project_id,";",sep="")
               mysql_result <- dbSendQuery(con,table_query1)
               mysql_result <- dbSendQuery(con,table_query2)
               mysql_result <- dbSendQuery(con,table_query3)
               mysql_result <- dbSendQuery(con,table_query4)
            }
            else {
               cat(paste("\nWould you like to remake the table for project ",project_id," (y/n)? (Note this will delete all existing data in project ",project_id," but retain the existing project description): \n",sep=""))
               cat(paste(remake_table,"\n"))
               if ((remake_table == 'y') || (remake_table == 'Y') || (remake_table == 't') || (remake_table == 'T')) {
                  drop <- paste("drop table ",project_id,sep="")
                  mysql_result <- dbSendQuery(con,drop)
                  create_table()
                  cat("\nThe following database table has been successfully re-generated.  Please review the following for accuracy, then use the link below to advance to the next step. \n")
               }
               else {
                  cat(paste("\nAlright, doing nothing. Change the flags in the script if you wish to delete, update or remake project ",project_id,".\n\n",sep=""))
               }
            } 
         }
      }
      exists <- 'y'
   }
}

if (exists != "y") {
   cat(paste("\nNo existing project named ",project_id," found.  Creating new project ",project_id," with the information below:",sep=""))
   cat(paste("\nmodel = ",model,sep=""))
   cat(paste("\nuser name = ",user_name,sep=""))
   cat(paste("\nemail = ",email,sep=""))
   cat(paste("\nproject description = ",description,"\n\n",sep=""))
   current_date <- Sys.Date()
   current_time <- Sys.time()
   current_time <- substr(current_time,12,19)
   year <- substr(current_date,1,4)
   mon  <- substr(current_date,6,7)
   day  <- substr(current_date,9,10)
   proj_date <- paste(year,mon,day,sep="")
   proj_time <- current_time
   table_query <- paste("REPLACE INTO aq_project_log (proj_code, model, user_id, email, description, proj_date, proj_time) VALUES ('",project_id,"','",model,"','",user_name,"','",email,"','",description,"',",proj_date,",'",proj_time,"')",sep="")
   mysql_result <- dbSendQuery(con,table_query)
   create_table()
   cat("\n### The following database tables have been successfully generated.  Please review the following for accuracy. ### \n")
}

if ((rename_table == 'y') || (rename_table == 'Y') || (rename_table == 't') || (rename_table == 'T')) {
   project_id <- new_project_id
}
query_min <- paste("SELECT * from aq_project_log where proj_code='",project_id,"' ",sep="")
query_results <- suppressWarnings(dbGetQuery(con,query_min))
cat(paste("project_id  = ",project_id,"\n",sep=""))
cat(paste("model       = ",query_results$model,"\n",sep=""))
cat(paste("user        = ",query_results$user,"\n",sep=""))
cat(paste("email       = ",query_results$email,"\n",sep=""))
cat(paste("description = ",query_results$description,"\n",sep=""))
cat(paste("proj_date   = ",query_results$proj_date,"\n",sep=""))
cat(paste("proj_time   = ",query_results$proj_time,"\n",sep=""))
mysql_result <- dbDisconnect(con)

