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
for post in get_posts('chinaairlines.travelchannel', pages=50, sleep=0):

    result_post.append(post)
    '''
    print(post['post_id'])
    print(post['likes'])
    print(post['comments'])
    print(post['shares'])
    '''
output = pd.DataFrame(result_post)
output1 = output[['post_id', 'time', 'likes', 'comments', 'shares']]
print(output1)
output.to_csv('datafile/ChinaAirline.csv')
output1.to_csv('datafile/ChinaAirline_sta.csv')