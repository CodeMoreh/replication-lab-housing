# Codebook: `housing_audit.csv`

The course file of the housing-audit case: one row per email of the field experiment reported in "Does Race Affect Access to Government Services? An Experiment Exploring Street-Level Bureaucrats and Access to Public Housing" (*American Journal of Political Science* 61 (1), 2017, doi:10.1111/ajps.12252), whose authors the course calls the original authors (OAs). It holds 1,014 rows, with readable names and the columns that the exercises use. It is written by `R/housing/01_audit_data.R` from the public file of the OAs, and it keeps the rows of that file in the same order, so that row *i* here is row *i* of `audit_original.csv` ([codebook](audit_original_codebook.md)).

## Sources and construction

The OAs published their data and code on the Harvard Dataverse (doi:10.7910/DVN/1HOVTU) under a CC0 dedication. The public file is blinded. Its ReadMe explains that the census codes of the communities and the continuous community values would identify the housing authorities, so the file gives population, percent white, percent Black, percent Hispanic, the poverty rate and the HUD assessment score only as thirds of their distributions among the communities of the study (1 lower, 2 middle, 3 top). The experimental comparisons can be reproduced exactly from it, and the models with community covariates only approximately. Nothing in the course tries to recover the continuous values.

The paper reports 1,017 emails, and the public file holds 1,014. Each email was signed with one of six names, assigned at random. The names were meant to indicate a white, a Black or a Hispanic sender, one male and one female name for each group, and the file records the name through the number of the email account (`NumberAssignment`), which `01_audit_data.R` translates as follows.

| `NumberAssignment` | `name` | `group` | `name_sex` | Emails |
|--:|:--|:--|:--|--:|
| 1 | Tyrone | black | male | 184 |
| 2 | Shanice | black | female | 145 |
| 3 | Santiago | hispanic | male | 207 |
| 4 | Gabriela | hispanic | female | 161 |
| 5 | Brett | white | male | 172 |
| 6 | Emily | white | female | 145 |

## Variables

| Variable | Description | Source column |
|:--|:--|:--|
| `email_id` | The row number of the email in the public file, 1 to 1,014. It orders the rows and identifies nothing outside the file | – |
| `name` | The name that signed the email | `NumberAssignment` |
| `group` | The group that the name was meant to indicate: `white`, `black` or `hispanic` | `NumberAssignment` |
| `name_sex` | `male` or `female` | `NumberAssignment` |
| `hard_email` | 1 if the authority offered no contact that could be found quickly on its own website, so that the address came from the list of housing authorities kept by the Department of Housing and Urban Development (HUD), 458 emails; 0 if the authority gave an address or a contact form, 556 | `HardEmail` |
| `reply` | 1 if the authority replied (563), 0 if it did not (428); missing for the 23 emails that bounced | `Response_Dichotomous` |
| `reply24` | Replies only: 1 if the reply came within 24 hours (439), 0 if later (121); missing for 3 replies and for every email without a reply | `Respond24` |
| `named` | Replies only: 1 if the reply opened with the name of the sender, in any form from "Hi Brett" to "Dear Ms. Martinez" (294), 0 if not (264); missing for the 5 replies without a greeting code and for every email without a reply | `ProperName` |
| `hispanic_official` | Replies only: 1 if the name of the official who replied was distinctively Hispanic (40), 0 if not (522); missing for 1 reply and for every email without a reply | `HispanicEmailer` |
| `waitlist` | Replies only, as text: the length of the wait list in months as the OAs coded it from the reply (121 replies, from `0` to `120`), `Closed` (106) or `No Housing` (26); empty for the other replies and for every email without a reply | `WaitListFinal` |
| `white_third` | The third of the community on percent non-Hispanic white: `lower`, `middle` or `top`; missing for 14 emails | `white_pop_third` |
| `black_third` | The third on percent non-Hispanic Black; missing for 14 | `black_pop_third` |
| `hispanic_third` | The third on percent Hispanic; missing for 14 | `hispanic_pop_third` |
| `pop_third` | The third on total population; missing for 14 | `total_pop_third` |
| `poverty_third` | The third on the poverty rate; missing for 14 | `poverty_pop_third` |
| `assessment_third` | The third of the housing authority on the HUD assessment score, which HUD computes from physical inspection, financial assessment, management operations and the use of its Capital Fund; missing for 344 | `assesment_third` |

The community values come from the 2012 five-year estimates of the American Community Survey. Each of the five community thirds holds 333 or 334 emails in each band, except the poverty third (330, 337 and 333), and the assessment third holds 203, 258 and 209. The same 14 emails lack all five community thirds, and 9 of them drew a reply, so every specification that adjusts for the community loses them.

## Rows and missing values

The analyses of the course start from these counts.

| Emails | Count |
|:--|--:|
| In the file | 1,014 |
| Bounced (`reply` missing) | 23 |
| Delivered | 991 |
| Replied | 563 |
| Replied, without a greeting code (`named` missing) | 5 |
| Replied, with a greeting code | 558 |

A bounced email never reached an official, and every specification on the curve leaves the bounced emails out. The five replies without a greeting code are a decision of the specification menu: they are either left out or counted as replies that did not open with a name. When all delivered emails are counted, an email without a reply counts as an email without a named greeting.

## Notes

- `hispanic_official` comes from the name in the email address of the official who replied, so it exists only for replies. The Stata file of the OAs labels the source column "Hard to find email address", a copy error; their codebook labels it "Respondent had Hispanic name".
- `waitlist` keeps the text of the source. The numbers are months, sometimes converted by the OAs from phrases such as "two years", and one entry is `.5`.
- The data are dedicated to the public domain under CC0, which places no restriction on this derived file. Cite the paper and the Dataverse record when you use it.
