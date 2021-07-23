library(tidyverse)

# load master data
d <- read_tsv("data/program.tsv", col_types = "cccccccccccc")

# sanity check: no missing participant name
stopifnot(!is.na(d$full_name))

# note on abstract presenters ---------------------------------------------

# abstract presenters almost always exist in the list of abstract authors
filter(d, !is.na(abstract_id)) %>%
  group_by(abstract_id) %>%
  summarise(
    full_name = list(full_name[ role %in% "p" ]),
    abstract_presenters = str_split(abstract_presenters, ",\\s")
  ) %>%
  rowwise() %>%
  mutate(found = all(abstract_presenters %in% full_name, na.rm = TRUE)) %>%
  filter(!found) %>%
  unnest(c(full_name, abstract_presenters))

# n = 1 special case in a non-paper panel
# ... so apart in that special case, pids can be used on presenters too

# create unique participant identifiers -----------------------------------

# [NOTE] should be reproducible using R >= 3.5.0, serialization version 3
#        see ?rlang::hash -- 128-bit hashes

p <- distinct(d, full_name, affiliation) %>%
  add_column(conference = "epsa2019", .before = 1) %>%
  mutate(
    # [NOTE] `affiliation` can be missing, and will turn `text` into just `NA`
    #        if `str_replace_na` is not used, resulting into... duplicate hashes
    text = str_c(conference, full_name, str_replace_na(affiliation)),
    # create 32-length UIDs
    hash = map_chr(text, rlang::hash)
  )

# sanity checks: no duplicates
stopifnot(!duplicated(p$text))
stopifnot(!duplicated(p$hash))

# add hashes to master data
d <- select(p, full_name, pid = hash) %>%
  left_join(d, ., by = "full_name") %>%
  relocate(pid, .before = full_name)

# sanity check: no missing pid
stopifnot(!is.na(d$pid))

# export ------------------------------------------------------------------

cat(
  "Added", n_distinct(d$pid), "unique participant IDs to",
  n_distinct(d$full_name), "unique names\n"
)

# overwites existing version
readr::write_tsv(d, "data/program.tsv")

# kthxbye
