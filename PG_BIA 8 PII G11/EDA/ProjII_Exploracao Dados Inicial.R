####---GET START---####

#open_libraries
library("R.devices")
library("RMySQL")
library('DataExplorer')
library('ggplot2')
library("cowplot")
library(scales)
library(stringi)
library(stringr)


library('summarytools')
library('sqldf')
library('gbm')
library('ROCR')
library("aod")
library("randomForest")
library("rpart")
library("rattle")
library("caret")
library("jtools")
library("ggstance")
library("mlbench")
library("e1071")
library("h2o")
library("magrittr")
library("dplyr")
library("tidyverse")
library("lubridate")
library("esquisse")
library("DMwR")
library("ggcorrplot")
library("FSelector")
library("RColorBrewer")
library("flexclust")
library('ggdendro')
library("dendextend")
library('rgdal')
library('reshape2')
library('plotly')
library('factoextra')
library('data.table')
library("dbscan")
library("Rtsne")
library("cluster")


# clean_variables
# rm(list=ls())

# resources
gc()

#work_directory
setwd("C:/Users/pedro/Desktop/Silvia/Projeto II/Dados")


####---GET INFORMATION---####

#open_connection_to_database
drv <- dbDriver("MySQL")
conn_opt <- dbConnect(drv,host = "vsrv01.inesctec.pt",port = 3306,dbname = "opt", user = "a20182814", password = "XXX")
conn_P2G11 <- dbConnect(drv,host = "vsrv01.inesctec.pt",port = 3306,dbname = "P2G11", user = "a20182814", password = "XXX")
# conn_a20182814 <- dbConnect(drv,host = "vsrv01.inesctec.pt",port = 3306,dbname = "a20182814", user = "a20182814", password = "xxx")
#get_information_from_databases
data_log = dbGetQuery(conn_opt, "SELECT * FROM log")
data_rede = dbGetQuery(conn_opt, "SELECT * FROM rede")
data_rede<-dbGetQuery(conn_P2G11,"SELECT * FROM Dim_Rede") #if it is important all decimal places in Lat and Long import "as char" Lat and Long
data_rede<-data_rede[,-20]


# detach("package:RMySQL", unload=TRUE)

dbDisconnect(conn_opt)
dbDisconnect(conn_P2G11)
dbDisconnect(conn_a20182814)
dbUnloadDriver(drv)
rm(drv, conn_opt, conn_P2G11, conn_a20182814)



####--- Queries preliminares diretamente no servidor ---####

num = dbGetQuery(conn_opt, "SELECT count(*) FROM log")
num


# tipos de usernames
log_usernames = dbGetQuery(conn_opt, "

  SELECT USERNAME, count(*) 
  FROM log
  group by USERNAME"
)
log_usernames

# limpeza 
# criação tabela para exploração de dados
dbGetQuery(conn_P2G11, "
  CREATE TABLE IF NOT EXISTS log_P2G11 LIKE Master_Log_Detail
  ")

dbGetQuery(conn_P2G11, "
  CREATE INDEX index_name ON table_name (column_list)
  ")


dbGetQuery(conn_P2G11, "
  delete
  FROM log_P2G11
  ")

dbGetQuery(conn_P2G11, "
  INSERT log_P2G11
  SELECT * FROM Master_Log_Detail
  where USERNAME = 'Android' and TICKET > 0
  ")

dbGetQuery(conn_P2G11, "
  INSERT log_P2G11
  SELECT * FROM Master_Log_Detail
  where USERNAME = 'Android' and TICKET > 0
  or USERNAME = 'iOS' and TICKET > 0
  or USERNAME = 'iPhone' and TICKET > 0
  or USERNAME = 'WinPhone' and TICKET > 0
  ")


####--- Análise e Exploração de Dados ---####

# profiling data_rede ----
summary(data_rede)
introduce(data_rede)
plot_intro(data_rede)
plot_missing(data_rede)
plot_bar(data_rede)

# profiling data _log ----
summary(data_log)
str(data_log)
introduce(data_log)
plot_intro(data_log)
plot_missing(data_log)
plot_bar(data_log)
str(data_log)



# Clean data--------------------------

data_log <- data_log[data_log$TICKET != "-1" & data_log$TICKET != "0" & data_log$TICKET != "1",]
data_log <- data_log[data_log$USERNAME == "Android" | data_log$USERNAME =="iOS" | data_log$USERNAME == "iPhone" | data_log$USERNAME == "WinPhone",]

# Convert data--------------------------

data_log_0 <- data_log
table(data_log$USERNAME)
table(data_log$TYPEOFREQUEST )
table(data_log$REQUEST_SERVICE)
nrow(data_log)
summary(data_log)
str(data_log)

# data_log Convert Columns with categorical variables to Factor
data_log$ID<-as.factor(data_log$ID)
data_log$IP<-as.factor(data_log$IP)
data_log$USERNAME<-as.factor(data_log$USERNAME)
data_log$TYPEOFREQUEST<-as.factor(data_log$TYPEOFREQUEST)
data_log$REQUEST_SERVICE<-as.factor(data_log$REQUEST_SERVICE)
data_log$REQUEST_DATE<-ymd_hms(data_log$REQUEST_DATE)
data_log$RESPONSE_DATE<-ymd_hms(data_log$RESPONSE_DATE)
data_log <- data_log[, 1:11]
data_log <- data_log[, -9]


# Confirmação
summary(data_log)
str(data_log)



#plots sobre após a 1ª limpeza ----
options(repr.plot.width = 12, repr.plot.height = 8)
# ggplot(data_log, aes(x=REQUEST_SERVICE)) + geom_bar()

# nº de pedidos por REQUEST_SERVICE
ggplot(data_log, aes(x=REQUEST_SERVICE)) + geom_bar(fill="steelblue", width=0.5) + coord_flip()


# nº de pedidos por REQUEST_SERVICE e USERNAME
# nº de pedidos por REQUEST_SERVICE e USERNAME em %

# plot_grid(
    ggplot(data_log, aes(x=REQUEST_SERVICE, color=USERNAME, fill=USERNAME)) + 
    geom_bar(width=0.5) + 
    coord_flip() +
    theme(legend.position="bottom")
#    ,
    ggplot(data_log, aes(x=REQUEST_SERVICE, color=USERNAME, fill=USERNAME)) + 
    geom_bar(position ='fill', width=0.5) + 
    coord_flip() + 
    # scale_x_continuous(labels = percent) + 
    theme(legend.position="bottom")
# )


# Plot with dates ----
    
# nº de request_service por data
data_log_req_date <- data_log %>%
      select(REQUEST_DATE_date) %>%
      group_by(REQUEST_DATE_date) %>%
      count(REQUEST_DATE_date)
    
data_log_req_date$REQUEST_DATE_date = as.Date(data_log_req_date$REQUEST_DATE_date)
    
str(data_log_req_date$REQUEST_DATE_date)

# library(scales)
dp <- ggplot(data_log_req_date, aes(x=REQUEST_DATE_date, y=n)) + geom_line()
dp