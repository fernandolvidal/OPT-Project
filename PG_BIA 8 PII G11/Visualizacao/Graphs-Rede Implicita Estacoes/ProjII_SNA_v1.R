# Imports and Access DB---------------------------------

library(DBI)
library(RMySQL)
library(lubridate)
library(stringi)
library(stringr)

#Loading the MySQL driver
drv<-dbDriver("MySQL")
#Connecting to the DBMS
con<-dbConnect(drv, dbname="P2G11", bigint="character", username="a2018xxxx", password="pass", host="vsrv01.inesctec.pt",port=3306)

#getting the results of a query as a data frame
sample_data_log<-dbGetQuery(con,"SELECT * FROM Sample_Log_P2G11") # modify the table name
data_rede<-dbGetQuery(con,"SELECT * FROM Dim_Rede") #if it is important all decimal places in Lat and Long import "as char" Lat and Long

#closing up stuff
dbDisconnect(con)
dbUnloadDriver(drv)
rm(drv, con)

# initial Data Check-up--------------------------------

head(sample_data_log)
str(sample_data_log)
summary(sample_data_log)

#Lengths and duplicated values - Data_log ID and Tickets
sum(duplicated(sample_data_log$ID)) # Don't exist duplicated ID
length(unique(sample_data_log$ID))
length(sample_data_log$ID)

sum(duplicated(sample_data_log$TICKET))
length(unique(sample_data_log$TICKET)) # 43586/(5x10^6) unique tickets
length(sample_data_log$TICKET)

#Check Missing Values NA's
sum(is.na(sample_data_log$TICKET))
sum(is.na(sample_data_log$RESPONSE_DESC))

#Check which Type and Service of Request
table(sample_data_log$TYPEOFREQUEST)  # On Sample - 0.22 % of all request are "RouteFinder" 
table(sample_data_log$REQUEST_SERVICE)
#On Sample - 59.4% of all Request_Service are "GetScheds"; 40.3% are "LoadStopsWithinNMeters"

#Range of Request_Date on data set
range(sample_data_log$REQUEST_DATE)

# Clean and Convert data--------------------------------

# Sample Data log
#Convert Columns with categorical variables to Factor
sample_data_log$ID<-as.factor(sample_data_log$ID)
sample_data_log$USERNAME<-as.factor(sample_data_log$USERNAME)
sample_data_log$TYPEOFREQUEST<-as.factor(sample_data_log$TYPEOFREQUEST)

for (i in 6:ncol(sample_data_log)) {sample_data_log[,i]<-as.factor(sample_data_log[,i])}

summary(sample_data_log)

#Check Missing Values NA's
apply(sample_data_log,2,function(x) sum(is.na(x))) # gives number of MV per column

#Number of complete rows
nrow(na.omit(sample_data_log)) 

# Understand which users request more than once 

sum(duplicated(sample_data_log$TICKET[sample_data_log$REQUEST_SERVICE=="GetScheds"]))
sum(duplicated(sample_data_log$TICKET[sample_data_log$REQUEST_SERVICE=="LoadPointOfIntere"]))
sum(duplicated(sample_data_log$TICKET[sample_data_log$REQUEST_SERVICE=="LoadStopsWithinNM"]))
sum(duplicated(sample_data_log$TICKET[sample_data_log$REQUEST_SERVICE=="ProcessRequest"]))

# Data_rede

head(data_rede)
summary(data_rede)
str(data_rede)

#Convert Columns with categorical variables to Factor
for (i in 1:11) {data_rede[,i]<-as.factor(data_rede[,i])}
for (i in 13:ncol(data_rede)) {data_rede[,i]<-as.factor(data_rede[,i])}

summary(data_rede)

# Merge Data ---------------------------------------------------------------------
sum(duplicated(data_rede$STOP_KEY))
length(unique(data_rede$STOP_KEY))
length(data_rede$STOP_KEY)

# create a Simple data frame with only unique stop_keys (and respective PostCodes)
data_rede_Sel<-data_rede[,c("STOP_KEY","POSTAL_CODE")]
data_rede_Sel$RepStop_Key<-0
data_rede_Sel$RepStop_Key[duplicated(data_rede_Sel$STOP_KEY)=="TRUE"]<-1
#check variable RepStop_key
data_rede_Sel<-data_rede_Sel[order(data_rede_Sel$STOP_KEY),]

data_rede_Sel<-data_rede_Sel[data_rede_Sel$RepStop_Key==0,]

mergedtable<-merge(x=sample_data_log,y=data_rede_Sel, all.x = TRUE,by.x = c("REQUEST_DESC"),by.y = c("STOP_KEY"))
summary(mergedtable)
length(unique(mergedtable$POSTAL_CODE)) 

#Data Selection and Features-----------------------------------------------------------

#Filter dataset to RequestService=Get Scheds

DataSet<-mergedtable[,c("USERNAME","TICKET","REQUEST_DATE","REQUEST_SERVICE",
                             "REQUEST_DESC","RESPONSE_DESC","POSTAL_CODE")]
DataSet<-DataSet[DataSet$REQUEST_SERVICE=="GetScheds",]
summary(DataSet)

# Top-10 most frequent Tickets "Get Scheds" Service
sort(table(DataSet$TICKET),decreasing = TRUE)[1:10]

# List of tickets that request more than once - Active Tickets - exclude ticket=-1
DataSet$RepTicket<-0
DataSet$RepTicket[duplicated(DataSet$TICKET)=="TRUE"]=1
DataSet$RepTicket[DataSet$TICKET=="0" | DataSet$TICKET=="1"]=99
DataSet$RepTicket<-as.factor(DataSet$RepTicket)

ActiveTickets<-DataSet[DataSet$RepTicket=="1","TICKET"]

# create data set only with the transactions of the Active Tickets
DataSet<-DataSet[DataSet$TICKET %in% ActiveTickets,]

## Features

# Time between requests for the same ticket - DateDiff
library(lubridate)
DataSet$REQUEST_DATE<-ymd_hms(DataSet$REQUEST_DATE)
DataSet<-DataSet[order(DataSet$TICKET,DataSet$REQUEST_DATE),]
DataSet$DateDiff<-unlist(tapply(DataSet$REQUEST_DATE, INDEX = DataSet$TICKET, FUN = function(x) c(NA,diff(x))))

# Frequency of Station / Zone Request 
postcodes_valid<-DataSet$POSTAL_CODE[grep("^4",DataSet$POSTAL_CODE)]
DataSet<-DataSet[DataSet$POSTAL_CODE %in% postcodes_valid,]

PostCodes <-as.character(unique(DataSet$POSTAL_CODE),na.rm=TRUE)
length(DataSet$POSTAL_CODE)
length(unique(DataSet$POSTAL_CODE))

# Sub TrainDataSet and TestDataSet - concept model 
#DataSet<-DataSet[1:5000,]

#Eliminate observations with DateDiff < 3min and the same "REQUEST_DESC" - Confirm that we want???
DataSet$RequestDiff<-0
for (i in 2:nrow(DataSet)) {DataSet$RequestDiff[i] <-ifelse(DataSet$REQUEST_DESC[i-1]==DataSet$REQUEST_DESC[i],1,0)}

DataSet<-DataSet[-which(DataSet$DateDiff < 180 & DataSet$RequestDiff==1),]

# Clean Levels of variable 'Ticket', 'Request_Desc', 'Postal_Code'
str(DataSet)
DataSet$TICKET<-as.character(DataSet$TICKET)
DataSet$REQUEST_DESC<-as.character(DataSet$REQUEST_DESC)
DataSet$POSTAL_CODE<-as.character(DataSet$POSTAL_CODE)

DataSet$TICKET<-as.factor(DataSet$TICKET)
DataSet$REQUEST_DESC<-as.factor(DataSet$REQUEST_DESC)
DataSet$POSTAL_CODE<-as.factor(DataSet$POSTAL_CODE)
str(DataSet)

# Create Graph ---------------------------------------------------------

# Build a Matrix Ticket-Request_Desc
t<-table(DataSet$TICKET,DataSet$REQUEST_DESC)
colnames(t)[1:20]
rownames(t)[1:20]
MatrData<-matrix(t,nrow(t),ncol(t))
rownames(MatrData)<-rownames(t)
colnames(MatrData)<-colnames(t)
show(MatrData)

as(MatrData,'matrix')

library(igraph)
g<-graph_from_incidence_matrix(MatrData)
plot(g)
V(g)$size<-4
plot(g)
V(g)$label.cex <-1 
proj_g<-bipartite.projection(g)  
plot(proj_g)


plot(proj_g[[1]], g=TRUE, e=TRUE)
plot(proj_g[[2]], g=TRUE, e=TRUE)
V(proj_g[[2]])$size<-0.5
plot(proj_g[[2]], g=TRUE, e=TRUE)

gp<-proj_g[[2]]
edgelist<-get.edgelist(gp)
E(gp)$weight
edgelist_weight<-cbind(get.edgelist(gp),E(gp)$weight) #create edgelist weighted

# write csv to import to Gephi
write.csv(edgelist_weight,file = "edgelistweight50_proj.csv",row.names = FALSE)

#df_edge<-as.data.frame(edgelist)

#df_adjacency_w<-get.adjacency(gp)

