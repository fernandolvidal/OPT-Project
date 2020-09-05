#!/usr/bin/env python
# coding: utf-8

# In[1]:


pip install pandas-profiling


# In[1]:


# importing required packages
import pandas as pd
import pandas_profiling as pp
import numpy as np
import mysql.connector


# In[2]:


db_connection = mysql.connector.connect(
  host="vsrv01.inesctec.pt",
  user="a20182847",
  passwd="changeme",
  database="P2G11"
)


# In[3]:


db_cursor = db_connection.cursor()


# In[4]:


db_cursor.execute("Select ID, IP, USERNAME, TYPEOFREQUEST, REQUEST_DATE, RESPONSE_DATE, REQUEST_SERVICE, REQUEST_DESC, VOA_VERSION, TICKET, RESPONSE_DESC, VRSION, IS_RT from P2G11.DA_log_sample order by REQUEST_DATE LIMIT 50000")


# In[5]:


table_rows = db_cursor.fetchall()


# In[6]:


df = pd.DataFrame(table_rows, columns=['ID','IP','USERNAME','TYPEOFREQUEST','REQUEST_DATE','RESPONSE_DATE','REQUEST_SERVICE','REQUEST_DESC','VOA_VERSION','TICKET','RESPONSE_DESC','VRSION','IS_RT'])
print(df)


# In[7]:


df.profile_report(style={'full_width':True})
profile = df.profile_report(title='Pandas Profiling Report')
profile.to_file(output_file="C:\\00_PGBIA_BI\\P2G11_DA_log_sample.html")


# In[8]:


db_cursor.execute("Select PROVIDER_ID,PROVIDER_NAME,LINE_ID,LINE_CODE,LINE_GO_NAME,LINE_RETURN_NAME,PATH_ID,ORIENTATION,PATH_CODE,PATHSTOP_ID,PATHSTOP_STOPORDER,PATHSTOP_PREVDISTANCE,STOP_CODE,STOP_SHORTNAME,STOP_NAME,STOP_LATITUDE,STOP_LONGITUDE from P2G11.DA_rede_full")


# In[9]:


table_rows = db_cursor.fetchall()


# In[10]:


df = pd.DataFrame(table_rows, columns=['PROVIDER_ID','PROVIDER_NAME','LINE_ID','LINE_CODE','LINE_GO_NAME','LINE_RETURN_NAME','PATH_ID','ORIENTATION','PATH_CODE','PATHSTOP_ID','PATHSTOP_STOPORDER','PATHSTOP_PREVDISTANCE','STOP_CODE','STOP_SHORTNAME','STOP_NAME','STOP_LATITUDE','STOP_LONGITUDE'])
print(df)


# In[11]:


df.profile_report(style={'full_width':True})
profile = df.profile_report(title='Pandas Profiling Report')
profile.to_file(output_file="C:\\00_PGBIA_BI\\P2G11_DA_rede_full.html")


# In[12]:


db_cursor.close()
db_connection.close()

