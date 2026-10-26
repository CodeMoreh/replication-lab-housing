# Codebook: `spec_curve.csv`

The curve of the claim of the housing-audit case, "Hispanic housing applicants were ... less likely to be greeted by name than were ... white counterparts", in the wording that SCORE took from the paper of the original authors (OAs): every specification that the specification menu of the course keeps, 64 rows, fitted once on the course file `housing_audit.csv`. The file is written by `R/housing/02_spec_curve.R` with the estimator of `R/housing/_tools.R` (`fit_spec()`), which uses base R, dplyr and one function of purrr, so that the workspace and the browser lab run the identical code; `R/housing/check_parity.R` checks it against `estimatr` (HC2 errors) and `marginaleffects` (average marginal effects) on every row.

## The specifications

Five decisions vary on the curve, and every combination of their options is one row: 2 × 2 × 2 × 2 × 4 = 64.

| Column | Options | Meaning |
|:--|:--|:--|
| `comparison` | `white`, `nonhispanic` | Hispanic names against white names, or against the white and Black names together |
| `population` | `replies`, `all` | Only the emails that drew a reply, or every delivered email, an email without a reply counting as one without a named greeting |
| `uncoded` | `drop`, `not_named` | The five replies without a greeting code left out, or counted as replies that did not open with a name |
| `model` | `lpm`, `logit` | A linear probability model, whose coefficient is the difference in proportions, or a logistic regression, reported as an average marginal effect |
| `adjust` | `none`, `email`, `place`, `place_ethnic` | No covariates; the hard-to-find address (`hard_email`); that with the thirds of population and poverty (`pop_third`, `poverty_third`); that with the thirds of percent Black and percent Hispanic as well (`black_third`, `hispanic_third`) |

The other decisions of the menu take one option on every row: the outcome is the named greeting, male and female names are pooled, every reply counts whoever wrote it, the bounced emails are left out, each specification is tested by its own model, and the estimate is reported in percentage points. `menu_options.csv` lists every option ([codebook](menu_options_codebook.md)).

The analysed rows of a specification are the delivered emails of the groups that it compares, restricted to the replies when `population` is `replies`, without the uncoded replies when `uncoded` is `drop`, and without the emails that lack a covariate of the adjustment set; 14 emails lack the community thirds. The thirds enter as three categories and `hard_email` as a 0/1 indicator.

The reference specification (`is_reference`) is `white`, `replies`, `drop`, `lpm`, `none`, the raw gap of the paper: 41.2% of the replies to Hispanic names against 61.1% of those to white names opened with the name, a gap of −19.97 points, t = −3.87 on 360 df, on 362 replies.

## Columns

| Column | Meaning |
|:--|:--|
| `spec_id` | The row number, 1 to 64, in the order of `expand_grid()` over the five decisions |
| `comparison`, `population`, `uncoded`, `model`, `adjust` | The options of the specification, as above. These are the arguments of `fit_spec()` and of `try_spec()` in the exercise |
| `b_pp` | The estimate in percentage points: 100 times the coefficient of the Hispanic names for the linear model, and 100 times the average marginal effect for the logit, the difference in the predicted probability of a named greeting between a Hispanic and a comparison name, averaged over the analysed emails. Negative values mean that Hispanic names were greeted by name less often, the direction of the claim |
| `se_pp` | The standard error of `b_pp` in points: the HC2 error for the linear model, from parameters with sandwich, and for the logit the delta-method error of the average marginal effect, from marginaleffects |
| `coef`, `coef_se` | The coefficient of the Hispanic names on the scale of the model (a proportion for the linear model, a log odds for the logit) and its standard error (HC2 for the linear model, the usual model-based error for the logit) |
| `stat_type` | `t` for the linear model, `z` for the logit |
| `stat` | `coef` divided by `coef_se` |
| `df` | The residual degrees of freedom of the linear model; empty for the logit |
| `p` | The two-sided p-value of the test of the model: `stat` on `df` for the linear model, on the normal distribution for the logit. This is the test that classes every row |
| `r` | The partial correlation by the rules of Multi100: t / sqrt(t^2 + df) for a t, and tanh(\|z\| / sqrt(n − 3)) with the sign of z for a z, the number of emails standing in for the missing degrees of freedom |
| `n` | The emails analysed |
| `n_hisp`, `n_comp` | The analysed emails with Hispanic names and with comparison names |
| `rate_hisp`, `rate_comp` | The share of the analysed emails in each group whose outcome is 1, in per cent, before any adjustment |
| `p_ri` | The p-value of a randomisation test, kept as a check: the names are reshuffled 1,999 times among the analysed emails by complete random assignment, as many Hispanic names as the design gave them, and the model is refitted after each reshuffle (ri2), each specification with its own seed (20261025 plus `spec_id`); p = (1 + the number of reshuffles whose coefficient is at least as large in absolute value as the observed one) / 2,000, the permutation p-value of `statmod::permp()` for reshuffles drawn at random. The smallest possible value is therefore 0.0005 |
| `supports` | `b_pp` < 0 |
| `sig` | `p` < 0.05 |
| `is_reference` | TRUE for the reference specification only |

## What the curve shows

All 64 specifications are negative and significant at the 5% level under the test of their own model. The estimates run from −20.0 to −12.1 points, with standard errors from 2.86 to 5.27 points, and the p-values from 0.00001 to 0.0010. The linear models give t from −4.43 to −3.31 on 346 to 989 df, and the logits z from −4.19 to −3.29. The randomisation test gives p = 0.0005 for 45 specifications, 0.001 for 16, 0.0015 for 2 and 0.0025 for 1. The partial correlations run from −0.200 to −0.128, and the analysed emails from 357 to 991.

The emails counted divide the curve. Among the replies the estimates run from −20.0 to −15.8 points (mean −17.7), and among all delivered emails from −13.3 to −12.1 (mean −12.7), because fewer than six in ten delivered emails drew any reply. The other decisions move the estimate by at most 2.7 points, as `menu_deviations.csv` records ([codebook](menu_deviations_codebook.md)).
