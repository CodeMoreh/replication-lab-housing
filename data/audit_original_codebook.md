# Codebook: `audit_original.csv`

The public file of the original authors (OAs) of "Does Race Affect Access to Government Services? An Experiment Exploring Street-Level Bureaucrats and Access to Public Housing" (*American Journal of Political Science* 61 (1), 2017), as a plain CSV with its own column names: 1,014 rows, one per email, and 14 columns. It is written by `R/housing/01_audit_data.R` from `HousingAuditAJPSFinalPublic_Unidentified.dta`, the blinded file of the replication package on the Harvard Dataverse (doi:10.7910/DVN/1HOVTU, CC0). The script turns the Stata value labels into their numeric codes and drops the variable labels and formats; it changes no value and no row. The reproduction of Task 3 runs on this file, because a reproduction starts from the data as the OAs published them. Every other exercise uses the course file, `housing_audit.csv` ([codebook](housing_audit_codebook.md)), which holds the same rows in the same order with readable names.

## Columns

| Column | Description | In the course file |
|:--|:--|:--|
| `NumberAssignment` | The email account, assigned at random: 1 Tyrone, 2 Shanice, 3 Santiago, 4 Gabriela, 5 Brett, 6 Emily | `name`, `group`, `name_sex` |
| `TreatmentGroup` | The same assignment as text: `white male`, `white female`, `black male`, `black female`, `Hispanic male`, `Hispanic female`. The codebook of the OAs calls it redundant with `NumberAssignment` | – |
| `Response_Dichotomous` | 1 if the email received a reply, 0 if not; empty if the email bounced | `reply` |
| `WaitListFinal` | Replies only: the wait time in months that the reply gave, or a brief description such as `Closed`; empty where the reply gave none | `waitlist` |
| `ProperName` | Replies only: 1 if the reply began with any named greeting, 0 if not; empty for five replies without a code | `named` |
| `Respond24` | Replies only: 1 if the reply came within 24 hours, 0 if later | `reply24` |
| `HardEmail` | 1 if the address came from the list of housing authorities kept by the Department of Housing and Urban Development (HUD), because the authority offered no contact that could be found quickly; 0 otherwise | `hard_email` |
| `HispanicEmailer` | Replies only: 1 if the name of the official who replied was distinctively Hispanic, 0 if not | `hispanic_official` |
| `white_pop_third` | The third of the community among the communities of the study on percent non-Hispanic white: 1 lower, 2 middle, 3 top | `white_third` |
| `black_pop_third` | The same on percent non-Hispanic Black | `black_third` |
| `hispanic_pop_third` | The same on percent Hispanic | `hispanic_third` |
| `total_pop_third` | The same on total population | `pop_third` |
| `poverty_pop_third` | The same on the poverty rate | `poverty_third` |
| `assesment_third` | The third of the housing authority on the HUD assessment score; the spelling is that of the source | `assessment_third` |

The counts of every column are given in the [codebook of the course file](housing_audit_codebook.md). The community values are thirds because the continuous values of the 2012 American Community Survey would identify the housing authorities. The Stata file labels `HispanicEmailer` "Hard to find email address", a copy error in the source, and the codebook of the OAs labels it "Respondent had Hispanic name".

## The reproductions of Task 3

The five Multi100 reanalyses of the claim are reproduced from this file, and the four statistics that Multi100 recorded come out exactly.

| Analyst | Rows | Test | Recorded |
|:--|:--|:--|:--|
| 8PTRZ | the 558 replies with a greeting code (`ProperName` not empty), the Hispanic names (`TreatmentGroup` starting with `Hispanic`) against all other names | `chisq.test()` of the two-by-two table by `ProperName`, with the continuity correction that R applies to such a table unless it is told otherwise (14.95 without it) | $\chi^2$ = 14.265 |
| UYV3F | the 362 coded replies to Hispanic and white names | logistic regression of `ProperName` on the Hispanic names, without covariates | z = −3.771 |
| EWFMI | the 549 coded replies that carry `poverty_pop_third` | logistic regression of `ProperName` on the three groups with the Hispanic names as the base group, the sex of the name, `poverty_pop_third` entered as a number and `HardEmail` | z = 3.645 |
| 25N5D | the 665 delivered emails to Hispanic and white names (`Response_Dichotomous` not empty), a missing reply counted as no greeting | `prop.test()` on the greetings by name and the emails of each group, with its default continuity correction (14.33 without it) | $\chi^2$ = 13.683 |
| P9W8Y | the 558 coded replies | likelihood-ratio test of a logistic regression of `ProperName` on the three groups against a model without them | none recorded; the test gives $\chi^2$ = 15.951 on 2 df |

The group and the sex of the name are the two words of `TreatmentGroup`. The code of each reproduction is in Task 3 of the browser lab and of the downloadable workspace.
