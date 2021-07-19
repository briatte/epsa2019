#!/usr/bin/env python
# coding: utf-8

# # Download EPSA 2019 Web pages

# In[1]:


from bs4 import BeautifulSoup
from selenium import webdriver
import os
import re
import time


# # Get panel URLs

# The `html/presentation-types.html` page was manually downloaded from the [conference website](https://app.oxfordabstracts.com/events/772/), using an Oxford Abstracts user account.

# In[2]:


panel_page = BeautifulSoup(open("html/presentation-types.html"), "lxml")


# In[3]:


panel_urls = []
for i in panel_page.find_all("a", href = re.compile("session")):
    panel_urls.append(i.get("href"))


# In[4]:


panel_urls[0:4]


# In[5]:


len(panel_urls)


# In[6]:


# unique values
panel_urls = list(set(panel_urls))


# In[7]:


len(panel_urls)


# In[8]:


panel_urls[0:4]


# # Download panels

# ## Warning: empty pages

# Some pages will fail to load properly despite the time allocated for that, and will contain nothing except a "Loading event data" message.
# 
# Delete them and run the notebook again.

# In[9]:


driver = webdriver.Chrome('/Applications/chromedriver')


# In[10]:


left = panel_urls[::-1]

for i in panel_urls:
    u = "https://app.oxfordabstracts.com" + i
    f = "html/sessions/session" + i[-4:] + ".html"
    print("(" + str(left.index(i) + 1) + " left) URL: " + u)
    if os.path.exists(f):
        next
    else:
        driver.get(u)
        # give it some time to load
        time.sleep(7.5)
        with open(f, "w") as file:
            file.write(driver.page_source)

print("done")


# # Get abstracts URLs

# This will fail if the page loaded improperly. In that case, go back to previous step and download the page again.

# In[11]:


files = [f for f in os.listdir("html/sessions") if re.match(r'.*\.html', f)]
abstract_urls = []
for i in files:
    # print(i)
    x = BeautifulSoup(open("html/sessions/" + i), "lxml")
    # determine panel type
    y = x.find("span", string = re.compile("Presentation type$")).parent.text
    # find links to abstracts
    z = []
    for j in x.find_all("a", href = re.compile("submission")):
        z.append(j.get("href"))
    print(i + ": " + y.replace('Presentation type', '') + " with " + str(len(z)) + " abstracts")
    abstract_urls.append(z)


# In[12]:


# should equal number of panels
len(abstract_urls)


# In[13]:


abstract_urls = [item for sublist in abstract_urls for item in sublist]
abstract_urls[0:4]


# In[14]:


# actual number of abstracts
len(abstract_urls)


# In[15]:


# unique values
abstract_urls = list(set(abstract_urls))
len(abstract_urls)


# In[16]:


abstract_urls[0:4]


# # Download abstracts

# In[17]:


left = abstract_urls[::-1]

for i in abstract_urls:
    u = "https://app.oxfordabstracts.com" + i
    f = "html/abstracts/abstract_" + i[-4:] + ".html"
    print("(" + str(left.index(i) + 1) + " left) URL: " + u)
    if os.path.exists(f):
        next
    else:
        driver.get(u)
        # give it ample time to load
        time.sleep(7.5)
        with open(f, "w") as file:
            file.write(driver.page_source)

print("done")

