# Collect and clean four O*NET occupation profiles.
# Run from the post2 directory. Existing snapshots are reused by default.

career_sources <- data.frame(
  soc = c("15-2051.00", "15-2031.00", "13-2051.00", "15-2011.00"),
  occupation = c("Data Scientists", "Operations Research Analysts",
                 "Financial and Investment Analysts", "Actuaries"),
  stringsAsFactors = FALSE
)
career_sources$url <- paste0("https://www.onetonline.org/link/summary/",
                             career_sources$soc)
research_agent <- paste0("StudentCareerResearch/1.0 (contact: ",
                        "https://qianzhaoli949-afk.github.io/qianzhao-website/)")

# Pause between requests and stop on HTTP errors.
fetch_html <- function(url, dest) {
  Sys.sleep(4)
  page <- rvest::session(url, httr::user_agent(research_agent), httr::timeout(30))
  status <- httr::status_code(page$response)
  if (status != 200L) stop("Fetch stopped: HTTP ", status, " at ", url)
  writeBin(page$response$content, dest)
  invisible(format(Sys.time(), tz = "UTC", usetz = TRUE))
}

# Extract the value following a matching field label.
field <- function(doc, prefix) {
  labels <- rvest::html_elements(doc, "#WagesEmployment dt")
  text <- rvest::html_text2(labels)
  hit <- which(startsWith(text, prefix))
  if (length(hit) != 1L) stop("Expected one field: ", prefix)
  value <- rvest::html_element(labels[[hit]], xpath = "following-sibling::dd[1]")
  list(label = text[hit], value = rvest::html_text2(value))
}

match_one <- function(text, pattern) {
  hit <- regmatches(text, regexec(pattern, text, perl = TRUE))[[1]]
  if (length(hit) < 2L) stop("Could not parse: ", text)
  hit[2]
}

parse_career <- function(path, soc, url, retrieved_utc) {
  doc <- rvest::read_html(path)
  title <- rvest::html_text2(rvest::html_element(doc, "h1 .main"))
  pay <- field(doc, "Median wages")
  employment <- field(doc, "Employment (")
  growth <- field(doc, "Projected growth")
  openings <- field(doc, "Projected job openings")
  education <- rvest::html_text2(rvest::html_elements(doc, "#Education li"))
  # Keep NA when the education section is absent.
  degree <- NA_character_
  share <- NA_real_
  if (length(education)) {
    shares <- as.numeric(vapply(education, match_one, character(1),
                               pattern = "^([0-9]+)%"))
    top <- which.max(shares)
    degree <- trimws(sub("^[0-9]+%\\s*(responded:\\s*)?", "",
                        education[top], perl = TRUE))
    share <- shares[top]
  }
  period <- function(x) match_one(x, "\\(([0-9]{4}[-\u2013][0-9]{4})\\)")
  wage <- as.numeric(gsub(",", "", match_one(pay$value, "\\$([0-9,]+) annual")))
  jobs <- as.numeric(gsub(",", "", openings$value))
  if (!is.finite(wage) || !is.finite(jobs) || wage <= 0 || jobs <= 0)
    stop("Invalid wage/openings for ", soc)
  if (period(growth$label) != period(openings$label))
    stop("Mismatched projection periods for ", soc)
  data.frame(
    soc = soc, occupation = title, median_annual_pay_usd = wage,
    wage_year = as.integer(match_one(pay$label, "([0-9]{4})")),
    employment = as.numeric(gsub(",", "", match_one(employment$value, "^([0-9,]+)"))),
    employment_year = as.integer(match_one(employment$label, "([0-9]{4})")),
    growth_category = growth$value, projection_period = period(growth$label),
    annual_projected_openings = jobs,
    top_education_response = degree, education_response_pct = share,
    education_all_responses = if (length(education)) paste(education, collapse = " | ") else NA_character_,
    source_url = url, retrieved_utc = retrieved_utc,
    stringsAsFactors = FALSE
  )
}

build_careers <- function(data_dir = "data", refresh = FALSE) {
  if (!requireNamespace("rvest", quietly = TRUE) ||
      !requireNamespace("httr", quietly = TRUE))
    stop('Install packages first: install.packages(c("rvest", "httr"))')
  raw_dir <- file.path(data_dir, "raw")
  dir.create(raw_dir, recursive = TRUE, showWarnings = FALSE)
  manifest_file <- file.path(data_dir, "manifest.csv")
  manifest <- if (file.exists(manifest_file)) {
    read.csv(manifest_file, stringsAsFactors = FALSE)
  } else {
    data.frame(soc = character(), url = character(), retrieved_utc = character(),
               file = character(), md5 = character())
  }
  paths <- file.path(raw_dir, paste0(career_sources$soc, ".html"))
  needs_fetch <- refresh | !file.exists(paths)
  if (any(needs_fetch)) {
    robots_file <- file.path(data_dir, "robots.txt")
    fetch_html("https://www.onetonline.org/robots.txt", robots_file)
    rules <- readLines(robots_file, warn = FALSE)
    # Require a new policy review if robots.txt has changed.
    if (!file.exists("ROBOTS-REVIEWED.txt") ||
        !identical(rules, readLines("ROBOTS-REVIEWED.txt", warn = FALSE)))
      stop("robots.txt needs manual review before collecting; see DATA-NOTES.md.")
    for (i in which(needs_fetch)) {
      stamp <- fetch_html(career_sources$url[i], paths[i])
      manifest <- manifest[manifest$soc != career_sources$soc[i], , drop = FALSE]
      manifest <- rbind(manifest, data.frame(
        soc = career_sources$soc[i], url = career_sources$url[i],
        retrieved_utc = stamp, file = basename(paths[i]),
        md5 = unname(tools::md5sum(paths[i]))
      ))
      write.csv(manifest, manifest_file, row.names = FALSE)
    }
  }
  rows <- lapply(seq_len(nrow(career_sources)), function(i) {
    m <- manifest[manifest$soc == career_sources$soc[i], , drop = FALSE]
    if (nrow(m) != 1L || m$md5 != unname(tools::md5sum(paths[i])))
      stop("Missing or changed snapshot for ", career_sources$soc[i])
    parse_career(paths[i], career_sources$soc[i], career_sources$url[i], m$retrieved_utc)
  })
  result <- do.call(rbind, rows)
  if (!identical(result$occupation, career_sources$occupation))
    stop("Occupation labels have changed; review the source pages.")
  if (length(unique(result$wage_year)) != 1L ||
      length(unique(result$projection_period)) != 1L)
    stop("Sources mix reference years; review before comparing.")
  write.csv(result, file.path(data_dir, "careers.csv"), row.names = FALSE)
  result
}
