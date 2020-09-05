#!/usr/bin/env python
# coding: utf-8

# In[1]:


pip install python-forecastio


# In[2]:


import datetime
import pandas as pd
import forecastio
import getpass


# In[3]:


lat = 41.14961
lng = -8.61099


# In[4]:


date = datetime.datetime(2019,4,1)


# In[5]:


forecast = forecastio.load_forecast('b46ebf303e720a75953d949dd7318bc9', lat, lng, time=date, units="uk")


# In[6]:


forecast


# In[7]:


hourly = forecast.hourly()


# In[8]:


hourly.data


# In[9]:


hourly.data[0].d


# In[10]:


attributes = ["summary","temperature","precipProbability"]


# In[11]:


times = []
data = {}
for attr in attributes:
    data[attr] = []


# In[12]:


start = datetime.datetime(2019, 4, 1)
for offset in range(1, 10):
    forecast = forecastio.load_forecast('b46ebf303e720a75953d949dd7318bc9', lat, lng, time=start+datetime.timedelta(offset), lang='PT')
    h = forecast.hourly()
    d = h.data
    for p in d:
        times.append(p.time)
        for attr in attributes:
            data[attr].append(p.d[attr])


# In[27]:


df = pd.DataFrame(data, index=times)
df.insert(0, 'DESC_CONCELHO', 'PORTO')


# In[28]:


print(df)


# In[22]:


import sqlalchemy


# In[15]:


df.head()  


# In[19]:


df.columns = ['DESC_CONCELHO', 'DESC_TEMPO', 'TEMPERATURA', 'PROB_PRECIPITACAO']


# In[20]:


df.head()  


# In[23]:


database_username = 'a20182847'
database_password = 'changeme'
database_ip       = 'vsrv01.inesctec.pt'
database_name     = 'P2G11'
database_connection = sqlalchemy.create_engine('mysql+mysqlconnector://{0}:{1}@{2}/{3}'.
                                               format(database_username, database_password, 
                                                      database_ip, database_name))


# In[24]:


df.to_sql(con=database_connection, name='STG_Hist_Meteo_2', if_exists='replace')


# In[97]:


del df


# In[ ]:




