# Base-R implementation shared by preview.R and stop-preview.R.
# Sourced into their local environments, not the user's global workspace.
wcrp_docker <- function(args, capture = FALSE) {
  docker <- unname(Sys.which("docker"))
  if (!nzchar(docker)) {
    stop("Docker was not found. Install Docker Desktop, start it, then restart RStudio.", call. = FALSE)
  }
  args <- vapply(args, shQuote, character(1))
  if (capture) {
    output <- suppressWarnings(system2(docker, args, stdout = TRUE, stderr = TRUE))
    status <- attr(output, "status")
    if (is.null(status)) status <- 0L
  } else {
    status <- system2(docker, args)
    output <- character()
  }
  list(status = status, output = output)
}

wcrp_checked <- function(result, message) {
  if (result$status != 0L) {
    stop(paste(c(message, result$output), collapse = "\n"), call. = FALSE)
  }
  result$output
}

wcrp_ready <- function(address) {
  old <- options(timeout = 2)
  on.exit(options(old))
  for (attempt in seq_len(20L)) {
    ready <- suppressWarnings(tryCatch({
      connection <- url(address, open = "rb")
      tryCatch(length(readBin(connection, "raw", n = 1L)) > 0L,
               finally = close(connection))
    }, error = function(e) FALSE))
    if (ready) return(invisible(TRUE))
    Sys.sleep(0.25)
  }
  stop("Preview did not respond at ", address,
       ". Check Docker Desktop and whether port 8000 is available.", call. = FALSE)
}

wcrp_preview <- function(root, command = wcrp_docker,
                         launch_browser = interactive(), browser = utils::browseURL,
                         wait_ready = wcrp_ready) {
  previous <- setwd(root)
  on.exit(setwd(previous))
  inputs <- c("Dockerfile", ".dockerignore", "compose.yaml", "renv.lock",
              "docker/requirements.lock.txt")
  if (!all(file.exists(inputs))) {
    stop("Required container files are missing. Download or clone the complete repository.", call. = FALSE)
  }
  engine <- wcrp_checked(command(c("info", "--format", "{{.OSType}}"), TRUE),
                         "Docker is not responding. Start Docker Desktop and wait for Engine running, then retry.")
  if (!"linux" %in% trimws(engine)) {
    stop("Docker must use Linux containers. Switch Docker Desktop to Linux containers and retry.", call. = FALSE)
  }
  wcrp_checked(command(c("compose", "version", "--short"), TRUE),
               "Docker Compose is unavailable. Install/update Docker Desktop and restart RStudio.")
  images <- wcrp_checked(command(c("compose", "config", "--images", "book"), TRUE),
                         "Unable to read compose.yaml.")
  images <- unique(trimws(images[nzchar(trimws(images))]))
  if (length(images) != 1L) stop("Expected one renderer image in compose.yaml.", call. = FALSE)
  inspect <- function() command(c("image", "inspect", images, "--format", "{{.Id}}"), TRUE)
  image <- inspect()
  hashes <- tools::md5sum(inputs)
  stamp_path <- file.path(".build-validation", "preview-image.rds")
  stamp <- if (file.exists(stamp_path)) {
    tryCatch(readRDS(stamp_path), error = function(e) NULL)
  } else NULL
  rebuild <- image$status != 0L || !identical(stamp$inputs, hashes) ||
    !identical(stamp$image, image$output)

  # Do not continue serving old or partially rewritten HTML during a build.
  wcrp_checked(command(c("compose", "stop", "preview")), "Could not stop the existing preview.")
  completed <- FALSE
  on.exit({
    if (!completed) try(command(c("compose", "stop", "preview")), silent = TRUE)
  }, add = TRUE)
  if (rebuild) {
    message("Preparing the Docker environment. The first build can take several minutes...")
    wcrp_checked(command(c("compose", "build", "book")),
                 "Container build failed. Fix the Docker error above, then run this helper again.")
    image <- inspect()
    wcrp_checked(image, "The renderer image was not available after building.")
    dir.create(dirname(stamp_path), showWarnings = FALSE)
    saveRDS(list(inputs = hashes, image = image$output), stamp_path)
  } else {
    message("Using the existing Docker environment.")
  }
  message("Rendering the book...")
  wcrp_checked(command(c("compose", "run", "--rm", "book")),
               "Rendering failed. Preview remains stopped. Fix the error above and retry; do not publish this _book output.")
  wcrp_checked(command(c("compose", "run", "--rm", "book", "python", "scripts/check-render.py")),
               "The rendered book failed its link/asset checks. Preview remains stopped; fix the reported errors and retry.")
  wcrp_checked(command(c("compose", "up", "-d", "--no-build", "--pull", "never", "preview")),
               "Could not start preview. Check the Docker error above; port 8000 may already be in use.")
  address <- "http://localhost:8000"
  wait_ready(address)
  completed <- TRUE
  message("Preview ready: ", address,
          "\nAfter saving edits, run source('scripts/preview.R') again.",
          "\nTo stop: source('scripts/stop-preview.R')")
  if (launch_browser) {
    tryCatch(browser(address), error = function(e) {
      message("The browser could not be opened automatically. Open ", address, " manually.")
    })
  }
  invisible(address)
}

wcrp_stop_preview <- function(root, command = wcrp_docker) {
  previous <- setwd(root)
  on.exit(setwd(previous))
  wcrp_checked(command(c("compose", "stop", "preview")),
               "Could not stop preview. Check that Docker Desktop is running.")
  message("Preview stopped. Your content and rendered files are unchanged.")
  invisible(NULL)
}
