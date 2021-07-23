library(tidyverse)
library(rvest)

# [NOTE] checks required to ensure all abstracts (`abstract_id`) are assigned
#        to a session (`session_id`); if not, some abstracts end up being
#        'orphaned' with `NA` as their `session_id`

# check sessions ----------------------------------------------------------

# get all sessions listed in authors listings
f <- fs::dir_ls("html/authors/") %>%
  map(read_html) %>%
  map(html_nodes, xpath = "//a[contains(@href, 'session')]") %>%
  map(html_attr, "href") %>%
  unlist() %>%
  unique() %>%
  str_replace(".*?/(\\d{4})$", "html/sessions/session_\\1.html")

# sanity check: found a result in every URL
stopifnot(!is.na(f))

# sanity check: all have downloaded
stopifnot(fs::file_exists(f))

# check abstracts ---------------------------------------------------------

# get all abstracts listed in authors listings

f <- fs::dir_ls("html/authors/") %>%
  map(read_html) %>%
  map(html_nodes, xpath = "//a[contains(@href, 'submission')]") %>%
  map(html_attr, "href") %>%
  unlist() %>%
  unique() %>%
  str_replace(".*?/(\\d{5,6})$", "html/abstracts/abstract_\\1.html")

# sanity check: found a result in every URL
stopifnot(!is.na(f))

# sanity check: all have downloaded
stopifnot(fs::file_exists(f))

cat("All downloads completed.\n")

# kthxbye
