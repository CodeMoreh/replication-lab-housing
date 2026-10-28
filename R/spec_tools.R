##############################################################################
# Title:        spec_tools.R – explore, preregister, fit and report
# Purpose:      The estimator of the housing-audit case and the helpers that
#               the report and the working script use, in two groups.
#
#               EXPLORATORY (Task 4): try_spec() fits any specification on
#               the curve from arguments that default to the reference
#               specification, my_experiments() prints the running log, and
#               submit_exploration() sends the last one to the class chart.
#
#               DECLARED (Task 5), where one specification is fixed in the
#               preregistration block before it is fitted: prereg() checks it
#               against the menu and prints it, run_spec() fits it, and
#               report_result() submits it.
#
#               The menu has eleven decisions, and the curve of the claim
#               keeps 64 specifications of them. An option that is not on the
#               curve stops with the reason recorded in data/menu_options.csv
#               and the page of the course site that teaches it. Every
#               specification is fitted live by fit_spec(), the estimator that
#               built the curve, and placed among the 64 of
#               data/spec_curve.csv. The fits use parameters, sandwich,
#               marginaleffects and effectsize; the rows dplyr and datawizard;
#               the iteration purrr.
# Author:       Chris Moreh
# Last updated: 2026-10-26
# Sourced by:   index.qmd and working_script.R (source("R/spec_tools.R"))
##############################################################################

# ============================================================================
# CONFIGURATION – the class chart and the course site
# ============================================================================
# The results Form that submit_exploration() and report_result() pre-fill: its
# ID and the entry codes of its seven fields. They belong to the Form that the
# housing-audit case shares with the EU-frames course; a Form of its own
# replaces them here and nowhere else. The word in .case_word follows the tag
# in every label, so that the chart of this case reads only its own rows.
.form_id <- "1FAIpQLSezoAEOnZUfP4pkfN28_XtEBwSyc2RLsXB-h8RPSegF7_t76A"
.form_entry <- c(spec = "entry.832496914", b = "entry.1656311800", se = "entry.1337458262",
                 t = "entry.1940779437", df = "entry.1682711955", n = "entry.1586392724",
                 r = "entry.1660273001")
.case_word <- "housing"
.course_url <- "https://codemoreh.github.io/ar4ds-housing"
# ============================================================================


# ---- The estimator -------------------------------------------------------------
# A verbatim copy of R/housing/_tools.R in the course repository, which builds
# the curve; the browser lab of the course site carries the same copy.

# The same code runs in the downloadable workspace and in webR on the browser
# lab, so all three give the same numbers. The standard errors and the average
# marginal effect come from packages: parameters with sandwich for the HC2
# errors of the linear model, marginaleffects for the average marginal effect
# of the logit. R/housing/check_parity.R in the course repository checks both
# against estimatr and margins. The rows are chosen with dplyr, because
# datawizard evaluates its conditions in a fresh environment and so cannot see
# the arguments of a function.

# The options of the curve, in menu order. Anything else is refused by
# check_spec() with the reason recorded in data/menu_options.csv.
SPEC_AXES <- list(
  comparison = c("white", "nonhispanic"),
  population = c("replies", "all"),
  uncoded    = c("drop", "not_named"),
  model      = c("lpm", "logit"),
  adjust     = c("none", "email", "place", "place_ethnic")
)

# Covariates of each adjustment set; all are recorded before the emails went out.
ADJUST_TERMS <- list(
  none         = character(0),
  email        = "hard_email",
  place        = c("hard_email", "pop_third", "poverty_third"),
  place_ethnic = c("hard_email", "pop_third", "poverty_third", "black_third", "hispanic_third")
)

# The analysed rows and the outcome of one specification. Bounced emails never
# reached an official and are outside the experiment under every option.
spec_frame <- function(audit, comparison = "white", population = "replies", uncoded = "drop") {
  audit |>
    dplyr::filter(!is.na(reply),
                  .env$comparison == "nonhispanic" | group %in% c("white", "hispanic"),
                  .env$population == "all" | reply == 1) |>
    dplyr::mutate(
      hisp = as.integer(group == "hispanic"),
      y = dplyr::case_when(reply == 0 ~ 0,
                           is.na(named) & .env$uncoded == "not_named" ~ 0,
                           .default = named)
    ) |>
    dplyr::filter(!is.na(y))
}

# The conversion rules of Multi100 (standard_correlation_coefficient.R in
# github.com/marton-balazs-kovacs/multi100): t with its df, which is the rule of
# effectsize::t_to_r(); z with the sample size standing in for the missing df;
# a chi-square read as the square of a z, so it carries no sign.
r_multi100 <- function(stat, stat_type, df, n) {
  dplyr::case_when(
    stat_type == "t" ~ effectsize::t_to_r(stat, df, ci = NULL)$r,
    stat_type == "z" ~ tanh(abs(stat) * sqrt(1 / (n - 3))) * sign(stat),
    stat_type == "chi2" ~ tanh(sqrt(abs(stat)) * sqrt(1 / (n - 3)))
  )
}

check_spec <- function(comparison, population, uncoded, model, adjust) {
  chosen <- list(comparison = comparison, population = population, uncoded = uncoded,
                 model = model, adjust = adjust)
  bad <- names(chosen)[!purrr::map2_lgl(chosen, SPEC_AXES[names(chosen)], \(v, ok) v %in% ok)]
  if (length(bad) > 0) {
    stop("Not on the curve: ", paste0(bad, " = '", unlist(chosen[bad]), "'", collapse = ", "),
         ". The options are listed in data/menu_options.csv.", call. = FALSE)
  }
  invisible(TRUE)
}

# One specification: estimate in percentage points (negative = Hispanic names
# greeted by name less often, the direction of the claim), its SE and 95%
# interval, the test of the model that the specification fits, and the partial
# correlation by the Multi100 rule.
fit_spec <- function(audit, comparison = "white", population = "replies", uncoded = "drop",
                     model = "lpm", adjust = "none") {
  check_spec(comparison, population, uncoded, model, adjust)
  terms <- ADJUST_TERMS[[adjust]]
  # only the model columns, and only the emails with every covariate;
  # marginaleffects refuses a data column called `group`
  frame <- spec_frame(audit, comparison, population, uncoded) |>
    dplyr::select("y", "hisp", dplyr::all_of(terms)) |>
    stats::na.omit()
  form <- stats::reformulate(c("hisp", terms), response = "y")

  if (model == "lpm") {
    fit <- stats::lm(form, data = frame)
    # HC2 errors (MacKinnon and White 1985) from sandwich::vcovHC() (Zeileis
    # 2004, Journal of Statistical Software), with the t test on the residual df
    coefs <- parameters::model_parameters(fit, vcov = "HC2")
    row <- datawizard::data_filter(coefs, Parameter == "hisp")
    test <- list(coef = row$Coefficient, coef_se = row$SE, stat_type = "t", stat = row$t,
                 df = row$df_error, p = row$p)
    est <- list(b = row$Coefficient, se = row$SE, low = row$CI_low, high = row$CI_high)
  } else {
    fit <- stats::glm(form, family = stats::binomial(), data = frame)
    coefs <- parameters::model_parameters(fit, ci_method = "wald")
    row <- datawizard::data_filter(coefs, Parameter == "hisp")
    test <- list(coef = row$Coefficient, coef_se = row$SE, stat_type = "z", stat = row$z,
                 df = NA_real_, p = row$p)
    # The average marginal effect: the mean over the analysed emails of the
    # predicted probability with a Hispanic name minus that with a comparison
    # name, with delta-method errors (marginaleffects; Arel-Bundock, Greifer and
    # Heiss 2024, Journal of Statistical Software)
    ame <- marginaleffects::avg_comparisons(fit, variables = list(hisp = 0:1))
    est <- list(b = ame$estimate, se = ame$std.error, low = ame$conf.low, high = ame$conf.high)
  }

  tibble::tibble(
    comparison = comparison, population = population, uncoded = uncoded,
    model = model, adjust = adjust,
    b_pp = 100 * est$b, se_pp = 100 * est$se,
    coef = test$coef, coef_se = test$coef_se,
    stat_type = test$stat_type, stat = test$stat, df = test$df, p = test$p,
    r = r_multi100(test$stat, test$stat_type, test$df, nrow(frame)),
    n = nrow(frame), n_hisp = sum(frame$hisp == 1), n_comp = sum(frame$hisp == 0),
    rate_hisp = 100 * mean(frame$y[frame$hisp == 1]),
    rate_comp = 100 * mean(frame$y[frame$hisp == 0]),
    ci_low = 100 * est$low, ci_high = 100 * est$high
  )
}

# The free-text label that carries a specification to the class chart.
spec_line <- function(comparison, population, uncoded, model, adjust) {
  sprintf("comparison=%s population=%s uncoded=%s model=%s adjust=%s",
          comparison, population, uncoded, model, adjust)
}


# ---- The menu --------------------------------------------------------------------
# The eleven decisions in the order of the menu, each with the options that the
# curve keeps. The five decisions of SPEC_AXES keep two or more options, which
# multiply to the 64 specifications; on the other six the curve keeps one.
# Every other option is a row of data/menu_options.csv, whose reason the
# helpers print when it is asked for.
.menu <- list(
  # Level 1 – Estimands
  outcome    = "named",
  comparison = SPEC_AXES$comparison,
  population = SPEC_AXES$population,
  names      = "both",
  officials  = "any",
  # Level 2 – Measurement
  uncoded    = SPEC_AXES$uncoded,
  bounced    = "exclude",
  # Level 3 – Estimation
  model      = SPEC_AXES$model,
  adjust     = SPEC_AXES$adjust,
  inference  = "model",
  scale      = "pp"
)
.level_titles <- c(estimand    = "Level 1 – Estimands",
                   measurement = "Level 2 – Measurement",
                   estimation  = "Level 3 – Estimation")


# ---- The shipped files -----------------------------------------------------------
# Each file is read once and cached. The base reader keeps this code identical,
# line for line, with the copy in the browser lab. An empty cell must read as
# NA, as readr reads it: the 14 authorities without community thirds would
# otherwise enter the adjusted models as a fourth level "".
.cache <- new.env(parent = emptyenv())
.read_once <- function(name, path) {
  if (is.null(.cache[[name]])) {
    if (!file.exists(path))
      stop(sprintf("%s is missing – the workspace ships it under data/. Run from the workspace root folder.",
                   path), call. = FALSE)
    assign(name, utils::read.csv(path, stringsAsFactors = FALSE, encoding = "UTF-8", # r-style: keep – the same reader as the browser lab
                                 na.strings = c("", "NA")),
           envir = .cache)
  }
  .cache[[name]]
}
.audit   <- function() .read_once("audit", "data/housing_audit.csv")
.curve   <- function() .read_once("curve", "data/spec_curve.csv")
.options <- function() .read_once("options", "data/menu_options.csv")


# ---- Pages of the course site ----------------------------------------------------
.pages <- c(
  "cases/housing/index.qmd"       = "Case study",
  "cases/housing/menu.qmd"        = "Specification menu",
  "cases/housing/map.qmd"         = "Decision map",
  "cases/housing/multiverse.qmd"  = "Multiverse",
  "companion/experiments.qmd"     = "Audit experiments",
  "companion/binary-outcomes.qmd" = "Binary outcomes",
  "companion/dags.qmd"            = "Causal graphs and conditioning",
  "companion/multiverse.qmd"      = "The multiverse and its critics")
.page_ref <- function(path) {
  title <- if (path %in% names(.pages)) .pages[[path]] else path
  sprintf("%s, %s/%s", title, .course_url, sub("\\.qmd$", ".html", path))
}
.or_list <- function(x) {
  q <- paste0("\"", x, "\"")
  if (length(q) == 1) q else paste(paste(q[-length(q)], collapse = ", "), "or", q[length(q)])
}


# ---- Validation ------------------------------------------------------------------
# Two entry points into the same rules. .validate() takes a named list, which
# is how try_spec() supplies its arguments; .check_choices() reads the eleven
# my_* choices of the preregistration block. An option that is not on the
# curve stops with the reason from menu_options.csv, the page of the course
# site that teaches it, and the options that stay on the curve.
.on_menu <- function(axis, v) is.character(v) && length(v) == 1 && !is.na(v) && v %in% .menu[[axis]]

.refuse <- function(axis, v, as_args) {
  shown <- if (as_args) axis else paste0("my_", axis)
  keep  <- .menu[[axis]]
  map   <- paste0("  Every decision and its options: ", .page_ref("cases/housing/map.qmd"))
  if (!is.character(v) || length(v) != 1 || is.na(v))
    stop(sprintf("%s needs one option in quotes, for example %s = \"%s\".", shown, shown, keep[1]),
         call. = FALSE)
  opts <- .options()
  row  <- dplyr::filter(opts, .data$axis == .env$axis, .data$option == .env$v)
  off  <- dplyr::filter(opts, .data$axis == .env$axis, !.data$on_curve)$option
  msg <- if (nrow(row) == 1) c(
    sprintf("%s = \"%s\" (%s) is not on the curve of %d specifications, so it has no result here.",
            shown, v, row$label, nrow(.curve())),
    paste0("  Why: ", row$reason),
    paste0("  Where it is taught: ", .page_ref(row$taught_on)),
    map,
    sprintf("  To stay on the curve, choose %s = %s.", shown, .or_list(keep))
  ) else c(
    sprintf("%s = \"%s\" is not an option on the menu.", shown, v),
    sprintf("  On the curve: %s.", paste(keep, collapse = " | ")),
    if (length(off) > 0)
      sprintf("  Off the curve, refused with the reason why: %s.", paste(off, collapse = " | ")),
    map
  )
  stop(paste(msg, collapse = "\n"), call. = FALSE)
}

.validate <- function(ch, as_args = FALSE) {
  bad <- purrr::discard(names(.menu), \(a) .on_menu(a, ch[[a]]))
  if (length(bad) > 0) .refuse(bad[1], ch[[bad[1]]], as_args)
  ch[names(.menu)]
}

# The choices are looked up from the frame of this function outwards, which
# reaches the session in which the preregistration block was run.
.check_choices <- function() {
  need <- paste0("my_", names(.menu))
  ch <- mget(need, envir = environment(), inherits = TRUE, ifnotfound = list(NULL))
  missing <- need[purrr::map_lgl(ch, is.null)]
  if (length(missing) > 0)
    stop("Not declared yet: ", paste(missing, collapse = ", "),
         ". Fill in every choice in the preregistration block and run it first.", call. = FALSE)
  .validate(stats::setNames(ch, names(.menu)))
}


# ---- The live fit ----------------------------------------------------------------
# fit_spec() on the five decisions that vary on the curve, with the 95%
# interval of the estimate that it returns (a t interval from parameters for
# the linear model, a normal interval from marginaleffects for the average
# marginal effect of the logit) and the place of the result among the 64. The
# fit is checked against its row of data/spec_curve.csv; a difference means
# that a file in data/ has been edited.
.result <- function(ch) {
  fit <- fit_spec(.audit(), ch$comparison, ch$population, ch$uncoded, ch$model, ch$adjust) |>
    as.list()
  curve <- .curve()
  stored <- dplyr::filter(curve, .data$comparison == ch$comparison, .data$population == ch$population,
                          .data$uncoded == ch$uncoded, .data$model == ch$model,
                          .data$adjust == ch$adjust)
  if (nrow(stored) != 1) {
    warning("This specification has no row in data/spec_curve.csv; restore the file from the course repository.",
            call. = FALSE)
  } else if (abs(fit$b_pp - stored$b_pp) > 1e-6 || abs(fit$stat - stored$stat) > 1e-6) {
    warning(sprintf("The live fit (%.4f points, %s = %.4f) differs from the curve shipped with the workspace (%.4f points, %s = %.4f). A file in data/ may have been edited; restore it from the course repository.",
                    fit$b_pp, fit$stat_type, fit$stat, stored$b_pp, fit$stat_type, stored$stat),
            call. = FALSE)
  }
  c(fit, list(further = sum(curve$b_pp < fit$b_pp - 1e-9), n_curve = nrow(curve)))
}


# ---- The printout ----------------------------------------------------------------
.comparison_label <- function(comparison)
  c(white = "white names", nonhispanic = "white and Black names")[[comparison]]

.fmt_p <- function(p) sprintf("= %s", format(signif(p, 2), scientific = FALSE))

.class_line <- function(res) {
  below <- res$b_pp < 0
  sig   <- res$p < 0.05
  if (below && sig) "below zero and significant at 5%, in the direction of the claim"
  else if (below) "below zero, but not significant at 5%"
  else if (sig) "above zero and significant at 5%, against the direction of the claim"
  else "above zero and not significant at 5%"
}

.print_result <- function(ch, res, lead = NULL) {
  unit <- if (ch$population == "all") "delivered emails" else "replies"
  test <- if (res$stat_type == "t") c(
    sprintf("  Test: t = %.2f on %d df, p %s (linear probability model, HC2 standard errors)",
            res$stat, round(res$df), .fmt_p(res$p))
  ) else c(
    sprintf("  Test: z = %.2f, p %s (logistic regression; the difference is its average marginal effect)",
            res$stat, .fmt_p(res$p)),
    sprintf("        logit coefficient %.3f, standard error %.3f", res$coef, res$coef_se)
  )
  writeLines(c(
    lead,
    paste0("  ", spec_line(ch$comparison, ch$population, ch$uncoded, ch$model, ch$adjust)),
    sprintf("  Greeted by name: Hispanic names %.1f%% of %d %s, %s %.1f%% of %d",
            res$rate_hisp, res$n_hisp, unit, .comparison_label(ch$comparison), res$rate_comp,
            res$n_comp),
    sprintf("  Difference: %.2f percentage points, 95%% interval %.2f to %.2f",
            res$b_pp, res$ci_low, res$ci_high),
    test,
    sprintf("  n = %d %s, partial r = %.3f (the conversion rule of Multi100)", res$n, unit, res$r),
    paste0("  Verdict: ", .class_line(res)),
    sprintf("  On the curve: %d of the %d specifications have an estimate further below zero",
            res$further, res$n_curve)))
  invisible(res)
}


# ---- Task 4: the exploratory helpers -----------------------------------------------
.tried <- new.env(parent = emptyenv())
assign("log", NULL, envir = .tried)
assign("last", NULL, envir = .tried)

# The first five arguments are the decisions on which the curve keeps more
# than one option; the other six are fixed on the curve, and asking for any
# other option of theirs prints the reason why it is not on the curve.
try_spec <- function(comparison = "white", population = "replies", uncoded = "drop",
                     model = "lpm", adjust = "none", outcome = "named", names = "both",
                     officials = "any", bounced = "exclude", inference = "model", scale = "pp") {
  ch <- .validate(list(outcome = outcome, comparison = comparison, population = population,
                       names = names, officials = officials, uncoded = uncoded,
                       bounced = bounced, model = model, adjust = adjust,
                       inference = inference, scale = scale), as_args = TRUE)
  res <- .result(ch)
  .print_result(ch, res, lead = "")
  row <- data.frame(ch, b_pp = res$b_pp, ci_low = res$ci_low, ci_high = res$ci_high,  # r-style: keep – data.frame() spreads the list of choices into columns
                    stat_type = res$stat_type, stat = res$stat, p = res$p, n = res$n,
                    stringsAsFactors = FALSE)
  assign("log", dplyr::bind_rows(.tried$log, row), envir = .tried)
  assign("last", list(ch = ch, res = res), envir = .tried)
  invisible(row)
}

# The running log of everything try_spec() has fitted. Only the decisions that
# varied are shown; the others are those of the reference specification.
my_experiments <- function() {
  d <- .tried$log
  if (is.null(d)) {
    writeLines("Nothing tried yet – call try_spec() at least once.")
    return(invisible(NULL))
  }
  varied <- purrr::keep(names(.menu), \(a) dplyr::n_distinct(d[[a]]) > 1)
  show <- d |>
    dplyr::transmute(dplyr::across(dplyr::all_of(varied)),
                     estimate = round(.data$b_pp, 2),
                     interval = sprintf("%.1f to %.1f", .data$ci_low, .data$ci_high),
                     test = sprintf("%s = %.2f", .data$stat_type, .data$stat),
                     p = signif(.data$p, 2),
                     n = .data$n)
  writeLines(sprintf("Specifications you have tried (%d), estimates in percentage points:\n", nrow(d)))
  # wide enough for all five varied decisions on one line
  old_width <- options(width = max(getOption("width"), 120))
  on.exit(options(old_width))
  print(show, row.names = FALSE)
  writeLines(sprintf("\nEstimates from %.2f to %.2f points  |  below zero and significant at 5%%: %d of %d",
                     min(d$b_pp), max(d$b_pp), sum(d$b_pp < 0 & d$p < 0.05), nrow(d)))
  invisible(show)
}

submit_exploration <- function(nickname = NULL) {
  if (is.null(.tried$last))
    stop("Nothing to submit – call try_spec() first, ending with the specification you want on the chart.",
         call. = FALSE)
  .submit(.tried$last$ch, .tried$last$res, "explore",
          "Your exploratory submission (the last specification you tried):", nickname)
}


# ---- Task 5: the declared helpers --------------------------------------------------
# prereg() prints the block and returns it, so that run_spec() can check that
# the block has not changed since.
prereg <- function() {
  ch <- .check_choices()
  rows <- .options() |>
    dplyr::filter(paste(.data$axis, .data$option) %in% paste(names(ch), unlist(ch))) |>
    dplyr::arrange(match(.data$axis, names(.menu))) |>
    dplyr::mutate(line = sprintf("    %-31s : %-12s (%s)", .data$decision, .data$option, .data$label))
  block <- purrr::imap(.level_titles, \(title, lv) c(paste0("  ", title), rows$line[rows$level == lv])) |>
    unlist(use.names = FALSE)
  ph <- stats::setNames(rows$phrase, rows$axis)
  statement <- c(
    sprintf("%s%s, %s, %s, the difference in the share that drew %s between Hispanic names and %s (%s, %s).",
            toupper(substr(ph[["population"]], 1, 1)), substring(ph[["population"]], 2),
            ph[["names"]], ph[["officials"]], ph[["outcome"]], ph[["comparison"]],
            ph[["uncoded"]], ph[["bounced"]]),
    sprintf("Estimated with %s, %s, tested by %s and reported %s.",
            ph[["model"]], ph[["adjust"]], ph[["inference"]], ph[["scale"]]))
  writeLines(c(
    "DECLARED – your preregistered specification, fixed before it is fitted:",
    "",
    block,
    "",
    "  The estimand statement",
    strwrap(statement, width = 78, indent = 4, exdent = 4),
    "",
    "run_spec() and report_result() read these choices from here. Rendered into",
    "your report, this block is your preregistration, and it sits above the",
    "cells that fit and submit this specification."))
  invisible(structure(list(choices = ch), class = "housing_prereg"))
}

run_spec <- function(spec) {
  if (missing(spec) || !inherits(spec, "housing_prereg"))
    stop("Pass the object that prereg() returned: my_spec <- prereg(), then run_spec(my_spec).",
         call. = FALSE)
  if (!identical(spec$choices, .check_choices()))
    stop("The preregistration block has changed since prereg() returned this object. Run the whole block again, then run_spec(my_spec).",
         call. = FALSE)
  .print_result(spec$choices, .result(spec$choices), "Your preregistered specification, fitted live:")
}

report_result <- function(nickname = NULL) {
  ch <- .check_choices()
  .submit(ch, .result(ch), "declared",
          "Your declared submission (straight from your preregistration):", nickname)
}


# ---- Submission tags ---------------------------------------------------------------
# Both submissions of a participant carry one short tag inside the spec label,
# "explore: [amber-otter-42] housing …", so that the participant can find
# their own marks on the class chart. The tag rides in the free-text label
# because the form and its fields are shared infrastructure. It is drawn once
# and kept in .class-tag at the root of the workspace, so the explored and the
# declared submission share it across sessions; a nickname passed to either
# submission function replaces it. Base R throughout.
.tag_words <- list(
  adj  = c("amber", "azure", "bright", "calm", "coral", "crisp", "dusky", "early",
           "fair", "gentle", "golden", "hazel", "ivory", "jade", "keen", "lively",
           "lunar", "misty", "noble", "olive", "pale", "quiet", "rapid", "rosy",
           "russet", "silver", "snowy", "solar", "sunny", "swift", "velvet", "vivid"),
  noun = c("otter", "heron", "lynx", "badger", "finch", "hare", "ibex", "kestrel",
           "lark", "marten", "newt", "owl", "puffin", "quail", "raven", "seal",
           "stoat", "tern", "vole", "wren", "bison", "crane", "dove", "egret",
           "fox", "gecko", "koala", "lemur", "moose", "panda", "robin", "swan")
)
.tag_file <- ".class-tag"

# A fresh tag, drawn without touching the random-number stream of the session,
# so that a participant's set.seed() keeps reproducing the same draws.
.new_tag <- function() {
  had_seed <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (had_seed) old_seed <- get(".Random.seed", envir = globalenv())
  on.exit(if (had_seed) assign(".Random.seed", old_seed, envir = globalenv())
          else rm(".Random.seed", envir = globalenv()))
  set.seed(as.integer((as.numeric(Sys.time()) * 1000) %% 1e9) + Sys.getpid() %% 1e5)
  paste(sample(.tag_words$adj, 1), sample(.tag_words$noun, 1), sample(10:99, 1), sep = "-")
}

# A nickname reduced to lower-case ASCII letters, digits and single hyphens,
# at most 24 characters – the only form that the class chart parses.
.clean_tag <- function(x) {
  # iconv on Windows turns these into "?": the Romanian comma-below letters and the eszett
  x <- gsub("ß", "ss", chartr("ȘșȚț", "SsTt", trimws(as.character(x)[1])))
  ascii <- suppressWarnings(iconv(x, to = "ASCII//TRANSLIT"))
  if (!is.na(ascii)) x <- ascii
  x <- gsub("^-+|-+$", "", gsub("[^a-z0-9]+", "-", tolower(x)))
  x <- gsub("-+$", "", substr(x, 1, 24))
  if (is.na(x) || !nzchar(x))
    stop("A nickname needs at least one letter or digit, for example nickname = \"blue-heron\".",
         call. = FALSE)
  x
}

# The tag of this workspace: the nickname if one is given, otherwise the stored
# tag, otherwise a fresh one. Returns the tag and the one it replaced, if any.
.class_tag <- function(nickname = NULL) {
  stored <- if (file.exists(.tag_file))
    tryCatch(.clean_tag(readLines(.tag_file, warn = FALSE)[1]), error = function(e) NULL)
  tag <- if (!is.null(nickname)) .clean_tag(nickname) else if (!is.null(stored)) stored else .new_tag()
  if (!identical(tag, stored)) writeLines(tag, .tag_file)
  list(tag = tag, replaced = if (!is.null(stored) && !identical(tag, stored)) stored)
}

# One submission, used by both phases. The phase, the tag and the word of the
# case are prefixed to the free-text spec label, which carries the five
# decisions that vary on the curve. The estimate and its standard error are
# sent in percentage points, the statistic of the model in the t field (a z
# for a logit, whose df field stays empty), and r by the rule of Multi100.
.submit <- function(ch, res, phase, lead, nickname = NULL) {
  tg <- .class_tag(nickname)
  spec_label <- paste0(phase, ": [", tg$tag, "] ", .case_word, " ",
                       spec_line(ch$comparison, ch$population, ch$uncoded, ch$model, ch$adjust))
  value <- c(spec = spec_label, b = sprintf("%.5f", res$b_pp), se = sprintf("%.5f", res$se_pp),
             t = sprintf("%.3f", res$stat), df = if (is.na(res$df)) "" else as.character(round(res$df)),
             n = as.character(res$n), r = sprintf("%.3f", res$r))
  query <- purrr::imap_chr(.form_entry, \(entry, k)
    paste0(entry, "=", utils::URLencode(value[[k]], reserved = TRUE))) |>
    paste(collapse = "&")
  url <- sprintf("https://docs.google.com/forms/d/e/%s/viewform?usp=pp_url&%s", .form_id, query)

  writeLines(c(
    lead,
    "",
    paste("  spec:", spec_label),
    sprintf("  b = %s | se = %s | %s = %s | df = %s | n = %d | r = %s",
            value[["b"]], value[["se"]], res$stat_type, value[["t"]],
            if (nzchar(value[["df"]])) value[["df"]] else "(none, a logit)", res$n, value[["r"]]),
    "  (b and se in percentage points)",
    paste0("  Verdict: ", .class_line(res)),
    "",
    "Open the link below (or copy the URL) – the form opens with every field",
    "pre-filled; just press Send.",
    "",
    url,
    "",
    sprintf("Your marks on the class chart carry the tag %s%s.", tg$tag,
            if (!is.null(tg$replaced)) sprintf(" (it replaces %s)", tg$replaced) else ""),
    sprintf("Look for it on the Multiverse page, %s/cases/housing/multiverse.html.", .course_url),
    "Both of your submissions share it. To choose your own, pass nickname = \"...\"",
    "– pick a nickname rather than your name, because the chart is public."))
  invisible(list(spec = spec_label, tag = tg$tag, b = res$b_pp, se = res$se_pp, statistic = res$stat,
                 df = res$df, n = res$n, r = res$r, url = url))
}
