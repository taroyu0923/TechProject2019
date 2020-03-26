from facebook_scraper import get_posts
from pprint import pprint
import pandas as pd
import numpy as np
import csv
from collections import Counter

def nestedlist(list, output):
    with open(output, 'w') as f:
        w = csv.writer(f)
        fieldnames = list[0].keys()
        w.writerow(fieldnames)
        for row in list:
            w.writerow(row.values())

path = 'D:/WORK5/TechProject/datafile/test.csv'
result_post = []
for post in get_posts('evaairwayscorp.tw', pages=500, sleep=0):

    result_post.append(post)
    '''
    print(post['post_id'])
    print(post['likes'])
    print(post['comments'])
    print(post['shares'])
    '''
output = pd.DataFrame(result_post)
output1 = output[['post_id', 'time', 'likes', 'comments', 'shares', 'image', 'post_url', 'link']]
output2 = output[['text']]
print(output2)
output.to_csv('datafile/EvaAir.csv')
output1.to_csv('datafile/EvaAir_sta.csv')
output2.to_csv('datafile/EvaAir_text.csv')