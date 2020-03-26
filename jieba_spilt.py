import jieba
from jieba import lcut, analyse, Tokenizer
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
from wordcloud import WordCloud, STOPWORDS

def Keyword_Finder(keywords):
    for item in keywords:
        print(item[0], item[1])
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

# open file

stopwords_file = 'datafile/stop_words.txt'
jieba.set_dictionary('./dict.txt.big.txt')
jieba.load_userdict('datafile/user_dict.txt')
jieba.analyse.set_stop_words('datafile/stop_words.txt')
tigerair_file = 'datafile/tigerair_rawtext.txt'
evaair_file = 'datafile/EvaAir_text.txt'

tigerair_text = Openfile(tigerair_file)
evaair_text = Openfile(evaair_file)


# cut text

r = lcut(tigerair_text, cut_all=False, HMM=False)
tigerair_keywords = analyse.extract_tags(tigerair_text, topK=150, withWeight=True)

r1 = lcut(evaair_text, cut_all=False, HMM=False)
evaair_keywords = analyse.extract_tags(evaair_text, topK=150, withWeight=True)

cut1 = jieba.cut(tigerair_text, cut_all=True, HMM=False)
cut1_sp = " ".join(cut1)

cut2 = jieba.cut(evaair_text, cut_all=True, HMM=False)
cut2_sp = " ".join(cut2)

df1 = pd.DataFrame(tigerair_keywords)
df2 = pd.DataFrame(evaair_keywords)
df1.to_csv('datafile/tigerair_keywords.csv')
df2.to_csv('datafile/evaair_keywords.csv')

#cut to cloud
dec = Openfile_sp(stopwords_file)
stopwords = set(STOPWORDS)
for i in range(len(dec)):
    stopwords.add(dec[i])

tigerair_cloud = WordCloud(
    font_path="msj.ttf", #設置字體
    background_color="white", #背景顏色
    stopwords=stopwords,
    max_words=150)
evaair_cloud = WordCloud(
    font_path="msj.ttf", #設置字體
    background_color="white", #背景顏色
    stopwords=stopwords,
    max_words=150)

tigerair_cloud.generate(cut1_sp)
evaair_cloud.generate(cut2_sp)

plt.imshow(tigerair_cloud)
plt.axis("off")
plt.figure(figsize=(4,3), dpi=500)
plt.savefig('image/tiger_cloud.png')
plt.show()

plt.imshow(evaair_cloud)
plt.axis("off")
plt.figure(figsize=(4,3), dpi=500)
plt.savefig('image/eva_cloud.png')
plt.show()

