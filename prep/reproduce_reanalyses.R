##############################################################################
# Title:        reproduce_reanalyses.R – the reproductions of Task 3
# Purpose:      Reproduce the five Multi100 reanalyses of the claim from the
#               public file of the original authors, each with the value that
#               Multi100 recorded: 8PTRZ (chi-square = 14.265 on 558 replies),
#               UYV3F (z = -3.771 on 362), EWFMI (z = 3.645 on 549) and 25N5D
#               (chi-square = 13.683 on 665 emails); P9W8Y has no recorded
#               statistic, and its likelihood-ratio test gives 15.951 on 2 df.
#               The same functions compute the refits of the course pipeline
#               (R/housing/03_reference_marks.R in the course repository). The
#               scripts of the analysts are on the OSF (all five under
#               osf.io/38rsh) and are not copied here.
# Reads:        data/audit_original.csv (the public file of the original
#               authors, Harvard Dataverse doi:10.7910/DVN/1HOVTU, CC0)
# Writes:       – (prints the tests)
# Author:       Chris Moreh
# Last updated: 2026-10-27
##############################################################################

original <- readr::read_csv("data/audit_original.csv", show_col_types = FALSE)

# Response_Dichotomous is 1 for a reply, 0 for none and missing for the 23
# bounced emails. ProperName is 1 when the reply greeted the sender by name, 0
# when it did not, and missing for the emails without a reply, the bounced
# emails and the five replies that carry no greeting code. TreatmentGroup
# reads "Hispanic male", "white female" and so on.

# ---- 8PTRZ: the test of a table ---------------------------------------------
# Hispanic against all other names among the replies with a greeting code.
# chisq.test() applies the continuity correction of Yates to a 2 x 2 table
# unless told otherwise, and the recorded value is the corrected one.
coded_replies <- original |>
  datawizard::data_filter(!is.na(ProperName)) |>
  datawizard::data_modify(hispanic_name = grepl("^Hispanic", TreatmentGroup))
nrow(coded_replies)   # 558

tab_8ptrz <- xtabs(~ hispanic_name + ProperName, data = coded_replies)  # r-style: keep – the table that chisq.test() takes
tab_8ptrz
chisq.test(tab_8ptrz)                    # X-squared = 14.265
chisq.test(tab_8ptrz, correct = FALSE)   # X-squared = 14.952

# ---- UYV3F: a logistic regression --------------------------------------------
# Hispanic against white names among their coded replies, no covariates.
replies_uyv3f <- original |>
  datawizard::data_filter(!is.na(ProperName) & !grepl("^black", TreatmentGroup)) |>
  datawizard::data_modify(hispanic_name = grepl("^Hispanic", TreatmentGroup))
m_uyv3f <- glm(ProperName ~ hispanic_name, family = binomial(), data = replies_uyv3f)
nobs(m_uyv3f)   # 362
print(parameters::model_parameters(m_uyv3f, ci_method = "wald"), digits = 3)   # z = -3.771

# ---- EWFMI: a model of three groups ------------------------------------------
# The three groups with the Hispanic names as the base group (Stata ib2.race),
# the sex of the name, the poverty third as a number and the hard-to-find
# address. The coefficient of the white names compares them with the Hispanic
# names, so its z is positive.
replies_ewfmi <- original |>
  datawizard::data_filter(!is.na(ProperName)) |>
  datawizard::data_separate(select = "TreatmentGroup", new_columns = c("ethnicity", "name_sex"),
                            separator = " ", append = TRUE) |>
  datawizard::data_modify(ethnicity = factor(ethnicity, levels = c("Hispanic", "black", "white")))
m_ewfmi <- glm(ProperName ~ ethnicity + name_sex + poverty_pop_third + HardEmail,
               family = binomial(), data = replies_ewfmi)
nobs(m_ewfmi)   # 549: the replies without a poverty third drop out
print(parameters::model_parameters(m_ewfmi, ci_method = "wald"), digits = 3)   # ethnicity [white]: z = 3.645

# ---- 25N5D: every delivered email --------------------------------------------
# Hispanic against white names among the delivered emails, a missing reply
# counted as no greeting and the five uncoded replies left in the
# denominators. prop.test() applies the continuity correction by default too.
counts_25n5d <- original |>
  datawizard::data_filter(!is.na(Response_Dichotomous) & !grepl("^black", TreatmentGroup)) |>
  datawizard::data_modify(hispanic_name = grepl("^Hispanic", TreatmentGroup),
                          greeted = Response_Dichotomous == 1 & ProperName %in% 1) |>
  datawizard::data_summary(greetings = sum(greeted), emails = n(), by = "hispanic_name")
counts_25n5d   # 308 + 357 = 665 emails
prop.test(counts_25n5d$greetings, counts_25n5d$emails)                   # X-squared = 13.683
prop.test(counts_25n5d$greetings, counts_25n5d$emails, correct = FALSE)  # X-squared = 14.334

# ---- P9W8Y: a test of three groups -------------------------------------------
# The three groups among the coded replies, and the likelihood-ratio test of
# the groups against a model without them. Multi100 recorded no statistic for
# this analysis, so there is nothing on record to match; the report that the
# analyst filed gives chi-square = 15.951 on 2 df.
replies_p9w8y <- original |>
  datawizard::data_filter(!is.na(ProperName)) |>
  datawizard::data_separate(select = "TreatmentGroup", new_columns = c("ethnicity", "name_sex"),
                            separator = " ", append = TRUE) |>
  datawizard::data_modify(ethnicity = factor(ethnicity, levels = c("white", "black", "Hispanic")))
m_p9w8y <- glm(ProperName ~ ethnicity, family = binomial(), data = replies_p9w8y)
nobs(m_p9w8y)   # 558
anova(update(m_p9w8y, . ~ 1), m_p9w8y, test = "LRT")   # Deviance = 15.951 on 2 df
