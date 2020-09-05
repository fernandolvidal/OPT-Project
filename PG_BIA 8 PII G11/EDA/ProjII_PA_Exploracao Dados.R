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
conn_opt <- dbConnect(drv,host = "vsrv01.inesctec.pt",port = 3306,dbname = "opt", user = "a20182814", password = "changeme")
conn_P2G11 <- dbConnect(drv,host = "vsrv01.inesctec.pt",port = 3306,dbname = "P2G11", user = "a20182814", password = "changeme")
# conn_a20182814 <- dbConnect(drv,host = "vsrv01.inesctec.pt",port = 3306,dbname = "a20182814", user = "a20182814", password = "changeme")
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

# Gravação do data_log e data_rede extraída da biblioteca original
# save.image("C:/Users/pedro/Desktop/Silvia/Projeto II/Dados/data_log e data_rede.RData")

# em alternativa load do R workspace, uma vez que já foi gravado
# load("C:/Users/pedro/Desktop/Silvia/Projeto II/RDatas/SampleLog5M_final.RData")
# load("C:/Users/pedro/Desktop/Silvia/Projeto II/RDatas/data_rede.RData")
# data_log <- sample_data_log
# rm(sample_data_log)


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
# plot_histogram(data_rede)

# profiling data _log ----
summary(data_log)
str(data_log)
introduce(data_log)
plot_intro(data_log)
plot_missing(data_log)
plot_bar(data_log)
str(data_log)

# Dicas ----
# Sort by column index [1] then [3]
dataframe[
  order( dataframe[,1], dataframe[,3] ),
  ]

# Clean data--------------------------
# remove data_log$TICKET=-1 and data_log$USERNAME = !(USERNAME = "Android", "iOS", "iPhone", "WinPhone")
data_log <- data_log[data_log$TICKET != "-1" & data_log$TICKET != "0" & data_log$TICKET != "1",]
data_log <- data_log[data_log$USERNAME == "Android" | data_log$USERNAME =="iOS" | data_log$USERNAME == "iPhone" | data_log$USERNAME == "WinPhone",]
# grava .RData
# save.image("C:/Users/pedro/Desktop/Silvia/Projeto II/Dados/data_log e data_rede rm_1.RData")

# preparação sample_data_log
# sample_data_log <- read.csv(file = "sample_data_log.csv",header = TRUE,encoding = "UTF-8")
# load sample_data_log


# Convert data--------------------------

# load("C:/Users/pedro/Desktop/Silvia/Projeto II/Dados/data_log e data_rede rm_1.RData")

# data_log$REQUEST_DATE<-ymd_hms(data_log$REQUEST_DATE)
# data_log$DateDiff<-unlist(tapply(data_log$REQUEST_DATE, INDEX = data_log$TICKET, FUN = function(x) c(NA,diff(x))))
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
# data_log$REQUEST_SERVICE<-as.factor(data_log$REQUEST_SERVICE)
# data_log$RESPONSE_DESC<-as.factor(data_log$RESPONSE_DESC)
# data_log$TICKET<-as.factor(data_log$TICKET)
data_log <- data_log[, 1:11]
data_log <- data_log[, -9]


# Confirmação
summary(data_log)
str(data_log)



# #plots
# options(repr.plot.width = 12, repr.plot.height = 8)
# plot_grid(ggplot(train_final, aes(x=gender,fill=target))+ geom_bar(), 
#           ggplot(train_final, aes(x=age_group,fill=target))+ geom_bar(position = 'fill'),
#           ggplot(train_final, aes(x=HIERARCHY_PARENT_DSC,fill=target))+ geom_bar(position = 'fill'),
#           ggplot(train_final, aes(x=REGION,fill=target))+ geom_bar(position = 'fill'),
#           ggplot(train_final, aes(x=DISTRICT,fill=target))+ geom_bar(position = 'fill')+
#             scale_x_discrete(labels = function(x) str_wrap(x, width = 10)),
#           align = "h")

# http://www.sthda.com/english/wiki/ggplot2-histogram-plot-quick-start-guide-r-software-and-data-visualization#prepare-the-data

#plots sobre após a 1ª limpeza ----
options(repr.plot.width = 12, repr.plot.height = 8)
# ggplot(data_log, aes(x=REQUEST_SERVICE)) + geom_bar()

# nº de pedidos por REQUEST_SERVICE
ggplot(data_log, aes(x=REQUEST_SERVICE)) + geom_bar(fill="steelblue", width=0.5) + coord_flip()


# nº de pedidos por REQUEST_SERVICE e USERNAME
# nº de pedidos por REQUEST_SERVICE e USERNAME em %

# plot_grid(
    ggplot(data_log_0, aes(x=REQUEST_SERVICE, color=USERNAME, fill=USERNAME)) + 
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

  data_log_req_date


# library(scales)
dp <- ggplot(data_log_req_date, aes(x=REQUEST_DATE_date, y=n)) + geom_line()
dp


# Axis limits c(min, max)
# min <- as.Date("2019-9-1")
min <- min(data_log$REQUEST_DATE_date)
max <- max(data_log$REQUEST_DATE_date)


# frequencias de utilização ----


# nº de pedidos por REQUEST_SERVICE/TICKET
  data_log_req_TICKET <- data_log %>%
  select(REQUEST_SERVICE, TICKET) %>%
  group_by(REQUEST_SERVICE, TICKET) %>%
  count(TICKET)

  data_log_req_TICKET$n1 <- as.factor(data_log_req_TICKET$n)
  summary(data_log_req_TICKET)
  str(data_log_req_TICKET)

  # TICKET com mais utilizações: 
  max_n <-max(data_log_req_TICKET$n)
  dados <- data_log_req_TICKET[data_log_req_TICKET$n==max_n,]
  dados # GetScheds/565439 12841
  
  data_frame_TICKET <- as.data.frame(data_log_req_TICKET) 
  str(data_frame_TICKET)
  
  
# request_services
  data_log_req_services <- data_log %>%
  select(REQUEST_SERVICE) %>%
  group_by(REQUEST_SERVICE) %>%
  count(REQUEST_SERVICE)

  data_log_req_services$min <- 1 
  data_log_req_services$max <- 1 

  for (i in 1:nrow(data_log_req_services)) 
  {
   # data_log_req_services$max[i] <- nrow(
   # data_log_req_TICKET[data_log_req_TICKET$REQUEST_SERVICE == data_log_req_services$REQUEST_SERVICE[i] & 
   # data_log_req_TICKET$n==1,])
    data_log_req_services$max[i] <- nrow(
    data_log_req_TICKET[data_log_req_TICKET$REQUEST_SERVICE == data_log_req_services$REQUEST_SERVICE[i] & 
    data_log_req_TICKET$n==1,])
    data_log_req_services$max[i]
  }
  
  # confirmação
  table(data_log_req_TICKET$n[data_log_req_TICKET$REQUEST_SERVICE == "GetScheds" ])
  table(data_log_req_TICKET$n[data_log_req_TICKET$REQUEST_SERVICE == "ReadMessages" ])
  for (i in 1:nrow(data_log_req_services)) 
  {
    table(data_log_req_TICKET$n[data_log_req_TICKET$REQUEST_SERVICE == data_log_req_services$REQUEST_SERVICE[i] ])
  }
  
  data_log_req_services
  max <- max(data_log_req_services$max)
  max

  p<-ggplot(df, aes(x=weight))+
  geom_histogram(color="black", fill="white")+
  facet_grid(sex ~ .)
 
  p<-ggplot(data_log_req_TICKET, aes(x=REQUEST_SERVICE))+
    geom_histogram(color="black", fill="white")+
    facet_grid(n1 ~ .)
  p
  # outra tentativa
  p<-ggplot(data_log_req_TICKET, aes(x=REQUEST_SERVICE))+
    geom_histogram(color="black", fill="white")+
    facet_grid(n1 ~ .)
  
  str(data_log_req_TICKET)
  
## 1ª aplicação
  ggplot(data_log_req_TICKET, aes(x= n1, colour = REQUEST_SERVICE)) + 
  geom_freqpoly(bins = max, binwidth=6,size=1.5)+ 
  geom_area(aes(fill = REQUEST_SERVICE), color = "white", stat ="bin", bins = max)+
  facet_grid(REQUEST_SERVICE ~ .)

+
  theme_bw()+
  xlab(" ") + 
  xlim(min, 15000)

  ggplot(data_log_req_TICKET, aes(x= n1, colour = REQUEST_SERVICE)) + 
    geom_freqpoly() + 
    geom_area(aes(fill = REQUEST_SERVICE))+
    facet_grid(REQUEST_SERVICE ~ .)

  
  # Análise da sample de PA ---------------------------------------------------------------------
  # versão com load da sample de PA devidamente tratada e preparada --------------------------
  # 
  # load("C:/Users/pedro/Desktop/Silvia/Projeto II/RDatas/Sample_PA.RData")
 
  

  str(sample)
  str(sample$dia_util)
  levels(sample$day) <- c("Sun", "Mon","Tue", "Wed","Thr", "Fri", "Sat")
  levels(sample$part_of_the_day) <- c("[0,6[", "[6-13[","[13-18[", "[18-24[")
  levels(sample$dia_util) <- c("weekend", "workday")

# Exploração PA 

# Relation between Temperature and precipitation for request_service
  ggplot(data = sample)+
  geom_point(mapping = aes(x=temperature,y=precipProbability,color=REQUEST_SERVICE))

range(sample$REQUEST_DATE)


sample$REQUEST_DATE_data <- as.Date(sample$REQUEST_DATE,format = "%y.%m.%d %H:%M:%S")

data_freq <- table(sample$REQUEST_DATE_data)
data_freq[,1]



ggplot(sample, aes(REQUEST_DATE, )) 


# com request_service, valores absoluto

#1
  ggplot(sample, aes(x=part_of_the_day, fill=REQUEST_SERVICE)) + 
    geom_bar(width=0.5) +
    scale_y_continuous(breaks = c(100000, 200000, 300000, 400000, 500000, 600000, 750000, 1000000, 1250000),
                     labels = c("1000k", "200k", "300k", "400k", "500k", "600k", "750k", "1000k", "1250k"))
  + theme(legend.position = "none")

#2
  ggplot(sample, aes(x=day, fill=REQUEST_SERVICE)) + 
  geom_bar(width=0.5) +
    scale_y_continuous(breaks = c(100000, 200000, 300000, 400000, 500000, 600000, 700000),
                       labels = c("100k", "200k", "300k", "400k", "500k", "600k", "700k"))
  + theme(legend.position = "none")

  
#3
  ggplot(sample, aes(x=dia_util, fill=REQUEST_SERVICE)) + 
    geom_bar(width=0.5) +
    scale_y_continuous(breaks = c(1000000, 2000000, 3000000, 4000000, 5000000, 6000000, 7000000),
                       labels = c("1000k", "2000k", "3000k", "4000k", "5000k", "6000k", "7000k"))
  + theme(legend.position = "none")

#4
  ggplot(sample, aes(x=part_of_the_day,fill=REQUEST_SERVICE))+ 
    geom_bar( position= 'fill', width=0.5) +
    # coord_flip() +
   scale_y_continuous(labels = percent_format()) +
    theme(legend.position = "none")

#5
  ggplot(sample, aes(x=day,fill=REQUEST_SERVICE))+ 
  geom_bar( position= 'fill', width=0.5) +
    # coord_flip() +
    scale_y_continuous(labels = percent_format()) +
    theme(legend.position = "none")

#6
  ggplot(sample, aes(x=dia_util,fill=REQUEST_SERVICE))+ 
    geom_bar( position= 'fill', width=0.5) +
    # coord_flip() +
    scale_y_continuous(labels = percent_format()) +
    theme(legend.position = "none")
  