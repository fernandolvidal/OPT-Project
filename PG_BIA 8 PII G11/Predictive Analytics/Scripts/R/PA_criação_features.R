library(stringi);
library(stringr);
library(dplyr);
library(lubridate);
#do data set limpo "PA_DatasetClean" pegando apenas as colunas que interessam para PA: TICKET, REQUEST_DATE,REQUEST_SERVICE
df<-DataSet_pa[,2:4];
#ordenando por REQUEST_DATE e TICKET
df$REQUEST_DATE<-ymd_hms(df$REQUEST_DATE);

df<-df[order(df$TICKET,df$REQUEST_DATE),];

#fazendo features de dia da semana.
df$day <- as.POSIXlt(as.Date(df$REQUEST_DATE,format = "%y.%m.%d %H:%M:%S"))$wday;
#feature hora para em seguida fazer a feature de parte do dia
df$hour <-as.numeric(format(as.POSIXct(df$REQUEST_DATE,format="%y.%m.%d %H:%M:%S"),"%H"));
#feature parte do dia
df$part_of_the_day <- ifelse(df$hour<13 & df$hour>6 ,1,ifelse(df$hour>13 & df$hour<18,2,ifelse(df$hour>18 & df$hour<24,3,0)));
#feature dia útil
df$dia_util <- ifelse(df$day==6 | df$day==0,0,1);
#feature diff time
df$diff <-unlist(tapply(df$REQUEST_DATE,INDEX = df$TICKET,FUN=function(x) c(NA,diff(x))));
#feature mean diff, média de diferença entre pedidos de cada ticket
df$mean_diff<-unlist(tapply(df$diff,INDEX = df$TICKET, FUN=function(x) rep(mean(x, na.rm=TRUE),length(x))));
#feature desvio padrão
df$sd_diff<-unlist(tapply(df$diff,INDEX = df$TICKET, FUN=function(x) rep(sd(x, na.rm=TRUE),length(x))));
#feature número acumulativo de pedidos por TICKET
df$count<-unlist(tapply(df$REQUEST_SERVICE,INDEX = df$TICKET, FUN=function(x) seq(1:length(x))));




#Ligação com a BD para pegar o histórico de METEO
drv<-dbDriver("MySQL");
#Connecting to the DBMS
con<-dbConnect(drv, dbname="P2G11", bigint="character", username="a20182403", password="changeme", host="vsrv01.inesctec.pt",port=3306);

meteo<-dbGetQuery(con,"SELECT * FROM STG_Hist_Meteo");

#criando variável de ligação entre as tabelas meteo e a nossa base

df$day_hour <-(format(as.POSIXct(df$REQUEST_DATE,format="%y.%m.%d %H:%M:%S"),"%y-%m-%d %H"));

meteo$day_hour <-(format(as.POSIXct(meteo$datahora,format="%Y-%m-%d %H:%M:%S"),"%y-%m-%d %H"));

#join entre as duas pelo dia_hora e obtemos as features meteorologicas do Porto
sample <- left_join(df,meteo, by='day_hour');

sample$summary<-ifelse(sample$summary=="Limpo",0,ifelse(sample$summary=="Nublado",2,ifelse(sample$summary=="Ligeiramente Nublado",1,ifelse(sample$summary=="Muito Nublado",3,4))));


sample$day_hour<-NULL;
sample$datahora<-NULL;
sample$DESC_CONCELHO<-NULL;
sample$Day_hour_format<-NULL;

sample$TICKET<-as.factor(sample$TICKET);
sample$day<-as.factor(sample$day);
sample$dia_util<-as.factor(sample$dia_util);
sample$part_of_the_day<-as.factor(sample$part_of_the_day);
sample$summary<-as.factor(sample$summary);
sample$REQUEST_SERVICE<-as.factor(sample$REQUEST_SERVICE);
sample$hour<-as.factor(sample$hour);
sample$temperature<-as.numeric(sample$temperature);
sample$precipProbability<-as.numeric(sample$precipProbability);
sample$count<-as.numeric(sample$count);
sample<-na.omit(sample);

sample<-sample[order(sample$REQUEST_DATE),];

write.csv(sample, "C:/Users/ferna/Desktop/PA_sample.csv")






