# Run from the repository root: Rscript --vanilla scripts/tests/test-preview-helper.R
# Exercise failure handling without stopping real containers or changing the book.
source("scripts/docker-helper.R")
root <- tempfile("wcrp helper test ")
dir.create(root)
dir.create(file.path(root, "docker"))
inputs <- c("Dockerfile", ".dockerignore", "compose.yaml", "renv.lock", "docker/requirements.lock.txt")
for (input in inputs) writeLines("fixture", file.path(root, input))
starting_directory <- getwd()
calls <- character()
opened <- FALSE
failure <- NULL
engine <- "linux"
image <- "sha256:fixture"
runner <- function(args, capture = FALSE) {
  call <- paste(args, collapse = " ")
  calls <<- c(calls, call)
  if (identical(call, failure)) return(list(status = 1L, output = "simulated error"))
  output <- if (args[1] == "info") engine else if (args[1] == "image") image else
    if (identical(args, c("compose", "config", "--images", "book"))) "renderer:test" else character()
  list(status = 0L, output = output)
}
preview <- function() wcrp_preview(root, command = runner, launch_browser = TRUE,
  browser = function(address) { opened <<- TRUE }, wait_ready = function(address) TRUE)
expect_failure <- function(command, text) {
  failure <<- command
  calls <<- character()
  opened <<- FALSE
  error <- tryCatch({ preview(); NULL }, error = identity)
  stopifnot(inherits(error, "error"), grepl(text, conditionMessage(error)), !opened,
            identical(getwd(), starting_directory))
  failure <<- NULL
}

preview()
stopifnot(opened, "compose build book" %in% calls, identical(getwd(), starting_directory))
calls <- character()
preview()
stopifnot(!"compose build book" %in% calls)
writeLines("changed lock", file.path(root, "renv.lock"))
calls <- character()
preview()
stopifnot("compose build book" %in% calls)
image <- "sha256:replaced-image"
calls <- character()
preview()
stopifnot("compose build book" %in% calls)

expect_failure("info --format {{.OSType}}", "Docker is not responding")
stopifnot(!"compose stop preview" %in% calls)
writeLines("changed again", file.path(root, "Dockerfile"))
expect_failure("compose build book", "Container build failed")
stopifnot(!"compose run --rm book" %in% calls)
preview() # accept the changed image inputs for subsequent failure cases
expect_failure("compose run --rm book", "Rendering failed")
stopifnot(!any(grepl("compose up", calls)), tail(calls, 1) == "compose stop preview")
expect_failure("compose run --rm book python scripts/check-render.py", "failed its link/asset checks")
stopifnot(!any(grepl("compose up", calls)))
expect_failure("compose up -d --no-build --pull never preview", "Could not start preview")

calls <- character()
wcrp_stop_preview(root, command = runner)
stopifnot(identical(calls, "compose stop preview"), identical(getwd(), starting_directory))

# Test the actual source wrappers from outside the project, including nested source
# and RStudio's source(chdir=TRUE), using a stub implementation instead of Docker.
dir.create(file.path(root, "scripts"))
for (name in c("preview.R", "stop-preview.R")) {
  stopifnot(file.copy(file.path("scripts", name), file.path(root, "scripts", name)))
}
writeLines(c(
  "wcrp_preview <- function(root) options(wcrp.test.root = root, wcrp.test.action = 'preview')",
  "wcrp_stop_preview <- function(root) options(wcrp.test.root = root, wcrp.test.action = 'stop')"
), file.path(root, "scripts", "docker-helper.R"))
writeLines("source('scripts/preview.R')", file.path(root, "outer.R"))
source(file.path(root, "outer.R"), chdir = TRUE)
stopifnot(identical(getOption("wcrp.test.root"), normalizePath(root, winslash = "/")),
          identical(getOption("wcrp.test.action"), "preview"), identical(getwd(), starting_directory))
source(file.path(root, "scripts", "stop-preview.R"), chdir = TRUE)
stopifnot(identical(getOption("wcrp.test.action"), "stop"), identical(getwd(), starting_directory))
options(wcrp.test.root = NULL, wcrp.test.action = NULL)
cat("PASS: build/cache changes, failure handling, stop, working-directory restoration, and source wrappers (nested, chdir, paths with spaces).\n")
