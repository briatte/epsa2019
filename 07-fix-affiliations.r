library(tidyverse)

# load master data
d <- read_tsv("data/program.tsv", col_types = cols(.default = "c"))

# find names with multiple affiliations -----------------------------------

# [NOTE] affiliation is sometimes missing
filter(d, is.na(affiliation) | affiliation %in% "") %>%
  select(session_id, full_name, affiliation, role)

# # [NOTE] chairs and discussants are sometimes missing
# group_by(d, session_id) %>%
#   count(role) %>%
#   pivot_wider(names_from = role, values_from = n) %>%
#   filter(is.na(c) | is.na(d))

# get names of authors/presenters for which there are more than 1 affiliation
p <- select(d, full_name, affiliation) %>%
  distinct() %>%
  arrange(full_name) %>%
  group_by(full_name) %>%
  mutate(n_affiliations = n_distinct(affiliation)) %>%
  filter(n_affiliations > 1)

# n = 103 cases of multiple affiliations
n_distinct(p$full_name)

# export
readr::write_tsv(p, "data/affiliation-problems.tsv")

# [NOTE] that file was used as the basis for the `fixes` file used below, which
#        was manually produced (see README for details)

# fix multiple affiliations -----------------------------------------------

f <- readr::read_tsv("data/affiliation-fixes.tsv",
                     col_types = cols(.default = "c"))

# sanity check: no duplicates in fixes
stopifnot(!duplicated(f$full_name))

# sanity check: all authors needing a fix have one
stopifnot(p$full_name %in% f$full_name)

# reverse check (won't work when fixes have been applied)
# stopifnot(f$full_name %in% p$full_name)

d <- left_join(d, f, by = "full_name") %>%
  mutate(
    # apply fixes
    affiliation.x = if_else(!is.na(affiliation.y), affiliation.y, affiliation.x)
  ) %>%
  rename(affiliation = affiliation.x) %>%
  select(-affiliation.y)

# sanity check: no problems left
p <- group_by(d, full_name) %>%
  summarise(n_affiliations = n_distinct(affiliation)) %>%
  filter(n_affiliations > 1)

stopifnot(!nrow(p))

# minimal data cleaning ---------------------------------------------------

d <- mutate(d, affiliation = str_replace_all(affiliation, "\\s,", ","))

# str_subset(d$affiliation, "\\s,")
# str_subset(d$affiliation, "\\w-\\s")
# str_subset(d$affiliation, "^[[:punct:]]|[[:punct:]]$")
# str_subset(d$affiliation, "[[:punct:]]{2,}")

# manual fixes (typos in names of chairs/discussants)
filter(d, is.na(affiliation) | affiliation %in% "") %>%
  select(session_id, full_name, affiliation, role)

d$full_name[ d$full_name == "Zeynep Somer-Tocu" ] <- "Zeynep Somer-Topcu"
d$affiliation[ d$full_name == "Zeynep Somer-Topcu" ] <- "University of Texas at Austin, USA"
d$full_name[ d$full_name == "Nick Vivian" ] <- "Nick Vivyan"
d$affiliation[ d$full_name == "Nick Vivyan" ] <- "Durham University, United Kingdom"

# export corrected program ------------------------------------------------

cat(
  "Fixed", nrow(f), "multiple affiliations,",
  n_distinct(d$affiliation), "unique affiliations left\n"
)

# overwites existing version
readr::write_tsv(d, "data/program.tsv")

# kthxbye
