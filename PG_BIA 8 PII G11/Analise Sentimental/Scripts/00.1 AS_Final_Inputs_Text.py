#!/usr/bin/env python
# coding: utf-8

# In[1]:


import nltk
nltk.download('punkt')


# In[2]:


nltk.download('twitter_samples')


# In[3]:


from nltk.corpus import twitter_samples


# In[4]:


positive_tweets = twitter_samples.strings('positive_tweets.json')
negative_tweets = twitter_samples.strings('negative_tweets.json')
text = twitter_samples.strings('tweets.20150430-223406.json')


# In[5]:


positive_tweets


# In[6]:


negative_tweets


# In[7]:


tweet_tokens = twitter_samples.tokenized('positive_tweets.json')


# In[8]:


tweet_tokens


# In[9]:


nltk.download('wordnet')
nltk.download('averaged_perceptron_tagger')


# In[10]:


from nltk.tag import pos_tag
from nltk.corpus import twitter_samples

tweet_tokens = twitter_samples.tokenized('positive_tweets.json')
print(pos_tag(tweet_tokens[0]))


# In[11]:


from nltk.tag import pos_tag
from nltk.stem.wordnet import WordNetLemmatizer

def lemmatize_sentence(tokens):
    lemmatizer = WordNetLemmatizer()
    lemmatized_sentence = []
    for word, tag in pos_tag(tokens):
        if tag.startswith('NN'):
            pos = 'n'
        elif tag.startswith('VB'):
            pos = 'v'
        else:
            pos = 'a'
        lemmatized_sentence.append(lemmatizer.lemmatize(word, pos))
    return lemmatized_sentence

print(lemmatize_sentence(tweet_tokens[0]))


# In[12]:


import re, string

def remove_noise(tweet_tokens, stop_words = ()):

    cleaned_tokens = []

    for token, tag in pos_tag(tweet_tokens):
        token = re.sub('http[s]?://(?:[a-zA-Z]|[0-9]|[$-_@.&+#]|[!*\(\),]|'                       '(?:%[0-9a-fA-F][0-9a-fA-F]))+','', token)
        token = re.sub("(@[A-Za-z0-9_]+)","", token)

        if tag.startswith("NN"):
            pos = 'n'
        elif tag.startswith('VB'):
            pos = 'v'
        else:
            pos = 'a'

        lemmatizer = WordNetLemmatizer()
        token = lemmatizer.lemmatize(token, pos)

        if len(token) > 0 and token not in string.punctuation and token.lower() not in stop_words:
            cleaned_tokens.append(token.lower())
    return cleaned_tokens


# In[13]:


nltk.download('stopwords')


# In[14]:


from nltk.corpus import stopwords
stop_words = stopwords.words('english')

print(remove_noise(tweet_tokens[0], stop_words))


# In[15]:


from nltk.corpus import stopwords
stop_words = stopwords.words('english')


# In[16]:


positive_tweet_tokens = twitter_samples.tokenized('positive_tweets.json')
negative_tweet_tokens = twitter_samples.tokenized('negative_tweets.json')

positive_cleaned_tokens_list = []
negative_cleaned_tokens_list = []

for tokens in positive_tweet_tokens:
    positive_cleaned_tokens_list.append(remove_noise(tokens, stop_words))

for tokens in negative_tweet_tokens:
    negative_cleaned_tokens_list.append(remove_noise(tokens, stop_words))


# In[17]:


print(positive_tweet_tokens[500])


# In[18]:


print(positive_cleaned_tokens_list[500])


# In[19]:


def get_all_words(cleaned_tokens_list):
    for tokens in cleaned_tokens_list:
        for token in tokens:
            yield token

all_pos_words = get_all_words(positive_cleaned_tokens_list)


# In[20]:


from nltk import FreqDist

freq_dist_pos = FreqDist(all_pos_words)
print(freq_dist_pos.most_common(10))


# In[21]:


def get_tweets_for_model(cleaned_tokens_list):
    for tweet_tokens in cleaned_tokens_list:
        yield dict([token, True] for token in tweet_tokens)

positive_tokens_for_model = get_tweets_for_model(positive_cleaned_tokens_list)
negative_tokens_for_model = get_tweets_for_model(negative_cleaned_tokens_list)


# In[22]:


import random

positive_dataset = [(tweet_dict, "Positive")
                     for tweet_dict in positive_tokens_for_model]

negative_dataset = [(tweet_dict, "Negative")
                     for tweet_dict in negative_tokens_for_model]

dataset = positive_dataset + negative_dataset

random.shuffle(dataset)

train_data = dataset[:7000]
test_data = dataset[7000:]


# In[23]:


dataset


# In[24]:


from nltk.classify.scikitlearn import SklearnClassifier


# In[43]:


from nltk import classify
from nltk import NaiveBayesClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC, LinearSVC

classifier = NaiveBayesClassifier.train(train_data)
print("NaiveBayes_classifier accuracy is:", classify.accuracy(classifier, test_data))
#print(classifier.show_most_informative_features(10))

LogisticRegression_classifier = SklearnClassifier(LogisticRegression(solver='lbfgs'))
LogisticRegression_classifier.train(train_data)
print("LogisticRegression_classifier accuracy is:", (nltk.classify.accuracy(LogisticRegression_classifier, test_data)))


SVC_classifier = SklearnClassifier(SVC(gamma='auto'))
SVC_classifier.train(train_data)
print("SVC_classifier accuracy percent:", (nltk.classify.accuracy(SVC_classifier, test_data)))

LinearSVC_classifier = SklearnClassifier(LinearSVC())
LinearSVC_classifier.train(train_data)
print("LinearSVC_classifier accuracy percent:", (nltk.classify.accuracy(LinearSVC_classifier, test_data)))


# In[43]:


from nltk.tokenize import word_tokenize

custom_tweet = "The MOVE-ME APP is very cool and usefull"

custom_tokens = remove_noise(word_tokenize(custom_tweet))

print(classifier.classify(dict([token, True] for token in custom_tokens)))


# In[45]:


from nltk.tokenize import word_tokenize

custom_tweet = "Sometimes, the MOVE-ME APP doesn't perform."

custom_tokens = remove_noise(word_tokenize(custom_tweet))

print(classifier.classify(dict([token, True] for token in custom_tokens)))


# In[ ]:




