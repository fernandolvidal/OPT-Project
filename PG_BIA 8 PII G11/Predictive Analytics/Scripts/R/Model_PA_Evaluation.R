# Evaluation ------------------------------------------------------------------------------

df_teste<-read.csv('C:/D_Mcd/PBSchool/30-Tri_3/306-PROJ_BIA2/d-Scripts/R/PA/Models_Results.csv',sep = ",",header = TRUE);

df_treino<-read.csv('C:/D_Mcd/PBSchool/30-Tri_3/306-PROJ_BIA2/d-Scripts/R/PA/df_treino.csv',sep = ",",header = TRUE);

#Baseline 1, Tipo do REQUEST_SERVICE que mais ocorre no dataset treino - Accuracy Rate

table(df_treino$REQUEST_SERVICE); 
summary(df_treino)
df_teste$baseline1<-'LoadStopsWithinNM'
df_teste$baseline1<-as.factor(df_teste$baseline1)

table(df_teste$REQUEST_SERVICE,df_teste$baseline1)
Taxa_Acerto_BS1<-596110/(length(df_teste$REQUEST_SERVICE))
Taxa_Acerto_BS1

#calculo baseline 2, REQUEST_SERVICE que mais ocorre por TICKET
library(dplyr)

df_treino<-df_treino[order(df_treino$TICKET,df_treino$REQUEST_DATE),]
df_treino$bs2<-as.factor(unlist(tapply(df_treino$REQUEST_SERVICE, INDEX = df_treino$TICKET, FUN= function(x) rep(names(which.max(table(x))),length(x)))))
df_treino<-df_treino[,c('TICKET','bs2')]

df_treino$RepTicket<-0
df_treino$RepTicket[duplicated(df_treino$TICKET)=="TRUE"]=1
#duplicada<-duplicated(df_treino)
df_treino<-df_treino[df_treino$RepTicket=="0",]
df_treino<-df_treino[,c('TICKET','bs2')]

df_teste_final<- left_join(df_teste,df_treino,by='TICKET')
summary(df_teste_final)

is.na_replace_0<- df_teste_final$bs2
is.na_replace_0[is.na(is.na_replace_0)] <-"LoadStopsWithinNM"
df_teste_final$bs2<- is.na_replace_0
rm(is.na_replace_0)
summary(df_teste_final)

#comparaçao resultados - Accuracy Rate

## Baseline 2 - Accuracy Rate
df_teste_final$Acerto_BS2<-0
df_teste_final$Acerto_BS2<-as.factor(ifelse(df_teste_final$bs2==df_teste_final$REQUEST_SERVICE,1,0))
table(df_teste_final$REQUEST_SERVICE,df_teste_final$Acerto_BS2)
summary(df_teste_final$Acerto_BS2)

confMatrix_BS2<-table(df_teste_final$REQUEST_SERVICE,df_teste_final$bs2)
confMatrix_BS2
Taxa_Acerto_BS2<-(sum(diag(confMatrix_BS2)))/(sum(confMatrix_BS2))

## DecisionTree - Accuracy Rate
confMatrix_DT<-table(df_teste_final$REQUEST_SERVICE,df_teste_final$Predict.Decision.Tree)
confMatrix_DT
Taxa_Acerto_DT<-(sum(diag(confMatrix_DT)))/(sum(confMatrix_DT))

## RandomForest - Accuracy Rate
confMatrix_RF<-table(df_teste_final$REQUEST_SERVICE,df_teste_final$Random.Forest.Predict)
confMatrix_RF
Taxa_Acerto_RF<-(497818+361529)/(sum(confMatrix_RF))

## SVC - Accuracy Rate
confMatrix_SVC<-table(df_teste_final$REQUEST_SERVICE,df_teste_final$SVC.predicts)
confMatrix_SVC
Taxa_Acerto_SVC<-(sum(diag(confMatrix_SVC)))/(sum(confMatrix_SVC))
Taxa_Acerto_SVC


# Temp---------------------------------------------------
#df_final$acerto_tree<-ifelse(df_final$Predict.Decision.Tree==df_final$Answer,1,0)
#table(df_final$acerto_tree)
#df_final$acerto_rf<-ifelse(df_final$Predict.Random.Forest==df_final$Answer,1,0)
#df_final$svc<-ifelse(df_final$Predict.svc==df_final$Answer,1,0)
#table(df_final$acerto_tree)svc


