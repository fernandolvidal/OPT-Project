#!/usr/bin/env python
# coding: utf-8

# In[105]:


import reverse_geocoder as rg


# In[419]:


coordinates =(41.2167015100,-8.5536823270),(41.1926918000,-8.5810632710),(41.2042617800,-8.5967512130),


# In[420]:


rg.search(coordinates)


# In[561]:


import mysql.connector


# In[3]:


pip install mysql.connector


# In[11]:


import mysql.connector
import json 


# In[12]:


db_connection = mysql.connector.connect(
  host="vsrv01.inesctec.pt",
  user="a20182847",
  passwd="changeme",
  database="P2G11"
)


# In[13]:


import time


# In[14]:


db_cursor = db_connection.cursor()
from geopy.geocoders import Nominatim
geolocator = Nominatim(user_agent="05DEZ")
import pandas as pd


# In[134]:


db_cursor.execute("Select distinct(CONCAT_LAT_LON) from Dim_GEO_LAT_LON_Detail where POSTAL_CODE is null limit 300")


# In[135]:


table_rows = db_cursor.fetchall()
df = pd.DataFrame(table_rows, columns=['LAT_LON'])
df["RAW_DATA"] = ""


# In[136]:


for row in df.index:
    location = geolocator.reverse(df.loc[row, 'LAT_LON'])  
    loc = location.raw
    raw_data = loc['address']
    aux=df.loc[row, 'LAT_LON']
    try:        
        fieldpairs = ','.join(['{0} {1}'.format(key, value) for (key, value) in raw_data.items()])
        str = "UPDATE Dim_GEO_LAT_LON_Detail SET RAW_DATA = \""+fieldpairs+"\" WHERE CONCAT_LAT_LON =\""+aux+"\""
        db_cursor.execute(str)
        db_connection.commit()
        postcode=location.raw['address']['postcode']
        str = "UPDATE Dim_GEO_LAT_LON_Detail SET POSTAL_CODE= \""+postcode+"\" WHERE CONCAT_LAT_LON =\""+aux+"\""
        db_cursor.execute(str)
        db_connection.commit()
        print(str)
    except Exception as ex: 
        aux= df.loc[row, 'LAT_LON']
        str = "UPDATE Dim_GEO_LAT_LON_Detail SET POSTAL_CODE= \"ERROR\" WHERE CONCAT_LAT_LON =\""+aux+"\""
        db_cursor.execute(str)
        db_connection.commit()
        print(ex)
    time.sleep(1.1) 
print("FIM!")


# In[58]:


print (df)


# In[ ]:


export_csv = df.to_csv (r'C:\\00_PGBIA_BI\\FileName.csv', index = None, header=True)


# In[580]:


db_cursor.close()
db_connection.close()


# In[ ]:




