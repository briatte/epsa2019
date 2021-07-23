#!/usr/bin/env python
# coding: utf-8

# # Download EPSA 2019 authors, sessions and abstracts

# In[1]:


from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from selenium.common.exceptions import TimeoutException
import os
import re


# ## Create download folders

# In[2]:


for i in ["authors", "abstracts", "sessions"]:
    os.makedirs("html/" + i, exist_ok = True)


# ## Initiate Web driver

# In[3]:


driver = webdriver.Chrome('/Applications/chromedriver')


# ## Download authors

# ### Check whether downloading authors is already done

# The notebook will go through (and download) all author listings if any of them is missing.

# In[4]:


download_authors = True

files = [f for f in os.listdir("html/authors") if re.match(r'.*\.html', f)]
if len(files) > 0:
    
    # extract numbers from downloaded authors lists filenames
    first_id = []
    last_id = []
    max_id = []
    
    for i in files:
        n = re.findall(r'\d+', i)
        # store 'x to y out of z' values
        first_id.append(int(n[0]))
        last_id.append(int(n[1]))
        max_id.append(int(n[2]))

    max_id = set(max_id)
    assert len(max_id) == 1, "Malformed author count."

    # determine whether we are already done
    if 1 in set(first_id) and max(set(last_id)) == max(max_id):
        print('All authors already downloaded.')
        download_authors = False


# ### If needed, loop through author listings and download

# In[5]:


if download_authors:
    
    driver.get("https://app.oxfordabstracts.com/events/772/program-app/authors")

    i = 0

    # loop until results counter says otherwise
    while download_authors:

        i += 1

        # wait for main content to finish loading
        try:
            WebDriverWait(driver, 7.5).until(EC.presence_of_element_located((By.TAG_NAME, 'h2')))
        except TimeoutException:
            print("Download of author pages failed at iteration " + str(i) +"\n")
            raise SystemExit("Could not download all author pages")

        # extract results string
        r = driver.find_element_by_xpath(".//span[@class='results__count']").text
        print(str(i).rjust(3) + " Dowloaded authors " + r)

        # save
        f = "html/authors/authors_" + r.replace(" ", "_") + ".html"
        with open(f, "w") as file:
            file.write(driver.page_source)

        # check if we reached the end
        n = re.findall(r'\d+', r)
        if int(n[1]) == int(n[2]):
            break

        # if not, find first 'Next' button, click it, and loop
        b = driver.find_element_by_xpath('.//button[@class="program__button"][contains(., "Next")]')
        b.click()

    print("done")


# ## Find links to sessions and abstracts

# In[6]:


session_urls = []
abstract_urls = []

files = [f for f in os.listdir("html/authors") if re.match(r'.*\.html', f)]
print("Parsing " + str(len(files)) + " author pages...")

for i in sorted(files):
    # load
    driver.get("file://" + os.path.abspath("html/authors/" + i))
    
    # find links to sessions
    r = driver.find_elements_by_xpath(".//a[contains(@href, 'session')]")
    for j in r:
        session_urls.append(j.get_attribute("href"))
    
    # find links to abstracts
    r = driver.find_elements_by_xpath(".//a[contains(@href, 'submission')]")
    for j in r:
        abstract_urls.append(j.get_attribute("href"))


# ## Download sessions (panels)

# Session IDs are always 4 digits.

# In[7]:


session_urls = set(session_urls)
print("Downloading " + str(len(session_urls)) + " sessions...")

for i in sorted(session_urls):
    u = i.replace("file://", "https://app.oxfordabstracts.com")
    f = "html/sessions/session_" + re.search(r'\d{4}', i).group(0) + ".html"
    if not(os.path.exists(f)):
        
        print("Downloading session " + u)
        
        # load
        driver.get(u)
        
        # wait for main content to finish loading
        try:
            WebDriverWait(driver, 7.5).until(EC.presence_of_element_located((By.TAG_NAME, 'h1')))
        except TimeoutException:
            print("Download of session failed at URL " + u +"\n")
            raise SystemExit("Could not download all session pages")

        # save
        with open(f, "w") as file:
            file.write(driver.page_source)

print("done")


# ## Download abstracts

# Abstracts IDs are variable-length: 5-6 digits.

# In[8]:


abstract_urls = set(abstract_urls)

print("Downloading " + str(len(abstract_urls)) + " abstracts...")

for i in abstract_urls:
    u = i.replace("file://", "https://app.oxfordabstracts.com")
    f = "html/abstracts/abstract_" + re.search(r'\d{5,6}', i).group(0) + ".html"
    if not(os.path.exists(f)):
        
        print("Downloading abstract " + u)
        
        # load
        driver.get(u)
        
        # wait for main content to finish loading
        try:
            WebDriverWait(driver, 7.5).until(EC.presence_of_element_located((By.TAG_NAME, 'h1')))
        except TimeoutException:
            print("Download of abstract failed at URL " + u +"\n")
            raise SystemExit("Could not download all abstract pages")

        # save
        with open(f, "w") as file:
            file.write(driver.page_source)

print("done")


# Have a nice day.
