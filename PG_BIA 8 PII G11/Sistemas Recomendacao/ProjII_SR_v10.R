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

# create columns for zones
# TrainDataSet[PostCodes]<-0
# ciclo for para contador por freguesia by user,time
#dat$`4100`<-ifelse(dat$PostCode==colnames(dat["4100"]),1,0)
# for (i in 11:ncol(TrainDataSet)) {TrainDataSet[,i]<-ifelse(TrainDataSet$POSTAL_CODE==colnames(TrainDataSet[i]),1,0)}

# Historic Ticket Sum

library(reshape2)
dat_dcast<-dcast(DataSet[,c("TICKET","REQUEST_DESC")],TICKET~REQUEST_DESC)

as(dat_dcast,'matrix') # incorrect - how to build a matrix format from a dataframe??
#data.matrix(dat_dcast,rownames.force = "TICKET")

#Create Training and Test data set -------------------------------------------------------------

# Clean Levels of variable 'Ticket', 'Request_Desc', 'Postal_Code'
str(DataSet)
DataSet$TICKET<-as.character(DataSet$TICKET)
DataSet$REQUEST_DESC<-as.character(DataSet$REQUEST_DESC)
DataSet$POSTAL_CODE<-as.character(DataSet$POSTAL_CODE)

DataSet$TICKET<-as.factor(DataSet$TICKET)
DataSet$REQUEST_DESC<-as.factor(DataSet$REQUEST_DESC)
DataSet$POSTAL_CODE<-as.factor(DataSet$POSTAL_CODE)
str(DataSet)

DataSet<-DataSet[order(DataSet$REQUEST_DATE,DataSet$TICKET),]


trPerc<-0.7
nTrain<-as.integer(trPerc*nrow(DataSet))

TestDataSet<-DataSet[(nTrain+1):nrow(DataSet),]
TrainDataSet<-DataSet[1:nTrain,]

range(TrainDataSet$REQUEST_DATE)
range(TestDataSet$REQUEST_DATE)


# Build Matrix Ticket-Postal_code--------------------------------------------------------
library(recommenderlab)

##  Train Matrix
t_train<-table(TrainDataSet$TICKET,TrainDataSet$REQUEST_DESC)
colnames(t_train)[1:20]
rownames(t_train)[1:20]
nrow(t_train)
ncol(t_train)
rowSums(t_train)

#Transform into relative frequencies
t_train_norm<-t_train/rowSums(t_train)
t_train_norm[1:5,]
rowSums(t_train_norm)

t_train_norm[t_train_norm<=0]<-NA

MatrTrain<-matrix(t_train_norm,nrow(t_train_norm),ncol(t_train_norm))
rownames(MatrTrain)<-rownames(t_train_norm)
colnames(MatrTrain)<-colnames(t_train_norm)
show(MatrTrain)
m<-as(MatrTrain,'realRatingMatrix')
as(m,'matrix')
show(m)

rowSums(m)
hist(getRatings(m))

##  Test Matrix
t_test<-table(TestDataSet$TICKET,TestDataSet$REQUEST_DESC)
colnames(t_test)[1:20]
rownames(t_test)[1:20]
nrow(t_test)
ncol(t_test)
rowSums(t_test)

#Transform into relative frequencies
t_test_norm<-t_test/rowSums(t_test)
t_test_norm[1:5,]
rowSums(t_test_norm)

t_test_norm[t_test_norm<=0]<-NA

MatrTest<-matrix(t_test_norm,nrow(t_test_norm),ncol(t_test_norm))
rownames(MatrTest)<-rownames(t_test_norm)
colnames(MatrTest)<-colnames(t_test_norm)
show(MatrTest)
mTest<-as(MatrTest,'realRatingMatrix')
as(mTest,'matrix')
show(mTest)

rowSums(mTest)
hist(getRatings(mTest))

## Recommendation -----------------------------------------------

library(recommenderlab)

# Model generation and use

model<-Recommender(m,method="UBCF")

# method=POPULAR 
#show(as(model@model$topN,'list'))
# See Association Rules if model = "AR"
#inspect(model@model$rule_base)


#One test example - put in matrix format and Predict
#as(mTest[19,],'matrix')
rowCounts(mTest)

recs<-predict(model,mTest["222403",],n=3)
as(recs,'list')

# Check prediction of stations - manipulate one test example

which(!is.na(as(mTest["348251",],"matrix")))
sample(which(!is.na(as(mTest["348251",],"matrix"))),4)
as(mTest["348251",c(which(!is.na(as(mTest["348251",],"matrix"))))],'matrix')

tst<-mTest['348251',]
manual<-as(tst,'matrix')
manual[,c(sample(which(!is.na(as(manual["348251",],"matrix"))),3))]<-NA
tst<-as(manual,'realRatingMatrix')
which(!is.na(as(tst["348251",],"matrix")))

recs<-predict(model,tst,n=3)
as(recs,'list')
# Compare the recommendations with the hidden items
as(mTest["348251",c(which(!is.na(as(mTest["348251",],"matrix"))))],'matrix')


## Evaluation --------------------------------------------

m<-as(DataSet[,c("TICKET","POSTAL_CODE")],'realRatingMatrix')
as(m,'matrix')
show(m)
hist(rowSums(m),breaks = 100)

#to run AR method it is necessary to 'binarize'
mb<-binarize(m,minRating=1)
as(mb,'matrix')
d<-mb

plot(sort(rowCounts(d)),type="line")
d<-d[rowCounts(d)>5]
evalscheme<-evaluationScheme(d,method="split",train=0.8,given=1)
algorithms<-list("random items" = list(name="RANDOM", param=NULL),
                 "popular items" = list(name="POPULAR", param=NULL),
                 "association rules" = list(name="AR",param=list(support=0.001,confidence=0.01,maxlen=5)),
                 "item-based CF 50" = list(name="IBCF", param=list(method="Cosine", k=50)),
                 "user-based CF 50" = list(name="UBCF", param=list(method="Cosine", nn=50)))
results<-evaluate(evalscheme,algorithms,n=c(1,3,5,10,15,20))
plot(results,annotate=c(1,2,4),legend="bottomright")
plot(results,"prec/rec",annotate=c(2,3,4),legend="bottomright")

# Check values of evaluation
results[["user-based CF 50"]]@results[[1]]@cm[5,6]
results[["item-based CF 50"]]@results[[1]]@cm[,6]
results[["association rules"]]@results[[1]]@cm

precision<-0
recall<-0
F1<-0
for (i in 1:6) {precision<-results[[3]]@results[[1]]@cm[i,5]
                recall<-results[[3]]@results[[1]]@cm[i,6]
                F1<-(2*precision*recall)/(precision+recall)
                print(i)
                print(F1)
}

## temp Normalize-----------------------


## min-max approach normalize data set
# define max and min values
#new_max<-5
#new_min<-1

#norm_min_max<-function(x) {(x-min(x,na.rm = TRUE))/(max(x,na.rm = TRUE)- min(x,na.rm = TRUE))*((new_max-new_min)+new_min)}

#t_normed<-apply(t,1, norm_min_max)
#t_normed


