##############################################################################
# Title:        reproduce_8PTRZ.R – the reproduction of Task 3
# Purpose:      Reproduce the value that Multi100 recorded for analyst 8PTRZ,
#               chi-square = 14.265 on 558 replies, from the public file of the
#               original authors: a 2 x 2 table of Hispanic against all other
#               names by whether the reply greeted the sender by name, passed
#               to chisq.test(). Then the same test without the continuity
#               correction (14.95), and, as an optional extension, the logit of
#               analyst UYV3F (z = -3.771 on 362 replies). The analysts' own
#               scripts are on OSF (8PTRZ: osf.io/j8wvh; all five under
#               osf.io/38rsh) and are not copied here.
# Reads:        data/audit_original.csv (the public file of the original
#               authors, Harvard Dataverse doi:10.7910/DVN/1HOVTU, CC0)
# Writes:       – (prints the tests)
# Author:       Chris Moreh
# Last updated: 2026-10-26
##############################################################################

original <- readr::read_csv("data/audit_original.csv", show_col_types = FALSE)

# ProperName is 1 when the reply greeted the sender by name, 0 when it did
# not, and missing for the emails without a reply, the bounced emails and the
# five replies that carry no greeting code. TreatmentGroup reads "Hispanic
# male", "white female" and so on.
coded_replies <- original |>
  datawizard::data_filter(!is.na(ProperName)) |>
  datawizard::data_modify(hispanic_name = grepl("^Hispanic", TreatmentGroup))

nrow(coded_replies)   # 558

tab_8ptrz <- xtabs(~ hispanic_name + ProperName, data = coded_replies)
tab_8ptrz

# chisq.test() applies the continuity correction of Yates to a 2 x 2 table
# unless told otherwise, and the value that Multi100 recorded is the
# corrected one: X-squared = 14.265.
chisq.test(tab_8ptrz)

# Without the correction: X-squared = 14.952.
chisq.test(tab_8ptrz, correct = FALSE)

# ---- Optional: analyst UYV3F --------------------------------------------------
# A logit of the greeting on a Hispanic name, among the replies to Hispanic and
# white names only, with no covariates: z = -3.771 on 362 replies.
replies_uyv3f <- coded_replies |>
  datawizard::data_filter(!grepl("^black", TreatmentGroup))

m_uyv3f <- glm(ProperName ~ hispanic_name, family = binomial(), data = replies_uyv3f)
nobs(m_uyv3f)   # 362
coef(summary(m_uyv3f))
