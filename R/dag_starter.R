##############################################################################
# Title:        dag_starter.R – the causal graph of Task 2, to finish
# Purpose:      The graph behind the claim that emails signed with Hispanic
#               names were less likely to be greeted by name. The name can
#               affect whether the official replies, and only a reply can greet the
#               sender by name. A characteristic of the official that nobody
#               recorded, and the community of the housing authority, affect
#               both the reply and the greeting. One arrow is left for you to
#               switch on. Then ask dagitty which paths from the name to the
#               greeting stay open when the comparison is made among replies.
# Author:       Chris Moreh
# Last updated: 2026-10-26
# Sourced by:   index.qmd and working_script.R (Task 2)
##############################################################################

# Three terms on which the task depends:
#   confounder – a common cause of the name and the greeting. The names were
#                assigned by a random number generator, so nothing causes the
#                name and there is no confounder to adjust for.
#   mediator   – a variable on a path from the name to the greeting. The reply
#                is one: a name that discourages a reply also removes the
#                chance of a greeting.
#   collider   – a common effect of two variables. The reply is one of these
#                as well, because the name and the official both affect it.
#                Comparing replies only conditions on it, and conditioning on a
#                collider opens a path between its causes.

# Where each node sits in the figure: the name on the left, the greeting on
# the right, the reply above the line between them. dagitty counts y
# downwards, so the heights are stored with their signs reversed. A node that
# you add without a position here is drawn on a row below the graph.
.dag_xy <- list(name = c(0, 0), reply = c(1.5, 1.6), greeting = c(3, 0),
                community = c(2, 0.65), official = c(3, 1.6))

# A dagitty graph from arrows written "cause -> effect", one per string. The
# named arguments come last, so that switching off the last arrow with a #
# never leaves a comma dangling.
make_dag <- function(..., exposure = "name", outcome = "greeting", latent = "official") {
  arrows <- c(...)
  nodes <- unique(c(exposure, outcome, trimws(unlist(strsplit(arrows, "->|<-")))))
  declare <- purrr::map_chr(nodes, \(v) {
    tags <- c(if (v %in% exposure) "exposure",
              if (v %in% outcome) "outcome",
              if (v %in% latent) "latent",
              if (v %in% names(.dag_xy))
                sprintf("pos=\"%s,%s\"", .dag_xy[[v]][1], -.dag_xy[[v]][2]))
    if (length(tags) == 0) v else sprintf("%s [%s]", v, paste(tags, collapse = ","))
  })
  dagitty::dagitty(paste0("dag {\n", paste(c(declare, arrows), collapse = "\n"), "\n}"))
}

# ---- The graph -------------------------------------------------------------
dag <- make_dag(
  # The name can affect whether the official replies at all.
  "name -> reply",
  # Only a reply can greet the sender by name.
  "reply -> greeting",
  # Something about the official that nobody recorded – workload, habits of
  # courtesy, attitudes – affects both whether they reply and how they greet.
  "official -> reply",
  "official -> greeting",
  # The community of the housing authority – its size, poverty and ethnic
  # composition, which the public file holds in thirds – affects both as well.
  "community -> reply",
  "community -> greeting",

  # ----- TASK 2: the arrow that the claim is about -----
  # The claim is that the name changes the tone of a reply, beyond whether a
  # reply comes at all. Take the # off the next line if you believe it,
  # source this file again, and rerun the checks in the report.
  # "name -> greeting",

  exposure = "name", outcome = "greeting", latent = "official"
)

# ---- The figure ------------------------------------------------------------
# Colour marks the exposure and the outcome, and the official, whom nobody
# observed, is drawn pale. Each arrow stops near the edge of the box of its
# target, which is sized from the length of the name. Drawn with tinyplot
# (McDermott, Arel-Bundock and Zeileis; CRAN, doi:10.32614/CRAN.package.tinyplot).
plot_dag <- function(d = dag) {
  xy <- dagitty::coordinates(d)
  nodes <- tibble::tibble(name = names(xy$x), x = unname(xy$x), y = -unname(xy$y)) |>
    dplyr::mutate(
      unplaced = is.na(.data$x),
      x = dplyr::if_else(.data$unplaced, 1.2 * (cumsum(.data$unplaced) - 1), .data$x),
      y = dplyr::if_else(.data$unplaced, -0.9, .data$y),
      half_w = 0.06 + 0.032 * nchar(.data$name),
      role = factor(dplyr::case_when(.data$name %in% dagitty::exposures(d) ~ "exposure",
                                     .data$name %in% dagitty::outcomes(d) ~ "outcome",
                                     .data$name %in% dagitty::latents(d) ~ "unobserved",
                                     .default = "observed"),
                    levels = c("exposure", "outcome", "observed", "unobserved")))
  # how far along a unit vector (ux, uy) the edge of a box of half-width w lies
  to_edge <- \(ux, uy, w) pmin(w / pmax(abs(ux), 1e-9), 0.15 / pmax(abs(uy), 1e-9))
  tails <- dplyr::select(nodes, from = "name", x0 = "x", y0 = "y", w0 = "half_w")
  heads <- dplyr::select(nodes, to = "name", x1 = "x", y1 = "y", w1 = "half_w")
  arrows <- dagitty::edges(d) |>
    dplyr::transmute(from = as.character(.data$v), to = as.character(.data$w)) |>
    dplyr::inner_join(tails, by = "from") |>
    dplyr::inner_join(heads, by = "to") |>
    dplyr::mutate(len = sqrt((.data$x1 - .data$x0)^2 + (.data$y1 - .data$y0)^2),
                  ux = (.data$x1 - .data$x0) / .data$len,
                  uy = (.data$y1 - .data$y0) / .data$len,
                  s0 = to_edge(.data$ux, .data$uy, .data$w0),
                  s1 = to_edge(.data$ux, .data$uy, .data$w1) + 0.04,
                  x = .data$x0 + .data$s0 * .data$ux, y = .data$y0 + .data$s0 * .data$uy,
                  xend = .data$x1 - .data$s1 * .data$ux, yend = .data$y1 - .data$s1 * .data$uy)

  # the boxes, coloured by role; tinyplot has no type for arrows, so they go
  # on the same canvas through graphics::arrows(); then the names, white on
  # the coloured boxes and dark on the pale one
  tinyplot::tinyplot(xmin = nodes$x - 0.8 * nodes$half_w, xmax = nodes$x + 0.8 * nodes$half_w,
                     ymin = nodes$y - 0.1, ymax = nodes$y + 0.1, by = nodes$role, type = "rect",
                     palette = c("#1b6ca8", "#d1495b", "grey45", "grey88"), fill = "by",
                     legend = list("bottom!", title = NULL), axes = FALSE, frame.plot = FALSE,
                     xlab = NA, ylab = NA,
                     xlim = range(nodes$x) + c(-0.45, 0.45), ylim = range(nodes$y) + c(-0.3, 0.3),
                     grid = FALSE, theme = "minimal")
  graphics::arrows(arrows$x, arrows$y, arrows$xend, arrows$yend,
                   length = 0.1, angle = 20, col = "grey40", lwd = 1.5)
  tinyplot::tinyplot(x = nodes$x, y = nodes$y, by = nodes$role,
                     type = tinyplot::type_text(labels = nodes$name, font = 2),
                     palette = c("white", "white", "white", "grey25"), cex = 0.85, add = TRUE)
}
