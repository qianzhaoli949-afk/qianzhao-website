# Keep projected net growth categories separate from gross annual openings.
analyze_careers <- function(careers) {
  allowed <- c("Faster than average (5% to 6%)", "Much faster than average (7% or higher)")
  stopifnot(nrow(careers) == 4, !anyDuplicated(careers$soc),
            all(careers$growth_category %in% allowed),
            all(is.finite(careers$employment)), all(careers$employment > 0),
            all(is.finite(careers$annual_projected_openings)),
            all(careers$annual_projected_openings >= 0),
            all(careers$employment_year == 2024),
            all(careers$projection_period == "2024-2034"))
  out <- careers[c("soc", "occupation", "growth_category", "employment",
                   "employment_year", "annual_projected_openings", "projection_period")]
  out$annual_openings_per_100_base_jobs <- 100 * out$annual_projected_openings / out$employment
  out$openings_rank <- rank(-out$annual_projected_openings, ties.method = "min")
  out$relative_openings_rank <- rank(-out$annual_openings_per_100_base_jobs, ties.method = "min")
  out
}
