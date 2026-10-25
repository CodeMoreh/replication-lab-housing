##############################################################################
# Title:        Working script – the housing-audit exercise, plain R
# Purpose:      Tasks 1 to 5 of index.qmd, as a script you can step through in
#               the console: check the setup, look at the emails and draw the
#               causal graph, reproduce the value that Multi100 recorded for
#               analyst 8PTRZ (chi-square = 14.265), explore the specification
#               menu, then preregister one specification and fit and report
#               it. Every fit is live and takes a moment.
# Reads:        data/housing_audit.csv (the 1,014 emails of the course file);
#               data/audit_original.csv (the public file of the original
#               authors); through R/spec_tools.R, data/spec_curve.csv (the
#               curve of 64, for the place of each fit) and
#               data/menu_options.csv (the reason for every option that is not
#               on the curve)
# Writes:       – (prints results to the console; the submit helpers print a
#               pre-filled form link)
# Author:       Chris Moreh
# Last updated: 2026-10-25
##############################################################################

## ---- Task 1: the setup check ---------------------------------------------

# Prints an [OK] line per check, ending with the reproduction of the
# reference specification (-19.97 percentage points).
source("R/check_setup.R")

library(dplyr)
library(readr)
library(ggplot2)

# The one working object, and the helpers that explore, preregister, fit and
# report a specification.
audit <- read_csv("data/housing_audit.csv", show_col_types = FALSE)
source("R/spec_tools.R")

## ---- Task 2: the emails, the estimand and the graph ----------------------

# One row per email: 1,014 emails, 23 of which bounced. reply is missing for a
# bounced email, and named is recorded for replies only (five replies carry no
# greeting code).
audit |>
  summarise(emails    = n(),
            bounced   = sum(is.na(reply)),
            delivered = sum(!is.na(reply)),
            replies   = sum(reply %in% 1),
            coded     = sum(!is.na(named)))

# By group of names: the replies, and the greetings by name among the coded
# replies.
audit |>
  filter(!is.na(reply)) |>
  summarise(delivered   = n(),
            replies     = sum(reply == 1),
            coded       = sum(!is.na(named)),
            greeted     = sum(named %in% 1),
            greeted_pct = round(100 * greeted / coded, 1),
            .by = group)

# The causal graph. Open R/dag_starter.R, take the # off the arrow
# "name -> greeting" if you believe it, and source the file again.
source("R/dag_starter.R")
plot_dag(dag)

# What has to be adjusted for, if the comparison counts every delivered email?
adjustmentSets(dag)

# Which paths from the name to the greeting are open, and which open up once
# the comparison is made among replies only?
paths(dag)
paths(dag, Z = "reply")
paths(dag, Z = c("reply", "community"))

## ---- Task 3: reproduce the recorded result -------------------------------

# The value that Multi100 recorded for analyst 8PTRZ, from the public file of
# the original authors. Type your X-squared into the chat and send it on the
# facilitator's word.
original <- read_csv("data/audit_original.csv", show_col_types = FALSE)

coded_replies <- original |>
  filter(!is.na(ProperName)) |>
  mutate(hispanic_name = grepl("^Hispanic", TreatmentGroup))

tab_8ptrz <- xtabs(~ hispanic_name + ProperName, data = coded_replies)
tab_8ptrz
chisq.test(tab_8ptrz)                    # X-squared = 14.265, with the continuity correction
chisq.test(tab_8ptrz, correct = FALSE)   # X-squared = 14.952, without it

# Optional: the logit of analyst UYV3F, z = -3.771 on 362 replies.
m_uyv3f <- glm(ProperName ~ hispanic_name, family = binomial(),
               data = filter(coded_replies, !grepl("^black", TreatmentGroup)))
coef(summary(m_uyv3f))

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

# Level 1 – Estimands (each of these changes what is being estimated)
my_outcome    <- "named"     # named   (greeted by name, the outcome of the claim)
my_comparison <- "white"     # white | nonhispanic   (white names, or white and Black names)
my_population <- "replies"   # replies | all   (replies only, or every delivered email)
my_names      <- "both"      # both   (male and female names pooled)
my_officials  <- "any"       # any    (replies from every official)

# Level 2 – Measurement (the same question, put to the data differently)
my_uncoded    <- "drop"      # drop | not_named   (the five replies without a greeting code)
my_bounced    <- "exclude"   # exclude   (the 23 emails that never arrived)

# Level 3 – Estimation (the same question and measures, another fit)
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
spec_curve <- read_csv("data/spec_curve.csv", show_col_types = FALSE) |>
  arrange(b_pp) |>
  mutate(rank = row_number(),
         mine = comparison == my_comparison & population == my_population &
           uncoded == my_uncoded & model == my_model & adjust == my_adjust)

ggplot(spec_curve, aes(x = rank, y = b_pp)) +
  geom_hline(yintercept = 0, colour = "grey60") +
  geom_point(aes(colour = population), size = 2) +
  geom_point(data = filter(spec_curve, mine), shape = 21, size = 5, stroke = 1.2,
             colour = "#8b1538") +
  scale_colour_manual(values = c(replies = "#0e3b6a", all = "#2b8585"),
                      breaks = c("replies", "all"),
                      labels = c(replies = "replies only", all = "all delivered emails"),
                      name = "Emails counted") +
  labs(x = "The 64 specifications, from the most negative estimate",
       y = "Hispanic minus comparison names (points)") +
  theme_minimal()
