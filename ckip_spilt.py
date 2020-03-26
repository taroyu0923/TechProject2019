import sys, re
from ckiptagger import data_utils, construct_dictionary, WS, POS, NER
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.feature_extraction.text import TfidfTransformer
from scipy.sparse import dok_matrix
import pandas as pd
import numpy as np

def print_word_pos_sentence(word_sentence, pos_sentence):
    assert len(word_sentence) == len(pos_sentence)
    for word, pos in zip(word_sentence, pos_sentence):
        print(f"{word}", end="\u3000")
    return

def read_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        result = []
        text = f.read()
        f.close()
        result.append(text)
        return result

sw = ['的', '了', '和', '是', '就', '都', '而', '及', '與', '著', '或', 
'之', '後', '才', '元', '在', '不', '一個', '沒有', '我們', '你們', '妳們', 
'他們', '她們', '因此', '因為', '同年', '同時', '唯一', '去年', '原來',
 '加上', '剩下', '其中', '其他', '不到', '不如', '不止', '不錯', '之外',
  '不足', '千萬', '如果', '所有', '為了', '若是', '所以', '是否', '於是',
   '的確', '沒錯', '發現', '公布', '等於', '說法', '表示', '包括', 'text'
   , 'bit', 'ly', 'u7', 'cl', '3cmic7', 'd2xkns', '299', 'zania', '½ä¾',
    'kongtex', 'more']


path = 'datafile/EvaAir_text.txt'
corpus = read_file(path)
df = pd.read_csv('datafile/EvaAir_text.csv')
df1 = df[['text']]
text_data0 = np.array(df1)
text_data = text_data0.tolist()

collect_corpus = []


for i in text_data:

    clean_obj = re.sub('[【】《》「」*]', '', str(i))
    #clean_obj1 = re.sub("\n", "", clean_obj)
    if len(clean_obj) > 0:
        collect_corpus.append(clean_obj)

ws = WS("D:/data")
#pos = POS("D:/data")
#ner = NER("D:/data")

word_to_weight = {
    "長榮": 5,
    "長榮航空": 5,
    "BR": 2
}

dictionary = construct_dictionary(word_to_weight)
sentence_list = read_file(path)


word_sentence_list = ws(
    sentence_list,
    sentence_segmentation=True, # To consider delimiters
    segment_delimiter_set = {",", "。", ":", "?", "!", ";"}) # This is the defualt set of delimiters
    # recommend_dictionary = dictionary1, # words in this dictionary are encouraged
    # coerce_dictionary = dictionary2, # words in this dictionary are forced


cut_corpus = []
for i in word_sentence_list:
    cut_corpus.append(' '.join(i))

vertor = CountVectorizer(stop_words=sw)
td_martix = vertor.fit_transform(cut_corpus)

print(td_martix.shape)
print(vertor.vocabulary_.keys())

TFIDF = TfidfTransformer()
TFIDF_matrix = TFIDF.fit_transform(td_martix)
TFIDF.idf_

df_res = pd.DataFrame(TFIDF_matrix.T.toarray(), index=vertor.vocabulary_.keys())
print(df_res)
print(TFIDF_matrix)

matrix = TFIDF_matrix.toarray()
new_matrix = np.squeeze(matrix)

df_res = pd.DataFrame(TFIDF_matrix.T.toarray(), index=vertor.vocabulary_.keys())
df_res.columns = ['tag']

df_key = list(vertor.vocabulary_.keys())
new_key = {
    "tag":df_key,
    "rate":new_matrix
}
df_res1 = pd.DataFrame(new_key)

df_final = df_res1.sort_values(by=['rate'], ascending=False)
print(df_final)
#pos_sentence_list = pos(word_sentence_list)
#entity_sentence_list = ner(word_sentence_list, pos_sentence_list)

del ws
#del pos
#del ner
