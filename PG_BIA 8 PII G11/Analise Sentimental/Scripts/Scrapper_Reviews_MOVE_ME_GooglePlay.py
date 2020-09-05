#!/usr/bin/env python
# coding: utf-8

# In[100]:


pip install google-play-scraper


# In[101]:


from google_play_scraper import app


# In[102]:


result = app(
    'com.moveme',
    lang='pt', # defaults to 'en'
    country='us' # defaults to 'us'
)


# In[103]:


print(result)


# In[ ]:




