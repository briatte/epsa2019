library(tidyverse)
library(rvest)

fs::dir_create("data")

# parse abstracts ---------------------------------------------------------

f <- fs::dir_ls("html/abstracts")
cat("Parsing", length(f), "abstract pages... ")

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
      abstract_text = "//*[self::p or self::div][@class='calibri']" %>%
        html_nodes(.x, xpath = .) %>%
        html_text() %>%
        unique() %>%
        str_flatten(collapse = " "),
      # abstract authors
      abstract_authors = "//h1/following-sibling::section" %>%
        html_nodes(.x, xpath = .) %>%
        html_text(),
      # abstract presenters
      abstract_presenters = "//h1/following-sibling::section" %>%
        html_nodes(.x, xpath = .) %>%
        map(html_nodes, xpath = "./div/span[contains(@style, 'underline')]") %>%
        map(html_text) %>%
        map_chr(str_c, collapse = ", ")
    ),
    # abstract id
    .id = "abstract_id"
  )

# sanity check: all abstracts parsed
stopifnot(!length(f[ !f %in% d$abstract_id ]))

# drop unused columns
d <- select(d, -abstract_authors) %>%
  # minimal data cleaning
  mutate(abstract_id = str_extract(abstract_id, "\\d{5,6}")) %>%
  mutate_if(is.character, str_squish) %>%
  mutate_if(is.character, str_replace_all, "\\\"+", "'")

# sanity check: no duplicates
stopifnot(!duplicated(d$abstract_id))

# sanity check: no missing abstract ids
stopifnot(str_detect(d$abstract_id, "\\d{5,6}"))

# export ------------------------------------------------------------------

f <- "data/abstracts.tsv"

readr::write_tsv(d, f)

cat(nrow(d), "rows written to", f, "\n")

# kthxbye
