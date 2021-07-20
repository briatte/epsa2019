#!/usr/bin/env python
# coding: utf-8

# # Download EPSA 2019 sessions and abstracts

# In[1]:


from bs4 import BeautifulSoup
from selenium import webdriver
import os
import re
import time


# ## Create download folders

# In[2]:


os.makedirs("html/sessions", exist_ok = True)
os.makedirs("html/abstracts", exist_ok = True)


# ## Find panel URLs

# The `html/presentation-types.html` page was [manually downloaded](https://app.oxfordabstracts.com/events/772/program-app/presentation-types) from the [conference website](https://app.oxfordabstracts.com/events/772/).

# In[3]:


panel_page = BeautifulSoup(open("html/presentation-types.html"), "lxml")


# In[4]:


panel_urls = []
for i in panel_page.find_all("a", href = re.compile("session")):
    panel_urls.append(i.get("href"))


# In[5]:


panel_urls[0:4]


# In[6]:


# check length of panel id is always 4
j = []
for i in panel_urls:
    j.append(len(re.search(r'\d+$', i).group(0)))

assert set(j) == {4}, "Unusual panel ids detected."


# In[7]:


len(panel_urls)


# In[8]:


# unique values
panel_urls = list(set(panel_urls))


# In[9]:


len(panel_urls)


# In[10]:


panel_urls[0:4]


# ## Download panels

# ### Warning: empty pages

# Some pages will fail to load properly despite the time allocated for that, and will contain nothing except a "Loading event data" message.
# 
# Delete them and run the notebook again.

# In[11]:


driver = webdriver.Chrome('/Applications/chromedriver')


# In[12]:


left = panel_urls[::-1]

for i in panel_urls:
    u = "https://app.oxfordabstracts.com" + i
    f = "html/sessions/session" + i[-4:] + ".html"
    print("(" + str(left.index(i) + 1).rjust(3) + " left) " + u) #  + " -> " + f
    if os.path.exists(f):
        next
    else:
        driver.get(u)
        # give it some time to load
        time.sleep(7.5)
        with open(f, "w") as file:
            file.write(driver.page_source)

print("done")


# ## Find abstracts URLs

# This will fail if the page loaded improperly. In that case, go back to previous step and download the page again.

# In[13]:


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
    print(i + ": " + y.replace('Presentation type', '') + " with " + str(len(z)) + " abstract(s)")
    abstract_urls.append(z)


# In[14]:


# should equal number of panels
assert len(panel_urls) == len(panel_urls), "Some session pages were not parsed."


# In[15]:


# unlist
abstract_urls = [item for sublist in abstract_urls for item in sublist]
abstract_urls[0:4]


# In[16]:


# actual number of abstracts
len(abstract_urls)


# In[17]:


# unique values
abstract_urls = list(set(abstract_urls))
len(abstract_urls)


# In[18]:


abstract_urls[0:4]


# ### Warning: abstract ids

# Abstract identifier length is actually variable.

# In[19]:


# check length of abstract id is always 5 or 6
j = []
for i in abstract_urls:
    j.append(len(re.search(r'\d+$', i).group(0)))

assert set(j) == {5, 6}, "Unusual abstract ids detected."


# ## Download abstracts

# In[20]:


left = abstract_urls[::-1]

for i in abstract_urls:
    u = "https://app.oxfordabstracts.com" + i
    f = "html/abstracts/abstract_" + re.search(r'\d+$', i).group(0) + ".html"
    print("(" + str(left.index(i) + 1).rjust(3) + " left) " + u) #  + " -> " + f
    if os.path.exists(f):
        next
    else:
        driver.get(u)
        # give it ample time to load
        time.sleep(7.5)
        with open(f, "w") as file:
            file.write(driver.page_source)

print("done")


# Have a nice day.
