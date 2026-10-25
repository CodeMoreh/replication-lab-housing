# Codebook: `reference_marks.csv`

The multiverse chart of the housing-audit case marks results that come from outside the curve: the published result of the original authors (OAs) and the five reanalyses of the same claim that Multi100 recorded. `reference_marks.csv` places each of them on the scale of the curve, the gap in percentage points between Hispanic names and the comparison names, and keeps beside it the statistic of the record and a note on how the mark was placed: 8 rows, of which 7 are drawn on the chart. It is written by `R/housing/03_reference_marks.R` from the course file `housing_audit.csv`, from the Multi100 record of the five analyses and from the paper, together with `analysts5.csv` ([codebook](analysts5_codebook.md)); `R/housing/06_replication.R` then adds the row `SCORE`, the replication with new data.

## How each result is placed

Every mark is a gap in percentage points, the scale of the claim and of the curve. The published result is placed by the number that the paper gives on that scale: the change in the predicted probability of a named greeting from a white to a Hispanic name, with the other variables at their means, −20.0 points with a 95% confidence interval from −30.5 to −10.0 (Table 1, model 3, and p. 18 of the accepted manuscript). Its statistic is the published logit coefficient divided by its standard error, −0.82 / 0.22.

The five analyses are placed by the course refits of their scripts on the public file, which reproduce the four recorded statistics exactly. Each refit gives its gap in points in the way that suits its model: the difference in proportions for the tests of a table (8PTRZ, Hispanic against all other names among the replies; 25N5D, Hispanic against white names among all delivered emails, the uncoded replies counted as no greeting), and the average marginal effect of a Hispanic against a white name for the logistic regressions (UYV3F, without covariates; EWFMI, with the sex of the name, the poverty third entered as a number and the hard-to-find address, averaged over its 549 replies of all three groups; P9W8Y, the three-group model without covariates). Without covariates the average marginal effect of a logit equals the difference in proportions, which is why UYV3F and P9W8Y sit exactly on the raw gap of the paper.

The SCORE replication (`SCORE`) is placed by the raw gap between its Hispanic and white aliases among all 1,484 replies of its new audit, +0.0 points (t = 0.00 with HC2 errors), computed by the course from the de-identified data that the replication published on the OSF (osf.io/xseqg); `display_replication.csv` holds the other samples ([codebook](displays_codebook.md)).

The refit of the model of the OAs on the public file (`OA_blinded`) is kept for the teaching but not drawn. The public file holds the community covariates only as thirds, so the refit, a logit of the greeting on the three groups with the thirds of percent Black, percent Hispanic, population and poverty and the hard-to-find address, approximates the published model by design.

## Columns

| Column | Meaning |
|:--|:--|
| `id` | `OA`, `OA_blinded`, `8PTRZ`, `UYV3F`, `EWFMI`, `25N5D`, `P9W8Y` or `SCORE` |
| `label` | A longer label for the two marks of the OAs and the identifier for the analysts. The chart prints the mark of `OA` as "OAs 2017" |
| `statistic_type` | `z`, `chi2`, `LR chi-square (2 df)` for P9W8Y, or `t` for SCORE |
| `statistic` | The statistic as the paper gives it (`OA`), as the refit gives it (`OA_blinded`), as Multi100 recorded it (four analysts), or as the refit gives it where Multi100 recorded none (P9W8Y). Signs are as recorded: the z of EWFMI is positive because its model takes the Hispanic names as the base, and a $\chi^2$ has no sign |
| `n` | The emails in the analysis: 549 replies for the model of the OAs, the replies or delivered emails of each refit for the analysts |
| `b_pp` | The gap in percentage points by which the result is placed; negative values mean that Hispanic names were greeted by name less often |
| `on_chart` | `TRUE` for the six results of the original data and for `SCORE`, `FALSE` for `OA_blinded`; the figures of the original data leave `SCORE` out |
| `note` | How the mark was placed |

## The marks

| Mark | Statistic | Emails | Gap (points) | On the chart |
|:--|--:|--:|--:|:--|
| OA | z = −3.73 | 549 | −20.0 | yes |
| OA_blinded | z = −3.47 | 549 | −18.4 | no |
| 8PTRZ | $\chi^2$ = 14.265 | 558 | −17.3 | yes |
| UYV3F | z = −3.771 | 362 | −20.0 | yes |
| EWFMI | z = 3.645 | 549 | −19.4 | yes |
| 25N5D | $\chi^2$ = 13.683 | 665 | −13.2 | yes |
| P9W8Y | LR $\chi^2$ = 15.951 (2 df) | 558 | −20.0 | yes |
| SCORE | t = 0.00 | 1,484 | +0.0 | yes |

The six marks of the original data lie within the range of the curve, from −20.0 to −12.1 points. 25N5D sits with the specifications that count every delivered email, and the other five with those that count the replies. The mark of the replication lies at zero, outside the range of the curve, because it comes from new data.
