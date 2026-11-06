##############################################################################
# Title:        Working script – the housing-audit exercise, plain R
# Purpose:      Tasks 1 to 5 of index.qmd, as a script you can step through in
#               the console: check the setup, look at the emails and draw the
#               causal graph, reproduce one of the five Multi100 reanalyses
#               (the four with a recorded statistic come out exactly), explore
#               the specification menu, then preregister one specification and
#               fit and report it. Every fit is live and takes a moment.
# Reads:        data/housing_audit.csv (the 1,014 emails of the course file);
#               data/audit_original.csv (the public file of the original
#               authors); through R/spec_tools.R, data/spec_curve.csv (the
#               curve of 64, for the place of each fit) and
#               data/menu_options.csv (the reason for every option that is not
#               on the curve)
# Writes:       – (prints results to the console; the submit helpers print a
#               pre-filled form link)
# Author:       Chris Moreh
# Last updated: 2026-10-27
##############################################################################

## ---- Task 1: the setup check ---------------------------------------------

# Prints an [OK] line per check, ending with the reproduction of the
# reference specification (-19.97 percentage points).
source("R/check_setup.R")

# Every function is written with the package that it comes from, as in
# readr::read_csv(). The one working object, and the helpers that explore,
# preregister, fit and report a specification.
audit <- readr::read_csv("data/housing_audit.csv", show_col_types = FALSE)
source("R/spec_tools.R")

## ---- Task 2: the emails, the estimand and the graph ----------------------

# One row per email: 1,014 emails, 23 of which bounced. reply is missing for a
# bounced email, and named is recorded for replies only (five replies carry no
# greeting code).
audit |>
  datawizard::data_summary(emails    = n(),
                           bounced   = sum(is.na(reply)),
                           delivered = sum(!is.na(reply)),
                           replies   = sum(reply %in% 1),
                           coded     = sum(!is.na(named)))

# By group of names: the replies, and the greetings by name among the coded
# replies.
audit |>
  datawizard::data_filter(!is.na(reply)) |>
  datawizard::data_summary(delivered   = n(),
                           replies     = sum(reply == 1),
                           coded       = sum(!is.na(named)),
                           greeted     = sum(named %in% 1),
                           greeted_pct = round(100 * sum(named %in% 1) / sum(!is.na(named)), 1),
                           by = "group")

# The causal graph. Open R/dag_starter.R, take the # off the arrow
# "name -> greeting" if you believe it, and source the file again.
source("R/dag_starter.R")
plot_dag(dag)

# What has to be adjusted for, if the comparison counts every delivered email?
dagitty::adjustmentSets(dag)

# Which paths from the name to the greeting are open, and which open up once
# the comparison is made among replies only?
dagitty::paths(dag)
dagitty::paths(dag, Z = "reply")
dagitty::paths(dag, Z = c("reply", "community"))

## ---- Task 3: reproduce one of the five reanalyses ------------------------

# Choose one of the five analysts and run their section. Each reproduces the
# analysis from the public file of the original authors, with the value that
# Multi100 recorded beside it. When you have your value, type the analyst and
# the value into the chat, for example "UYV3F z = -3.771", and send it on the
# facilitator's word.
original <- readr::read_csv("data/audit_original.csv", show_col_types = FALSE)

# 8PTRZ: Hispanic against all other names among the 558 replies with a
# greeting code, a chi-square test of the 2 x 2 table. Recorded: 14.265.
coded_replies <- original |>
  datawizard::data_filter(!is.na(ProperName)) |>
  datawizard::data_modify(hispanic_name = grepl("^Hispanic", TreatmentGroup))
tab_8ptrz <- xtabs(~ hispanic_name + ProperName, data = coded_replies)  # r-style: keep – the table that chisq.test() takes
tab_8ptrz
chisq.test(tab_8ptrz)                    # X-squared = 14.265, with the continuity correction
chisq.test(tab_8ptrz, correct = FALSE)   # X-squared = 14.952, without it

# UYV3F: Hispanic against white names among their 362 coded replies, a
# logistic regression without covariates. Recorded: z = -3.771.
replies_uyv3f <- original |>
  datawizard::data_filter(!is.na(ProperName) & !grepl("^black", TreatmentGroup)) |>
  datawizard::data_modify(hispanic_name = grepl("^Hispanic", TreatmentGroup))
m_uyv3f <- glm(ProperName ~ hispanic_name, family = binomial(), data = replies_uyv3f)
nobs(m_uyv3f)
print(parameters::model_parameters(m_uyv3f, ci_method = "wald"), digits = 3)

# EWFMI: the three groups with the Hispanic names as the base group, the sex
# of the name, the poverty third as a number and the hard-to-find address;
# the 9 coded replies without a poverty third drop out. Recorded: z = 3.645,
# the row of the white names, positive because the base is Hispanic.
replies_ewfmi <- original |>
  datawizard::data_filter(!is.na(ProperName)) |>
  datawizard::data_separate(select = "TreatmentGroup", new_columns = c("ethnicity", "name_sex"),
                            separator = " ", append = TRUE) |>
  datawizard::data_modify(ethnicity = factor(ethnicity, levels = c("Hispanic", "black", "white")))
m_ewfmi <- glm(ProperName ~ ethnicity + name_sex + poverty_pop_third + HardEmail,
               family = binomial(), data = replies_ewfmi)
nobs(m_ewfmi)
print(parameters::model_parameters(m_ewfmi, ci_method = "wald"), digits = 3)

# 25N5D: Hispanic against white names among the 665 delivered emails, no
# reply counted as no greeting and the five uncoded replies left in the
# denominators, a two-proportion test. Recorded: 13.683.
counts_25n5d <- original |>
  datawizard::data_filter(!is.na(Response_Dichotomous) & !grepl("^black", TreatmentGroup)) |>
  datawizard::data_modify(hispanic_name = grepl("^Hispanic", TreatmentGroup),
                          greeted = Response_Dichotomous == 1 & ProperName %in% 1) |>
  datawizard::data_summary(greetings = sum(greeted), emails = n(), by = "hispanic_name")
counts_25n5d
prop.test(counts_25n5d$greetings, counts_25n5d$emails)                   # X-squared = 13.683
prop.test(counts_25n5d$greetings, counts_25n5d$emails, correct = FALSE)  # X-squared = 14.334

# P9W8Y: the three groups among the 558 coded replies, a likelihood-ratio
# test of the groups. Multi100 recorded no statistic, so there is nothing to
# match; the report of the analyst gives chi-square = 15.951 on 2 df.
replies_p9w8y <- original |>
  datawizard::data_filter(!is.na(ProperName)) |>
  datawizard::data_separate(select = "TreatmentGroup", new_columns = c("ethnicity", "name_sex"),
                            separator = " ", append = TRUE) |>
  datawizard::data_modify(ethnicity = factor(ethnicity, levels = c("white", "black", "Hispanic")))
m_p9w8y <- glm(ProperName ~ ethnicity, family = binomial(), data = replies_p9w8y)
nobs(m_p9w8y)
anova(update(m_p9w8y, . ~ 1), m_p9w8y, test = "LRT")

## ---- Task 4: work the menu ------------------------------------------------

# try_spec() takes one argument per decision of the menu, and every one
# defaults to the reference specification, so changing one thing means
# changing one argument. The first five are the decisions on which the curve
# keeps more than one option. The specification that you submit with
# submit_exploration() is labelled exploratory on the class chart and carries
# the tag that the function prints and keeps in .class-tag;
# submit_exploration(nickname = "...") sets your own (a nickname, not your name).
try_spec()                                # the raw gap of the paper
try_spec(comparison = "nonhispanic")      # Hispanic names against white and Black names together
try_spec(population = "all")              # every delivered email, no reply counted as no greeting
try_spec(uncoded    = "not_named")        # the five uncoded replies counted as no greeting
try_spec(model      = "logit")            # the model of the paper, as an average marginal effect
try_spec(adjust     = "place_ethnic")     # the covariates of the original model, in thirds

# Options that are not on the curve are refused with the reason why and the
# page of the course site that teaches them; try() prints the refusal and lets
# the rest of the script run.
try(try_spec(model = "three_group"))      # all three groups in one model
try(try_spec(outcome = "reply"))          # any reply, a different claim

# The running log of everything you have tried. Only the decisions that
# varied are printed.
my_experiments()

# Send the most recent one to the class chart, labelled as exploration.
submit_exploration()

## ---- Task 5: preregister one specification --------------------------------

# One choice on each decision. An option that is not on the curve stops
# prereg() with the reason why.

# The question (each of these changes what is being estimated)
my_outcome    <- "named"     # named   (greeted by name, the outcome of the claim)
my_comparison <- "white"     # white | nonhispanic   (white names, or white and Black names)
my_population <- "replies"   # replies | all   (replies only, or every delivered email)
my_names      <- "both"      # both   (male and female names pooled)
my_officials  <- "any"       # any    (replies from every official)

# Measurement (the same question, put to the data differently)
my_uncoded    <- "drop"      # drop | not_named   (the five replies without a greeting code)
my_bounced    <- "exclude"   # exclude   (the 23 emails that never arrived)

# The model (the same question and measures, another fit)
my_model      <- "lpm"       # lpm | logit   (difference in proportions, or logistic regression)
my_adjust     <- "none"      # none | email | place | place_ethnic
my_inference  <- "model"     # model   (HC2 t test, or the z test of the logit)
my_scale      <- "pp"        # pp   (percentage points)

my_spec <- prereg()   # checks every choice, prints your preregistration and keeps it

## ---- Task 5, continued: fit, report and place -----------------------------

run_spec(my_spec)

# report_result() works from the preregistration and reuses the tag from
# Task 4. Open the printed link and press Send.
report_result()

# Your result among the 64 specifications of the curve.
spec_curve <- readr::read_csv("data/spec_curve.csv", show_col_types = FALSE) |>
  datawizard::data_arrange("b_pp") |>
  datawizard::data_modify(rank = 1:n(),
                          emails = factor(population, levels = c("replies", "all"),
                                          labels = c("replies only", "all delivered emails")))
# Yours, chosen with dplyr, because datawizard cannot see the my_ choices of
# the preregistration above
mine <- spec_curve |>
  dplyr::filter(comparison == my_comparison, population == my_population, uncoded == my_uncoded,
                model == my_model, adjust == my_adjust)

tinyplot::tinytheme("minimal")
tinyplot::tinyplot(b_pp ~ rank | emails, data = spec_curve, pch = 16,
                   palette = c("#0e3b6a", "#2b8585"), legend = list("right!", title = "Emails counted"),
                   ylim = c(min(spec_curve$b_pp), 0),
                   xlab = "The 64 specifications, from the most negative estimate",
                   ylab = "Hispanic minus comparison names (points)")
tinyplot::tinyplot(b_pp ~ rank, data = spec_curve, type = tinyplot::type_hline(h = 0), col = "grey60", add = TRUE)
# your specification, ringed; clim keeps a single ring at the size of cex
tinyplot::tinyplot(b_pp ~ rank, data = mine, type = tinyplot::type_points(clim = c(3, 3)),
                   pch = 1, cex = 3, lwd = 2.5, col = "#8b1538", add = TRUE)
tinyplot::tinytheme()
