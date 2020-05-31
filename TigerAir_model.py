#!/usr/bin/env python
# coding: utf-8

# In[129]:


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


# In[114]:


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


# In[115]:


# open file
stopwords_file = 'datafile/stop_words.txt'
jieba.set_dictionary('./dict.txt.big.txt')
jieba.load_userdict('datafile/user_dict.txt')
jieba.analyse.set_stop_words('datafile/stop_words.txt')
tigerair_file = 'datafile/tigerair_rawtext.txt'
tigerair_text = Openfile_sp(tigerair_file)
tiger_sta = 'datafile/tigerair.csv'


# In[4]:


dec = Openfile_sp(stopwords_file)
stopwords = set()
for i in range(len(dec)):
    stopwords.add(dec[i].strip())


# In[116]:


result = []
for i in range(len(tigerair_text)):
    r = lcut(tigerair_text[i], cut_all=False, HMM=False)
    result.append(r)


# In[117]:


adj_result = []
for i in range(len(result)):
    par = []
    for j in range(len(result[i])):
        if len(result[i][j]) > 1:
            if result[i][j] not in stopwords:
                par.append(result[i][j])
    adj_result.append(par)


# In[7]:


# frequency counter
c = Counter()
for i in range(len(adj_result)):
    for j in adj_result[i]:
        if len(j) > 1:
            c[j] += 1
freq_result = c.most_common(100)

df_freq = pd.DataFrame(freq_result)
df_freq.to_csv('datafile/tigerair_freqkey.csv')


# In[229]:


T_model = word2vec.Word2Vec(adj_result, size=300, min_count=10)
T_model.save("model/Tigerair_model.bin")


# In[230]:


# vec calculation
model = word2vec.Word2Vec.load("model/Tigerair_model.bin")
word_vectors = model.wv


# In[231]:


res = word_vectors.wv.most_similar('台灣虎航', topn = 20)


# In[232]:


res


# In[8]:


# vec calculation(only top 150 key result)
key_word = 'datafile/tigerair_keywords.csv'
df = pd.read_csv(key_word)
key = set()
df1 = df['key'].tolist()
for i in range(len(df1)):
    key.add(df1[i])
    
key_result = []
for i in range(len(adj_result)):
    par = []
    for j in range(len(adj_result[i])):
        if adj_result[i][j] in key:
            par.append(adj_result[i][j])
    key_result.append(par)


# In[86]:


# association
key_a = '注意事項'
key_b = df1
instances = 1599
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


# In[74]:


instance = 1599
new = []
assoc_key = []
for i in range(len(df1)):
    if df1[i] != key_a:
        assoc_key.append(df1[i])
for keylist in range(len(assoc_key)):
    counter = 0
    result = []
    for i in range(len(key_result)):
        if (key_a and assoc_key[keylist]) in key_result[i]:
            counter += 1
    assoc = counter / instance
    result.append(assoc_key[keylist])
    result.append(assoc)
    new.append(result)    
assoc_res = pd.DataFrame(new)
new_assoc_res = df.rename(columns={'0': 'tag', '1': 'assoc'})
new_assoc_res.sort_index(by = 'value', ascending=False)
new_assoc_res


# In[10]:


T_test_model = word2vec.Word2Vec(key_result, size=300, min_count=10)
T_test_model.save("model/Tigerair_key_model.bin")


# In[11]:


key_model = word2vec.Word2Vec.load("model/Tigerair_key_model.bin")
word_vectors = key_model.wv


# In[13]:


res = word_vectors.wv.most_similar('台灣虎航', topn = 30)


# In[14]:


res


# In[124]:


# text analysis
product = set()
price = set()
place = set()
depart = set()
company = set()
question = set()
prize = set()


product_key = ['航班', '機票', '訂位', '機場', '搭乘', '起飛', 'depart', '出發', '機位', 
               '航線', '機位數', '航點']
price_key = ['TWD', '優惠', '單程', '未稅', '機場稅', '優惠價', '金額', '票價', '元起']
place_key = ['澳門', '東京', '日本', '沖繩', '大阪', '名古屋', '岡山', '成田', '福岡', 
             '大邱', '曼谷']
depart_key = ['台北', '高雄']
company_key = ['tigerair.com']
prize_key = ['免費', '機會', '獲得', '得獎', '得獎者', '抽獎', '中獎']
question_key = ['?', '？']


for i in range(len(product_key)):
    product.add(product_key[i])
for i in range(len(price_key)):
    price.add(price_key[i])
for i in range(len(place_key)):
    place.add(place_key[i])
for i in range(len(depart_key)):
    depart.add(depart_key[i])
for i in range(len(company_key)):
    company.add(company_key[i])
for i in range(len(question_key)):
    question.add(question_key[i])
for i in range(len(prize_key)):
    prize.add(prize_key[i])


# In[166]:


output_res = []
ID = tiger_data['post_id'].tolist()
for i in range(len(result)):
    product_count = 0
    price_count = 0
    place_count = 0
    depart_count = 0
    prize_count = 0
    question_count = 0
    n_ID = ID[i]
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


# In[168]:


res_df = pd.DataFrame(output_res)
res_df.to_csv('./Tiger_data.csv')


# In[125]:


counter = 0
for i in range(len(key_result)):
    for j in range(len(key_result[i])):
        if key_result[i][j] in prize:
            counter += 1
            break
text_ana_res = counter / instances
text_ana_res


# In[123]:


counter1 = 0
for i in range(len(result)):
    for j in range(len(result[i])):
        if result[i][j] in question:
            counter1 += 1
            break
text_ana_res1 = counter1 / instances
text_ana_res1


# In[141]:


tiger_data = pd.read_csv(tiger_sta)

post_type = tiger_data['type'].tolist()
print(post_type.count('photo') / instances, 
      post_type.count('video') / instances,
      post_type.count('link') / instances)
publish = tiger_data['post_published'].tolist()
df_publish = tiger_data['post_published']
df_publish.to_csv('./T_time.csv')
adj_publish = []
for i in range(len(publish)):
    adj_time = publish[i].replace('T', ' ').replace('+0000', '')
    time = datetime.strptime(adj_time, "%Y-%m-%d %H:%M:%S")
    adj_publish.append(time)


# In[ ]:




