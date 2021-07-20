
# downloads (handled in Python) -------------------------------------------

# run 01-download.py
# run 02-download-authors.py

# parsing -----------------------------------------------------------------

source("03-parse-sessions.r")
source("04-parse-abstracts.r")
source("05-parse-authors.r")

# merge all datasets ------------------------------------------------------

d <- read_tsv("data/sessions.tsv", col_types = "ccccccccc") %>%
  left_join(
    read_tsv("data/abstracts.tsv", col_types = "ccccc"),
    by = "abstract_id"
  ) %>%
  left_join(
    read_tsv("data/authors.tsv", col_types = "ccc"),
    by = "abstract_id"
  )

cat(
  "Collected",
  n_distinct(d$session_id), "panels,",
  n_distinct(d$abstract_id), "abstracts,",
  # [WARNING] might contain homonyms
  n_distinct(d$author), "authors."
)

# work-in-progress
