####---GET START---####

#open_libraries
library(stringi)
library(stringr)

# clean_variables
# rm(list=ls())

# resources
gc()

#work_directory
# setwd("C:/Users/pedro/Desktop/Silvia/Projeto II/Dados")
setwd("C:/Users/pedro/Desktop/Silvia/Projeto II/P2G11 S_Joao/RDatas")


####---GET INFORMATION---####
# Data_rede
load("data_rede.RData")

# Limpeza e Preparação data_rede ---------------------------------------------------------------------

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

# Gravação ficheiros PGAdmin ---------------------------------------------------------------------
# gravação de ficheiros; para importação para o PGAdmin colocar os fix gravados em C:\tmp
write.csv(data_rede2,file = "dim_rede.csv", fileEncoding = "UTF8")
