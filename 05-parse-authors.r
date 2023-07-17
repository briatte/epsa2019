library(tidyverse)
library(rvest)

fs::dir_create("data")

# parse authors -----------------------------------------------------------

f <- fs::dir_ls("html/authors")
cat("Parsing", length(f), "author (list) pages... ")

d <- map(f, read_html) %>%
  map_dfr(
    ~ tibble::tibble(
      # author page (useless, does not point to a unique id)
      # file = i,
      # name
      author = html_nodes(.x, "li.results__result h2") %>%
        html_text(),
      # affiliation
      affiliation = html_nodes(.x, "li.results__result section:first-of-type span:first-of-type") %>%
        html_text(),
      # affiliation (alternative query)
      # affiliation = html_nodes(.x, xpath = "//section[@class='results__details-section'][1]/span") %>%
      #   html_text(),
      # number of affiliations
      n_affiliations = html_nodes(.x, "li.results__result") %>%
        map(html_nodes, xpath = "./section/section/i[contains(text(), 'domain')]") %>%
        map_int(length),
      # abstract ids (might be more than 1)
      abstract_id = html_nodes(.x, "li.results__result") %>%
        map(html_nodes, xpath = ".//a[contains(@href, 'submission')]") %>%
        map(html_attr, "href"),
      # abstract ref (might be more than 1)
      abstract_ref = html_nodes(.x, "li.results__result") %>%
        map(html_nodes, xpath = "./section/section/i[contains(text(), 'description')]") %>%
        map(html_nodes, xpath = "./following::span[1]") %>%
        map(html_text),
      # abstract titles (might be more than 1)
      abstract_title = html_nodes(.x, "li.results__result") %>%
        map(html_nodes, xpath = ".//a[contains(@href, 'submission')]") %>%
        map(html_text)
    )
  )

# sanity check: always only 1 affiliation
stopifnot(map_int(d$n_affiliations, length) == 1)

# [NOTE] checks below apply to columns that drop later: (1) abstract attributes
#        are collected again by the abstracts parser, and stored from there, as
#        are (2) author attributes, which are handled by the authors parser

# sanity check: abstract variables have equal lengths
stopifnot(map_int(d$abstract_id, length) == map_int(d$abstract_ref, length))
stopifnot(map_int(d$abstract_id, length) == map_int(d$abstract_title, length))

# drop unused columns
d <- select(d, author, affiliation, abstract_id) %>%
  # expand abstract ids
  tidyr::unnest(abstract_id) %>%
  # minimal data cleaning
  mutate(
    abstract_id = str_extract(abstract_id, "\\d{5,6}$"),
    # extra whitespace found, but no prefixes (e.g. "Dr.")
    author = str_squish(author),
    affiliation = str_squish(str_remove(affiliation, "\\.$"))
  )

# sanity check: no duplicates
stopifnot(!duplicated(d))

# sanity check: no missing abstract ids
stopifnot(str_detect(d$abstract_id, "\\d{5,6}"))

# identify abstract presenters --------------------------------------------

d <- readr::read_tsv("data/abstracts.tsv", col_types = cols(.default = "c")) %>%
  select(abstract_id, abstract_presenters) %>%
  right_join(d, by = "abstract_id") %>%
  mutate(presenter = str_detect(abstract_presenters, author),
         presenter = if_else(presenter, "y", "n")) %>%
  select(-abstract_presenters)

# export ------------------------------------------------------------------

f <- "data/authors.tsv"

readr::write_tsv(d, f)

cat(nrow(d), "rows written to", f, "\n")

# kthxbye
