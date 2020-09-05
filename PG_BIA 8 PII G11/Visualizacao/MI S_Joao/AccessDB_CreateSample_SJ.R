# Imports and Access DB----------------------------

library(DBI)
library(RMySQL)
library(lubridate)
library(stringi)
library(stringr)


#work_directory
# setwd("C:/Users/pedro/Desktop/Silvia/Projeto II/Dados")
setwd("C:/Users/pedro/Desktop/Silvia/Projeto II/P2G11 S_Joao/RDatas")

# Create Sample S.João --------------------------------
# data_log_sjoao: Request observations from 19.06.23 to 19.06.24

#Loading the MySQL driver
drv<-dbDriver("MySQL")
#Connecting to the DBMS
con<-dbConnect(drv, dbname="opt", bigint="character", username="a2018xxxx", password="pass", host="vsrv01.inesctec.pt",port=3306)

#getting the results of a query as a data frame
data_log_sjoao<-dbGetQuery(con,
  "SELECT * 
  FROM log
  where substr(request_date, 1, 8) = '19.06.23' or 
  substr(request_date, 1, 8) = '19.06.24'
") # modify the table name if it is a sample table

#closing up stuff
dbDisconnect(con)
dbUnloadDriver(drv)
rm(drv, con)


#Range of Request_Date on data set
range(data_log_sjoao$REQUEST_DATE)

# first Data selection
data_log_sjoao<-data_log_sjoao[,c("ID","USERNAME","TYPEOFREQUEST","REQUEST_DATE","RESPONSE_DATE",
                               "REQUEST_SERVICE","REQUEST_DESC","TICKET","RESPONSE_DESC")]

#exclude Tickets =-1 and Username=CheckSyst, InfoBoard, SystemChe

data_log_sjoao<-data_log_sjoao[data_log_sjoao$TICKET!="-1",]
data_log_sjoao<-data_log_sjoao[data_log_sjoao$USERNAME!="CheckSyst" & data_log_sjoao$USERNAME!="InfoBoard" & data_log_sjoao$USERNAME!="SystemChe",]


#DATA CLEANING sample_sjoao_log - Force Encoding UTF-8 in REQUEST_DESC and RESPONSE_DESC in sample_sjoao_log
write.csv(data_log_sjoao,file = "sample_sjoao_log.csv")
sample_sjoao_log<-read.csv(file = "sample_sjoao_log.csv",header = TRUE,encoding = "UTF-8")

for (i in 5:6) {sample_sjoao_log[,i]<-as.character(sample_sjoao_log[,i])}
range(sample_sjoao_log$REQUEST_DATE)
sample_sjoao_log$REQUEST_DESC<-str_replace_all(sample_sjoao_log$REQUEST_DESC,"ÃÂ£","")
sample_sjoao_log<-sample_sjoao_log[,2:10]


# Write in MYSQL

#Loading the MySQL driver
drv<-dbDriver("MySQL")
#Connecting to the DBMS
con<-dbConnect(drv, dbname="P2G11", bigint="character", username="axxxxxxxx", password="pass", 
               host="vsrv01.inesctec.pt",port=3306)

#writing data frame sample into MYSQL
dbWriteTable(con,name = "Sample_SJoao_Log_P2G11",value = sample_sjoao_log)

#closing up stuff
dbDisconnect(con)
dbUnloadDriver(drv)
rm(drv, con)

# Preparação PGAdmin ---------------------------------------------------------------------
# versão com load da sample sjoao devidamente tratada e preparada --------------------------
# 
# em alternativa para evitar a consulta ao servidor do INESCTEC
# load("C:/Users/pedro/Desktop/Silvia/Projeto II/Dados/Sample_sjoao.RData")

range(sample_sjoao_log$REQUEST_DATE)

# Separação de dados GetScheds e LoadStopsWithinNM
sample_sjoao_log_scheds <- sample_sjoao_log[sample_sjoao_log$REQUEST_SERVICE=="GetScheds",]
sample_sjoao_log_load <- sample_sjoao_log[sample_sjoao_log$REQUEST_SERVICE=="LoadStopsWithinNM",]
rm(sample_sjoao_log)

# LoadStopsWithinNM - preparação para exportação para o PGAdmin
sample_sjoao_log_load$ID <- format(sample_sjoao_log_load$ID, scientific = FALSE) # garante que a notação não é científica
sample_sjoao_log_load$REQUEST_DESC <- gsub('\\,', '\\.', sample_sjoao_log_load$REQUEST_DESC)
sample_sjoao_log_load$REQUEST_LATITUDE <- str_split_fixed(sample_sjoao_log_load$REQUEST_DESC ," ",3)[,1]
# manipulate and convert date columns with caracter format to timestamp
# converter formato "19.06.23 15:26:37" para "23.06.19 15:26:37" para importação direta no pgadmin

sample_sjoao_log_load$REQUEST_DATE <- paste(substr(sample_sjoao_log_load$REQUEST_DATE,7,8), 
                                            substr(sample_sjoao_log_load$REQUEST_DATE,3,6), 
                                            substr(sample_sjoao_log_load$REQUEST_DATE,1,2), 
                                            substr(sample_sjoao_log_load$REQUEST_DATE,9, 17), sep="")
sample_sjoao_log_load$RESPONSE_DATE <- paste(substr(sample_sjoao_log_load$RESPONSE_DATE,7,8), 
                                             substr(sample_sjoao_log_load$RESPONSE_DATE,3,6), 
                                             substr(sample_sjoao_log_load$RESPONSE_DATE,1,2), 
                                             substr(sample_sjoao_log_load$RESPONSE_DATE,9, 17), sep="")
range(sample_sjoao_log_load$REQUEST_DATE)

# sample_sjoao_log_load$REQUEST_LATITUDE <- gsub('\\,', '\\.', sample_sjoao_log_load$REQUEST_LATITUDE)
sample_sjoao_log_load$REQUEST_LONGITUDE <- str_split_fixed(sample_sjoao_log_load$REQUEST_DESC ," ",3)[,2]
# sample_sjoao_log_load$REQUEST_LONGITUDE <- gsub('\\,', '\\.', sample_sjoao_log_load$REQUEST_LONGITUDE)
range(sample_sjoao_log_load$REQUEST_LATITUDE)
range(sample_sjoao_log_load$REQUEST_LONGITUDE)

str(sample_sjoao_log_load)

# GetScheds - preparação para exportação para o PGAdmin

sample_sjoao_log_scheds$ID <- format(sample_sjoao_log_scheds$ID, scientific = FALSE) # garante que a notação não é científica
# retira as , do texto e substitui por espaço
sample_sjoao_log_scheds$REQUEST_DESC <- gsub('\\,', ' ',sample_sjoao_log_scheds$REQUEST_DESC)
sample_sjoao_log_scheds$RESPONSE_DESC <- gsub('\\,', ' ',sample_sjoao_log_scheds$RESPONSE_DESC)
# manipulate and convert date columns with caracter format to timestamp
# converter formato "19.06.23 15:26:37" para "23.06.19 15:26:37" para importação direta no pgadmin

sample_sjoao_log_scheds$REQUEST_DATE <- paste(substr(sample_sjoao_log_scheds$REQUEST_DATE,7,8), 
                                            substr(sample_sjoao_log_scheds$REQUEST_DATE,3,6), 
                                            substr(sample_sjoao_log_scheds$REQUEST_DATE,1,2), 
                                            substr(sample_sjoao_log_scheds$REQUEST_DATE,9, 17), sep="")
sample_sjoao_log_scheds$RESPONSE_DATE <- paste(substr(sample_sjoao_log_scheds$RESPONSE_DATE,7,8), 
                                             substr(sample_sjoao_log_scheds$RESPONSE_DATE,3,6), 
                                             substr(sample_sjoao_log_scheds$RESPONSE_DATE,1,2), 
                                             substr(sample_sjoao_log_scheds$RESPONSE_DATE,9, 17), sep="")
range(sample_sjoao_log_scheds$REQUEST_DATE)
sample_sjoao_log_scheds$REQUEST_LATITUDE<-0
sample_sjoao_log_scheds$REQUEST_LONGITUDE<-0



# Preparação data_rede ---------------------------------------------------------------------
# Data_rede
# load("C:/Users/pedro/Desktop/Silvia/Projeto II/Dados/data_rede.RData")

head(data_rede)
summary(data_rede)
str(data_rede)

#Convert Columns with categorical variables to Factor
for (i in 1:11) {data_rede[,i]<-as.factor(data_rede[,i])}
for (i in 13:ncol(data_rede)) {data_rede[,i]<-as.factor(data_rede[,i])}

summary(data_rede)
str(data_rede)
# assegura que código postal tem apenas códigos (ex. linha 903 com Perafita à frente do código postal)
data_rede$POSTAL_CODE<-substr(data_rede$POSTAL_CODE,1,8)
# retira as , do texto e substitui por espaço
data_rede$LINE_GO_NAME <- gsub('\\,', ' ', data_rede$LINE_GO_NAME)
data_rede$LINE_RETURN_NAME <- gsub('\\,', ' ', data_rede$LINE_RETURN_NAME)
data_rede$STOP_SHORTNAME <- gsub('\\,', ' ', data_rede$STOP_SHORTNAME)
data_rede$STOP_NAME <- gsub('\\,', ' ', data_rede$STOP_NAME)
data_rede2 <- data_rede[data_rede$PROVIDER_NAME == "STCP",]

# data_rede_unica
# Merge Data ---------------------------------------------------------------------
sum(duplicated(data_rede$STOP_KEY))
length(unique(data_rede$STOP_KEY))
length(data_rede$STOP_KEY)

# create a Simple data frame with only unique pairs of stop_keys and PostCodes
data_rede_Sel<-data_rede[,c("STOP_KEY","POSTAL_CODE", "STOP_LATITUDE", "STOP_LONGITUDE")]
data_rede_Sel$RepStop_Key<-0
data_rede_Sel$RepStop_Key[duplicated(data_rede_Sel$STOP_KEY)=="TRUE"]<-1
#check variable RepStop_key
data_rede_Sel<-data_rede_Sel[order(data_rede_Sel$STOP_KEY),]

data_rede_Sel<-data_rede_Sel[data_rede_Sel$RepStop_Key==0,]

mergedtable<-merge(x=sample_sjoao_log_scheds,y=data_rede_Sel, all.x = TRUE,by.x = c("REQUEST_DESC"),by.y = c("STOP_KEY"))
summary(mergedtable)

sample_sjoao_log_scheds$REQUEST_LATITUDE<-mergedtable$STOP_LATITUDE
sample_sjoao_log_scheds$REQUEST_LONGITUDE<-mergedtable$STOP_LONGITUDE

sample_sjoao_log_scheds <- na.omit(sample_sjoao_log_scheds)

# length(unique(mergedtable$POSTAL_CODE)) 
#

# Gravação ficheiros PGAdmin ---------------------------------------------------------------------
# gravação de ficheiros; para importação para o PGAdmin colocar os fix gravados em C:\tmp
write.csv(sample_sjoao_log_load,file = "sample_sjoao_log_load.csv", fileEncoding = "UTF8", quote = FALSE, row.names = FALSE)
write.csv(sample_sjoao_log_scheds,file = "sample_sjoao_log_scheds.csv", fileEncoding = "UTF8", quote = FALSE, row.names = FALSE)
