# Codebook: `menu_options.csv`

`menu_options.csv` lists every option of the specification menu of the housing-audit case, one row per option, 33 rows over 11 decisions. For each option it records whether it is on the curve of the claim, the 64 specifications of `spec_curve.csv` ([codebook](spec_curve_codebook.md)), which page of the course teaches it, and the reasoning on whether it answers the claim under test, "Hispanic housing applicants were ... less likely to be greeted by name than were ... white counterparts", in the wording that SCORE took from the paper of the original authors (OAs). The file is written by hand, not by a script. It follows the schema of the menu file of the EU-frames case, with one judgement added, `unavailable`, for an option that the public file cannot support.

Three parts of the course read it. The decision map (`cases/housing/map.qmd`) builds its stages, its selectable options, the estimand statement and the description of each option from it. The specification menu (`cases/housing/menu.qmd`) builds its tables of the three levels from it. And the helpers of the browser lab and of the workspace read `axis`, `option`, `on_curve`, `taught_on` and `reason` to explain why an option off the curve is refused, so those five columns and the codes in them must not change without a matching change in the helpers.

## Columns

| Column | Meaning |
|:--|:--|
| `axis` | The decision, as a code: `outcome`, `comparison`, `population`, `names`, `officials` (Level 1); `uncoded`, `bounced` (Level 2); `model`, `adjust`, `inference`, `scale` (Level 3). The five decisions that vary on the curve, `comparison`, `population`, `uncoded`, `model` and `adjust`, carry the codes of the columns of `spec_curve.csv` and of the arguments of `try_spec()` |
| `level` | `estimand`, `measurement` or `estimation`, the level of the menu at which the decision sits |
| `option` | The option code, as the curve, the deviation file and the helpers write it |
| `label` | A short label for the option, used on the decision map, in the tables of the menu and in messages |
| `on_curve` | `TRUE` for an option that the curve of 64 keeps (18 rows), `FALSE` for one that the course teaches off the curve (15 rows) |
| `taught_on` | The page that teaches the option, as a path from the project root: `cases/housing/index.qmd`, `cases/housing/menu.qmd`, `cases/housing/multiverse.qmd`, `companion/experiments.qmd` or `companion/binary-outcomes.qmd`. A page in `cases/housing/` links to it two levels up |
| `reason` | One sentence on why the option is or is not on the curve, used by the helpers in their messages and by the verdict of the decision map |
| `decision` | The name of the decision, as the decision map and the menu print it |
| `stage` | The stage of the decision map at which the decision is made: `data` (the emails counted, the names, who replied, the bounced emails), `outcome` (the outcome and the replies without a greeting code), `comparison`, `model` (the model and the adjustment) or `inference` (the test and the effect scale) |
| `judgement` | The verdict on the option for this claim: `kept` (on the curve, a defensible answer; 18 rows); `other_question` (it answers a different question, about another outcome, another comparison or a subgroup; 6); `weaker_answer` (it answers this question, but less well than the options on the curve; 2); `check` (a diagnostic or a second fit of an answer that the curve already holds; 6); `unavailable` (it would answer the question, but the public file cannot support it; 1, the continuous census values). The decision map labels the last "Not in the public file" |
| `phrase` | The phrase that the option writes into the estimand statement of the decision map |
| `estimates` | What the option estimates, in one sentence |
| `explanation` | Two or three sentences on whether and why the option answers the claim, for the description that the decision map opens when the option is selected |

## The phrases of the estimand statement

The decision map assembles the statement from the `phrase` column in a fixed order: "[Emails counted], [names], [who replied], the difference in the share that drew [outcome] between Hispanic names and [comparison group] ([replies without a greeting code], [bounced emails])." The phrases of the emails counted begin with "among", which the page capitalises. A second sentence carries the Level 3 decisions: "Estimated with [model], [adjustment], tested by [test] and reported [effect scale]." One option rewrites more than its own phrase: the comparison of Black with white names (`comparison` = `black`) replaces "Hispanic names and [comparison group]" with "Black names and white names", because it compares a different pair of groups.

## Options with numbers elsewhere

Only the options on the curve are fitted across the curve. Six options off the curve are fitted once, at the reference settings, by the displays beside the curve ([codebook](displays_codebook.md)): the reply and the reply within 24 hours (`display_outcomes.csv`), the comparison of Black with white names (`display_outcomes.csv`), the male and the female names, and the replies from officials with Hispanic names (`display_subgroups.csv`). The decision map shows those estimates when one of these options is selected. The specification menu computes three more on the page from the data files: the bounced emails counted as unanswered and the sex of the name as a covariate from `housing_audit.csv`, and the uncorrected $\chi^2$ test from `audit_original.csv`.

## Editing

Keep the existing columns and codes, and keep `reason` to one sentence. Every prose column is participant-facing, so it follows the writing conventions of the course: British spelling, spaced en-dashes, double quotation marks for quotation and single ones for terms held at a distance, relative clauses written out in full, and no possessive on an institution or an artefact. A new option needs a row here, a decision in the helpers about how to treat it, and, if it joins the curve, a refit of `spec_curve.csv` and `menu_deviations.csv`.
