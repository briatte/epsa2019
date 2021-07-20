library(tidyverse)
library(rvest)

fs::dir_create("data")

# parse abstracts ---------------------------------------------------------

f <- fs::dir_ls("html/abstracts")
cat("Parsing", length(f), "abstract pages...\n")

d <- map(f, read_html) %>%
  map_dfr(
    ~ tibble::tibble(
      # abstract ref
      abstract_ref = html_nodes(.x, "h2.mdc-typography--overline") %>%
        html_text(),
      # abstract title
      abstract_title = html_nodes(.x, "h1") %>%
        html_text(),
      # abstract text
      abstract_text = html_nodes(.x, "p.calibri:nth-of-type(1)") %>%
        html_text(),
      # abstract authors
      abstract_authors = html_nodes(.x, xpath = "//h1/following-sibling::section") %>%
        html_text(),
      # abstract presenters
      abstract_presenters = html_nodes(.x, xpath = "//h1/following-sibling::section") %>%
        map(html_nodes, xpath = "./div/span[contains(@style, 'underline')]") %>%
        map(html_text) %>%
        map_chr(str_c, collapse = ", ")
    ),
    # abstract id
    .id = "abstract_id"
  )

# drop unused columns
d <- select(d, -abstract_authors) %>%
  # minimal data cleaning
  mutate(
    abstract_id = str_extract(abstract_id, "\\d{5,6}"),
    abstract_text = str_squish(abstract_text)
  )

# sanity check: no duplicates
stopifnot(!duplicated(d))

# sanity check: no missing abstract ids
stopifnot(str_detect(d$abstract_id, "\\d{5,6}"))

# export
readr::write_tsv(d, "data/abstracts.tsv")

# kthxbye
