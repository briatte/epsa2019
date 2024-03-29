library(tidyverse)

d <- read_tsv("data/sessions.tsv", col_types = cols(.default = "c")) %>%
  full_join(read_tsv("data/authors.tsv", col_types = cols(.default = "c")),
            by = "abstract_id")

# sanity checks: identifiers are never missing
stopifnot(!is.na(d$session_id))
stopifnot(!is.na(d$abstract_id))

# [NOTE] chairs and discussants are sometimes missing
n_distinct(d$session_id[ is.na(d$chair) ])
n_distinct(d$session_id[ is.na(d$discussant) ])

# assemble participants ---------------------------------------------------

# participants
p <- bind_rows(
  # chairs
  select(d, session_id, starts_with("chair")) %>%
    distinct() %>%
    rename(full_name = chair, affiliation = chair_affiliation) %>%
    filter(!is.na(full_name)) %>%
    add_column(role = "c")
  ,
  # discussants
  select(d, session_id, starts_with("discussant")) %>%
    distinct() %>%
    rename(full_name = discussant, affiliation = discussant_affiliation) %>%
    filter(!is.na(full_name)) %>%
    add_column(role = "d")
  ,
  # authors
  select(d, session_id, full_name = author, affiliation, presenter, abstract_id) %>%
    # next lines not required: authors do not repeat and are never missing
    # distinct() %>%
    # filter(is.na(full_name))
    add_column(role = "p")
)

# reduce sessions ---------------------------------------------------------

# sessions, keeping only actual session columns
d <- select(d, starts_with("session")) %>%
  distinct()

# assemble full programme -------------------------------------------------

# add abstracts
a <- read_tsv("data/abstracts.tsv", col_types = cols(.default = "c"))

# `full_join` because `d` and `p` have exactly the same list of `session_id`
d <- full_join(d, p, by = "session_id") %>%
  # `left_join` because `d` has rows where `abstract_id` is `NA` (chairs, disc.)
  left_join(select(a, -abstract_presenters), by = "abstract_id")

# sanity check: everything belongs in a session
stopifnot(!is.na(d$session_id))

# export ------------------------------------------------------------------

readr::write_tsv(d, "data/program.tsv")

# kthxbye
