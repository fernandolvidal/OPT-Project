# Imports and Access DB----------------------------

library(DBI)
library(RMySQL)
library(lubridate)
library(stringi)
library(stringr)

#Loading the MySQL driver
drv<-dbDriver("MySQL")
#Connecting to the DBMS
con<-dbConnect(drv, dbname="opt", bigint="character", username="a2018xxxx", password="pass", host="vsrv01.inesctec.pt",port=3306)

#getting the results of a query as a data frame
data_log<-dbGetQuery(con,"SELECT * FROM log") # modify the table name if it is a sample table

#closing up stuff
dbDisconnect(con)
dbUnloadDriver(drv)
rm(drv, con)

# initial Data Check-up and Data Selection--------------------------------

head(data_log)
str(data_log)
summary(data_log)

#Lengths and duplicated values - Data_log ID and Tickets
sum(duplicated(data_log$ID)) # Don't exist duplicated ID
length(unique(data_log$ID))
length(data_log$ID)

sum(duplicated(data_log$TICKET))
length(unique(data_log$TICKET))
length(data_log$TICKET)

#Check Missing Values NA's
sum(is.na(data_log$TICKET))
sum(is.na(data_log$RESPONSE_DESC))

#Check which Type and Service of Request
table(data_log$TYPEOFREQUEST)  # On Full - 0.23 % of all request are "RouteFinder" 
table(data_log$REQUEST_SERVICE)
#On FULL - 54.9% of all Request_Service are "GetScheds"; 33.7% are "LoadStopsWithinNMeters"
#About de 11.1% Request_Service are "empty"

#Range of Request_Date on data set
range(data_log$REQUEST_DATE)

#Create Master_Log_Detail and first Data selection
master_log_detail<-data_log[,c("ID","USERNAME","TYPEOFREQUEST","REQUEST_DATE","RESPONSE_DATE",
                               "REQUEST_SERVICE","REQUEST_DESC","TICKET","RESPONSE_DESC")]
rm(data_log)
#exclude Tickets =-1 and Username=CheckSyst, InfoBoard, SystemChe
master_log_detail$NonVal<-0
master_log_detail$NonVal[master_log_detail$TICKET=="-1"]<-1
master_log_detail$NonVal[master_log_detail$USERNAME=="CheckSyst" | master_log_detail$USERNAME=="InfoBoard" | master_log_detail$USERNAME=="SystemChe" ]<-1
master_log_detail<-master_log_detail[master_log_detail$NonVal==0,]
master_log_detail<-master_log_detail[,1:9]

# Create Sample-------------------------------------

#Order by Date decreasing
master_log_detail<-master_log_detail[order(master_log_detail$REQUEST_DATE,decreasing=TRUE),]
master_log_detail$REQUEST_DATE[1]
master_log_detail$REQUEST_DATE[length(master_log_detail$REQUEST_DATE)]

# last 5 000 k of Requests observations
n_sample<-5000000
sample_data_log<-master_log_detail[1:n_sample,]

# Remove master_log_detail
rm(master_log_detail)

#DATA CLEANING - Force Encoding UTF-8 in REQUEST_DESC and RESPONSE_DESC by portions
write.csv(sample_data_log[1:1000000,],file = "sample_data_log1.csv")
write.csv(sample_data_log[1000001:2000000,],file = "sample_data_log2.csv")
write.csv(sample_data_log[2000001:3000000,],file = "sample_data_log3.csv")
write.csv(sample_data_log[3000001:4000000,],file = "sample_data_log4.csv")
write.csv(sample_data_log[4000001:5000000,],file = "sample_data_log5.csv")

sample_data_log1<-read.csv(file = "sample_data_log1.csv",header = TRUE,encoding = "UTF-8")
sample_data_log2<-read.csv(file = "sample_data_log2.csv",header = TRUE,encoding = "UTF-8")
sample_data_log3<-read.csv(file = "sample_data_log3.csv",header = TRUE,encoding = "UTF-8")
sample_data_log4<-read.csv(file = "sample_data_log4.csv",header = TRUE,encoding = "UTF-8")
sample_data_log5<-read.csv(file = "sample_data_log5.csv",header = TRUE,encoding = "UTF-8")

for (i in 5:6) {sample_data_log1[,i]<-as.character(sample_data_log1[,i])}
for (i in 5:6) {sample_data_log2[,i]<-as.character(sample_data_log2[,i])}
for (i in 5:6) {sample_data_log3[,i]<-as.character(sample_data_log3[,i])}
for (i in 5:6) {sample_data_log4[,i]<-as.character(sample_data_log4[,i])}
for (i in 5:6) {sample_data_log5[,i]<-as.character(sample_data_log5[,i])}

#Check Request_Date Range of portions
range(sample_data_log$REQUEST_DATE)
range(sample_data_log1$REQUEST_DATE)
range(sample_data_log2$REQUEST_DATE)
range(sample_data_log3$REQUEST_DATE)
range(sample_data_log4$REQUEST_DATE)
range(sample_data_log5$REQUEST_DATE)

# Clean "£" character from RESQUEST_DESC
sample_data_log1$REQUEST_DESC<-str_replace_all(sample_data_log1$REQUEST_DESC,"£","")
sample_data_log2$REQUEST_DESC<-str_replace_all(sample_data_log2$REQUEST_DESC,"£","")
sample_data_log3$REQUEST_DESC<-str_replace_all(sample_data_log3$REQUEST_DESC,"£","")
sample_data_log4$REQUEST_DESC<-str_replace_all(sample_data_log4$REQUEST_DESC,"£","")
sample_data_log5$REQUEST_DESC<-str_replace_all(sample_data_log5$REQUEST_DESC,"£","")

#Join Portions again to sample_data_log
rm(sample_data_log)
sample_data_log<-rbind(sample_data_log1,sample_data_log2)
sample_data_log<-rbind(sample_data_log,sample_data_log3)
sample_data_log<-rbind(sample_data_log,sample_data_log4)
sample_data_log<-rbind(sample_data_log,sample_data_log5)

sample_data_log<-sample_data_log[,2:10]

#Simple Test to Validate rbind
sample_data_log3[1,]
sample_data_log[2000001,]
range(sample_data_log$REQUEST_DATE)
sample_data_log$REQUEST_DATE[1]
sample_data_log$REQUEST_DATE[5000000]

#Remove portions
rm(sample_data_log1,sample_data_log2,sample_data_log3,sample_data_log4,sample_data_log5)

# Write in MYSQL sample_data_log-------------------------------------------

#Loading the MySQL driver
drv<-dbDriver("MySQL")
#Connecting to the DBMS
con<-dbConnect(drv, dbname="P2G11", bigint="character", username="a2018xxxx", password="pass", host="vsrv01.inesctec.pt",port=3306)

#writing data frame sample into MYSQL
dbWriteTable(con,name = "Sample_Log_P2G11",value = sample_data_log,row.names=FALSE)

#closing up stuff
dbDisconnect(con)
dbUnloadDriver(drv)
rm(drv, con)
