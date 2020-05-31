#!/usr/bin/env python
# coding: utf-8

# In[65]:


import matplotlib.pyplot as plt
import pandas as pd
import numpy as np
import jieba
from jieba import lcut, analyse, Tokenizer
from wordcloud import WordCloud, STOPWORDS
from gensim.models import word2vec
from gensim.models.keyedvectors import KeyedVectors
from collections import Counter
from datetime import datetime


# In[2]:


def Openfile(path):
    f = open(path, "r", encoding="utf-8")
    result = f.read()
    f.close()
    return result
def Openfile_sp(path):
    f = open(path, "r", encoding="utf-8")
    result = f.readlines()
    f.close()
    return result


# In[47]:


# open file
stopwords_file = 'datafile/stop_words.txt'
jieba.set_dictionary('./dict.txt.big.txt')
jieba.load_userdict('datafile/user_dict.txt')
jieba.analyse.set_stop_words('datafile/stop_words.txt')

evaair_file = 'datafile/EvaAir_text.csv'
eva_sta = 'datafile/EvaAir_sta.csv'
df = pd.read_csv(evaair_file)


# In[4]:


dec = Openfile_sp(stopwords_file)
stopwords = set()
for i in range(len(dec)):
    stopwords.add(dec[i].strip())


# In[5]:


df1 = df['text'].tolist()
for i in range(len(df1)):
    if isinstance(df1[i], float):
        df1[i] = str(df1[i])
evaair_text = []
for i in range(len(df1)):
    evaair_text.append(df1[i].strip())


# In[43]:


result = []
for i in range(len(evaair_text)):
    r = lcut(evaair_text[i], cut_all=False, HMM=False)
    result.append(r)
    
adj_result = []
for i in range(len(result)):
    par = []
    for j in range(len(result[i])):
        if len(result[i][j]) > 1:
            if result[i][j] not in stopwords:
                par.append(result[i][j])
    adj_result.append(par)


# In[44]:


# frequency counter
c = Counter()
for i in range(len(adj_result)):
    for j in adj_result[i]:
        if len(j) > 1:
            c[j] += 1
freq_result = c.most_common(100)

df_freq = pd.DataFrame(freq_result)
df_freq.to_csv('datafile/evaair_freqkey.csv')


# In[77]:


E_model = word2vec.Word2Vec(adj_result, size=200, min_count=10)
E_model.save("model/EvaAir_model.bin")


# In[101]:


model = word2vec.Word2Vec.load("model/EvaAir_model.bin")
word_vectors = model.wv


# In[102]:


res = word_vectors.wv.most_similar('長榮航空', topn = 20)


# In[103]:


res


# In[8]:


# test part
key_word = 'datafile/evaair_keywords.csv'
df = pd.read_csv(key_word)
df1 = df['key'].tolist()
key = set()
for i in range(len(df1)):
    key.add(df1[i])
    
key_result = []
for i in range(len(adj_result)):
    par = []
    for j in range(len(adj_result[i])):
        if adj_result[i][j] in key:
            par.append(adj_result[i][j])
    key_result.append(par)


# In[34]:


# key association 

key_a = '旅遊'
key_b = df1
instances = 1665
assoc_result = []
for j in range(len(key_b)):
    counter = 0
    r_counter = 0
    out_put = []
    for i1 in range(len(key_result)):
        if key_a in key_result[i1]:
            r_counter += 1
            continue
    for i2 in range(len(key_result)):
        if ((key_result[i2].count(key_a) > 0) and (key_result[i2].count(key_b[j]) > 0)):
            counter += 1
    result = counter / r_counter
    out_put.append(key_b[j])
    out_put.append(result)
    assoc_result.append(out_put)

assoc_result_adj = []
for i in range(len(assoc_result)):
    for j in range(len(assoc_result[i])):
        if assoc_result[i][1] >= 0.1:
            assoc_result_adj.append(assoc_result[i])
            break

new_assoc_result = sorted(assoc_result_adj, key=lambda I:I[1], reverse=True)
new_assoc_result


# In[9]:


E_test_model = word2vec.Word2Vec(key_result, size=300, min_count=10)
E_test_model.save("model/Evaair_key_model.bin")


# In[10]:


key_model = word2vec.Word2Vec.load("model/Evaair_key_model.bin")
word_vectors = key_model.wv


# In[11]:


res = word_vectors.wv.most_similar('長榮航空', topn = 30)


# In[12]:


res


# In[37]:


# text analysis
product = set()
price = set()
place = set()
depart = set()
company = set()
question = set()
prize = set()


product_key = ['航班', '航線', '班機', '飛航', '服務', '機上', 'Kitty', '搭乘', '彩繪機', 
               '體驗', '787', '經濟艙']
price_key = ['TWD', '優惠']
place_key = ['美國', '東京', '日本', '沖繩', '香港']
depart_key = ['台北', '高雄']
prize_key = ['免費', '機會', '獲得', '得獎', '得獎者', '抽獎', '好康', '參加']
question_key = ['?', '？']


for i in range(len(product_key)):
    product.add(product_key[i])
for i in range(len(price_key)):
    price.add(price_key[i])
for i in range(len(place_key)):
    place.add(place_key[i])
for i in range(len(depart_key)):
    depart.add(depart_key[i])
for i in range(len(question_key)):
    question.add(question_key[i])
for i in range(len(prize_key)):
    prize.add(prize_key[i])


# In[46]:


counter = 0
for i in range(len(key_result)):
    for j in range(len(key_result[i])):
        if key_result[i][j] in prize:
            counter += 1
            break
text_ana_res = counter / instances
text_ana_res


# In[45]:


counter1 = 0
for i in range(len(result)):
    for j in range(len(result[i])):
        if result[i][j] in question:
            counter1 += 1
            break
text_ana_res1 = counter1 / instances
text_ana_res1


# In[88]:


output_res = []
text_df = pd.read_csv('datafile/EvaAir_text.csv')
ID = text_df['no'].tolist()
for i in range(len(result)):
    n_ID = ID[i]
    product_count = 0
    price_count = 0
    place_count = 0
    depart_count = 0
    prize_count = 0
    question_count = 0
    for j in range(len(result[i])):
        if result[i][j] in product:
            product_count += 1
            continue
        if result[i][j] in price:
            price_count += 1
            continue
        if result[i][j] in place:
            place_count += 1
            continue
        if result[i][j] in depart:
            depart_count += 1
            continue
        if result[i][j] in prize:
            prize_count += 1
            continue
        if result[i][j] in question:
            question_count += 1
            continue
        process = [n_ID, product_count, price_count, place_count, 
                   depart_count, prize_count, question_count]
    output_res.append(process)


# In[90]:


res_df = pd.DataFrame(output_res)
res_df.to_csv('./Eva_data.csv')


# In[ ]:





# In[ ]:




