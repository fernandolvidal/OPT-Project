#!/usr/bin/env python
# coding: utf-8

# In[68]:


import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from textblob import TextBlob
import re
from nltk.corpus import stopwords
from nltk.stem.wordnet import WordNetLemmatizer
from sklearn.feature_extraction.text import CountVectorizer, TfidfTransformer
from sklearn.naive_bayes import MultinomialNB
from sklearn.model_selection import train_test_split
from sklearn.pipeline import Pipeline
from sklearn.metrics import confusion_matrix, classification_report,accuracy_score


# In[201]:


train_tweets = pd.read_csv('C:\\Temp\\train_tweets_NEW.csv')
train_tweets.head()


# In[202]:


test_tweets = pd.read_csv('C:\\Temp\\test_tweets_NEW.csv')
test_tweets.head()


# In[203]:


train_tweets = train_tweets[['label','tweet']]
train_tweets.head()


# In[204]:


test = test_tweets['tweet']
test.head()


# In[205]:


train_tweets['length'] = train_tweets['tweet'].apply(len)
fig1 = sns.barplot('label','length',data = train_tweets,palette='PRGn')
plt.title('Average Word Length vs label')
fig2 = sns.countplot(x= 'label',data = train_tweets)
plt.title('Label Counts')
plot = fig2.get_figure()
plot.savefig('Count Plot.png')
plot = fig1.get_figure()
plot.savefig('Barplot.png')


# In[206]:


fig2 = sns.countplot(x= 'label',data = train_tweets)
plt.title('Label Counts')
plot = fig2.get_figure()
plot.savefig('Count Plot.png')


# In[207]:


def form_sentence(tweet):
    tweet_blob = TextBlob(tweet)
    return ' '.join(tweet_blob.words)
print(form_sentence(train_tweets['tweet'].iloc[10]))
print(train_tweets['tweet'].iloc[10])


# In[208]:


print(form_sentence(train_tweets['tweet'].iloc[1]))
print(train_tweets['tweet'].iloc[1])


# In[209]:


def no_user_alpha(tweet):
    tweet_list = [ele for ele in tweet.split() if ele != 'user']
    clean_tokens = [t for t in tweet_list if re.match(r'[^\W\d]*$', t)]
    clean_s = ' '.join(clean_tokens)
    clean_mess = [word for word in clean_s.split() if word.lower() not in stopwords.words('portuguese')]
    return clean_mess

print(no_user_alpha(form_sentence(train_tweets['tweet'].iloc[10])))
print(train_tweets['tweet'].iloc[10])


# In[210]:


print(no_user_alpha(form_sentence(train_tweets['tweet'].iloc[1])))
print(train_tweets['tweet'].iloc[1])


# In[211]:


def normalization(tweet_list):
        lem = WordNetLemmatizer()
        normalized_tweet = []
        for word in tweet_list:
            normalized_text = lem.lemmatize(word,'v')
            normalized_tweet.append(normalized_text)
        return normalized_tweet
    
tweet_list = 'A aplicação é realmente muito boa'.split()
print(normalization(tweet_list))


# In[212]:


def text_processing(tweet):
    
    #Generating the list of words in the tweet (hastags and other punctuations removed)
    def form_sentence(tweet):
        tweet_blob = TextBlob(tweet)
        return ' '.join(tweet_blob.words)
    new_tweet = form_sentence(tweet)
    
    #Removing stopwords and words with unusual symbols
    def no_user_alpha(tweet):
        tweet_list = [ele for ele in tweet.split() if ele != 'user']
        clean_tokens = [t for t in tweet_list if re.match(r'[^\W\d]*$', t)]
        clean_s = ' '.join(clean_tokens)
        clean_mess = [word for word in clean_s.split() if word.lower() not in stopwords.words('portuguese')]
        return clean_mess
    no_punc_tweet = no_user_alpha(new_tweet)
    
    #Normalizing the words in tweets 
    def normalization(tweet_list):
        lem = WordNetLemmatizer()
        normalized_tweet = []
        for word in tweet_list:
            normalized_text = lem.lemmatize(word,'v')
            normalized_tweet.append(normalized_text)
        return normalized_tweet
    
    
    return normalization(no_punc_tweet)


# In[213]:


train_tweets['tweet_list'] = train_tweets['tweet'].apply(text_processing)
test_tweets['tweet_list'] = test_tweets['tweet'].apply(text_processing)


# In[214]:


train_tweets.head()


# In[215]:


test_tweets.head()


# In[216]:


train_tweets[train_tweets['label']==1].drop('tweet',axis=1).head()


# In[217]:


X = train_tweets['tweet']
y = train_tweets['label']
test = test_tweets['tweet']


# In[218]:


print(X)
print(y)
test.head()


# In[219]:


from sklearn.model_selection import train_test_split
msg_train, msg_test, label_train, label_test = train_test_split(train_tweets['tweet'], train_tweets['label'], test_size=0.2)


# In[220]:


pipeline = Pipeline([
    ('bow',CountVectorizer(analyzer=text_processing)),  # strings to token integer counts
    ('tfidf', TfidfTransformer()),  # integer counts to weighted TF-IDF scores
    ('classifier', MultinomialNB()),  # train on TF-IDF vectors w/ Naive Bayes classifier
])


# In[221]:


msg_train.head()


# In[222]:


msg_test.head()


# In[223]:


label_train.head()


# In[224]:


label_test.head()


# In[225]:


pipeline.fit(msg_train,label_train)


# In[227]:


msg_test.head()


# In[185]:


predictions = pipeline.predict(msg_test)

print(classification_report(predictions,label_test))
print ('\n')
print(confusion_matrix(predictions,label_test))
print(accuracy_score(predictions,label_test))
label_test.head()


# In[229]:


print(label_test)


# In[ ]:




