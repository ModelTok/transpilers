'''
Copyright [2020] [Arun Kumar G]
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
'''

'''
Scraping the first 2 pages of Hacker news website which gives lot of Tech news(as a articles)
which has upvotes more than 100.User can just click on story link to see the article.
'''

'''
Program uses requests module to get web data from URL and BeautifulSoup module to parse the web data
as HTML using html parser.
Install requests and BeautifulSoup module before executing!
'''

import requests
from bs4 import BeautifulSoup
import pprint


response1 = requests.get("https://news.ycombinator.com/news")
response2 = requests.get("https://news.ycombinator.com/news?p=2")

response1_html_parser = BeautifulSoup(response1.text,'html.parser')
response2_html_parser = BeautifulSoup(response2.text,'html.parser')

linksInPage1 = response1_html_parser.select('.storylink')
linksInPage2 = response2_html_parser.select('.storylink')

votesInPage1 = response1_html_parser.select('.subtext')
votesInPage2 = response2_html_parser.select('.subtext')


mega_link = linksInPage1 + linksInPage2
mega_votes = votesInPage1 + votesInPage2

def sorted_stories_list(hackerNewsList):
    """Sorting the list in decreasing order
       with respect to votes"""
    return sorted(hackerNewsList,key=lambda x:x['votes'],reverse=True)

def create_custom_hackernews(mega_link,mega_votes):
    hackerNews =[]
    for index,item in enumerate(mega_link):
        title = mega_link[index].getText()
        href = mega_link[index].get('href',None)
        vote = mega_votes[index].select('.score')
        if len(vote):
            points = int(vote[0].getText().replace(' points', ''))
            if points > 100:
                hackerNews.append({'title': title, 'link': href,'votes': points})

    return sorted_stories_list(hackerNews)

if __name__ == '__main__':
    pprint.pprint(create_custom_hackernews(mega_link,mega_votes))
    
