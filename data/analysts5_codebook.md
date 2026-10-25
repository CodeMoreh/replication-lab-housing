# Codebook: `analysts5.csv`

The Multi100 record of the five reanalyses of the claim of the housing-audit case, one row per analyst, with the choices that each analysis made and the course refit of it on the public file. It is written by `R/housing/03_reference_marks.R` from the five rows of the processed Multi100 data for this paper (`data-raw/housing/multi100/multi100_einstein_extract.csv`, an extract of the public Multi100 file) and from refits of the scripts that the analysts published on the OSF, in the Multi100 component of the paper (osf.io/38rsh). The course links to those scripts and does not copy them. The same script writes `reference_marks.csv` ([codebook](reference_marks_codebook.md)), which places the five analyses on the chart.

## Columns

| Column | Meaning |
|:--|:--|
| `id` | The identifier that Multi100 gave the analyst: `8PTRZ`, `UYV3F`, `EWFMI`, `25N5D` or `P9W8Y` |
| `discipline` | The primary discipline that the analyst reported |
| `hours` | The hours that the analyst reported for the two tasks together |
| `task1` | The conclusion of Task 1, shortened from the four categories of Multi100: `evidence for the claim` or `no evidence either way` (the other two, evidence for the null and evidence for the opposite, do not occur) |
| `direction` | The direction of the Task 2 result that the analyst ticked; "Same as claimed by the original study" for all five |
| `statistic_type`, `statistic_recorded` | The statistic of Task 2 as Multi100 recorded it: `chi2` or `z`, and its value, with the sign that the analyst typed; empty for P9W8Y |
| `df_recorded` | The degrees of freedom of the record: 1 for the two $\chi^2$ tests, empty otherwise |
| `n_recorded` | The sample size of the record |
| `r_recorded`, `d_recorded` | The partial correlation and the Cohen's d that Multi100 computed from the statistic. A z converts on the sample size, r = tanh(\|z\| / sqrt(n − 3)) with the sign of z, and a $\chi^2$ on one degree of freedom as the square of a z, which has no sign; d is positive for all four, because Multi100 took its direction from the box that each analyst ticked |
| `comparison` | The groups that the analysis compared, in the words of the course |
| `population` | The emails counted: `replies` or `all delivered emails` |
| `method` | The test or model, in the words of the course |
| `statistic_refit` | The statistic of the course refit of the script on the public file. For P9W8Y it is the likelihood-ratio $\chi^2$ of the three groups on 2 degrees of freedom, the omnibus test that the analysis reported |
| `n_refit` | The emails in the refit |
| `b_pp_refit` | The gap between Hispanic names and the comparison names in percentage points, from the refit: the difference in proportions for the two tests of a table, the average marginal effect for the logistic regressions |
| `matches_record` | `TRUE` where the refit reproduces the recorded statistic to within 0.0015 in absolute value and on the same number of emails; empty for P9W8Y, which has no recorded statistic |

## The five rows

| Analyst | Recorded statistic | n | r recorded | d recorded | Gap (points) | Task 1 |
|:--|--:|--:|--:|--:|--:|:--|
| 8PTRZ | $\chi^2$ = 14.265 | 558 | 0.159 | 0.322 | −17.3 | evidence for the claim |
| UYV3F | z = −3.771 | 362 | −0.196 | 0.401 | −20.0 | evidence for the claim |
| EWFMI | z = 3.645 | 549 | 0.155 | 0.313 | −19.4 | evidence for the claim |
| 25N5D | $\chi^2$ = 13.683 | 665 | 0.143 | 0.289 | −13.2 | no evidence either way |
| P9W8Y | – | – | – | – | −20.0 | no evidence either way |

The four recorded statistics reproduce exactly. The report that P9W8Y filed for Task 2 gives the omnibus test, $\chi^2$ = 15.951 on 2 degrees of freedom for 558 replies, in its text, but Multi100 recorded no statistic for the analysis, and the course refit gives the same value. The [case study](../index.qmd#sec-reanalysts) sets out what question each analysis answered.
