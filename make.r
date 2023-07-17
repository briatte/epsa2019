
# downloads ---------------------------------------------------------------

# [NOTE] download script runs in Python
# 01-download-pages.py

source("02-check-downloads.r")

# parsing -----------------------------------------------------------------

source("03-parse-sessions.r")
source("04-parse-abstracts.r")
source("05-parse-authors.r")

# wrangling ---------------------------------------------------------------

# reformat data into single master dataset (`program.tsv`)
source("06-assemble-program.r")

# fix multiple affiliations per author + minimal data cleaning
source("07-fix-affiliations.r")

# create unique participant ids
source("08-create-pids.r")

# conclude ----------------------------------------------------------------

d <- readr::read_tsv("data/program.tsv", col_types = cols(.default = "c"))

cat(
  "\n-", n_distinct(d$session_id), "panels",
  "\n-", n_distinct(d$abstract_id), "abstracts",
  "\n-", n_distinct(d$pid), "participants (ids)",
  "\n-", n_distinct(d$full_name), "participants (full names)",
  # TODO: more data cleaning on affiliations
  "\n-", n_distinct(d$affiliation), "affiliations\n"
)

# work-in-progress
