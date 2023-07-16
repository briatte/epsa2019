library(tidyverse)
library(rvest)

fs::dir_create("data")

# parse sessions ----------------------------------------------------------

d <- tibble::tibble()

f <- fs::dir_ls("html/sessions")
cat("Parsing", length(f), "session pages... ")

for (i in f) {

  h <- read_html(i)

  # `for` loop and `try` required to skip plenary sessions with no papers
  try(
    d <- tibble::tibble(
      # numeric id of the session URL
      session_id = i,
      # denoted as either "PE1" or "PE01" on the page
      # ... we store "PE1" (simpler to extract)
      session_ref = html_node(h, "h1") %>%
        html_text(),
      session_track = html_nodes(h, xpath = "//span[text()='Track']/..") %>%
        html_text(),
      session_type = html_nodes(h, xpath = "//span[text()='Presentation type']") %>%
        list(),
      session_title = html_nodes(h, "h1")[2] %>%
        html_text(),
      chair = html_node(h, xpath = "//h3[text()='Chair']/following::div[1]/div[1]") %>%
        html_text(),
      chair_affiliation = html_node(h, xpath = "//h3[text()='Chair']/following::div[1]/div[2]") %>%
        html_text(),
      discussant = html_node(h, xpath = "//h3[text()='Discussant']/following::div[1]/div[1]") %>%
        html_text(),
      discussant_affiliation = html_node(h, xpath = "//h3[text()='Discussant']/following::div[1]/div[2]") %>%
        html_text(),
      # numeric id in the abstract URL
      abstract_id = html_nodes(h, xpath = "//a[contains(@href, 'submission')]") %>%
        html_attr("href"),
      # internal numeric id
      abstract_ref = html_nodes(h, xpath = "//a[contains(@href, 'submission')]/preceding::div[2]") %>%
        html_text(),
      abstract_title = html_nodes(h, xpath = "//a[contains(@href, 'submission')]") %>%
        html_text(),
      abstract_authors = html_nodes(h, xpath = "//a[contains(@href, 'submission')]/following::div[1]") %>%
        html_text(),
      abstract_presenters = html_nodes(h, xpath = "//a[contains(@href, 'submission')]/following::div[1]") %>%
        map(html_nodes, xpath = "./span[contains(@style, 'underline')]") %>%
        map(html_text) %>%
        map_chr(str_c, collapse = ", ")
    ) %>%
      bind_rows(d),
    silent = TRUE
  )

}

# drop unused columns
d <- select(d, matches("session|chair|discussant"), abstract_id) %>%
  # minimal data cleaning
  mutate(
    session_id = str_extract(session_id, "\\d{4}"),
    session_track = str_remove(session_track, "^Track"),
    # sometimes missing...
    session_type = map_chr(d$session_type,
                           function(x) {
                             x <- html_text(html_node(x, xpath = "./.."))
                             if (!length(x)) NA else x
                           }) %>%
      str_remove("^Presentation type"),
    abstract_id = str_extract(abstract_id, "\\d{5,6}")
  )

# sanity check: no duplicates
stopifnot(!duplicated(d))

# sanity check: no missing session ids
stopifnot(str_detect(d$session_id, "\\d{4}"))

# sanity check: no missing abstract ids
stopifnot(str_detect(d$abstract_id, "\\d{5,6}"))

# export ------------------------------------------------------------------

f <- "data/sessions.tsv"

readr::write_tsv(d, f)

cat(nrow(d), "rows written to", f, "\n")

# kthxbye
