#!/usr/bin/env python
# coding: utf-8

# # Download EPSA 2019 authors

# In[1]:


from selenium import webdriver
import os
import re
import time


# ## Create download folder

# In[2]:


os.makedirs("html/authors", exist_ok = True)


# ### Check whether downloading is already done

# The notebook will go through (and download) all author listings if any of them is missing.

# In[3]:


download_required = True

files = [f for f in os.listdir("html/authors") if re.match(r'.*\.html', f)]
if len(files) > 0:
    # look at numbers in downloaded authors
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

    # exit if we are already done
    if 1 in set(first_id) and max(set(last_id)) == max(max_id):
        print('All authors already downloaded.')
        download_required = False


# ## Initiate Web driver

# In[4]:


if download_required:
    driver = webdriver.Chrome('/Applications/chromedriver')
    driver.get("https://app.oxfordabstracts.com/events/772/program-app/authors")


# ## Loop through author listings

# In[ ]:


i = 0

# loop until results counter says otherwise
while download_required:
    
    i += 1
    
    # give it some time to load
    time.sleep(7.5)
    
    # extract results string
    r = driver.find_element_by_xpath(".//span[@class='results__count']").text
    print(str(i).rjust(3) + "Dowloading authors " + " " + r)

    # save a copy
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


# Have a nice day.
