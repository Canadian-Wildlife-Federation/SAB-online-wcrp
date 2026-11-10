# In RStudio: source("scripts/preview.R"), or open this file and click Source.
local({
  sources <- Filter(Negate(is.null), lapply(sys.frames(), function(frame) frame$ofile))
  script <- if (length(sources)) sources[[length(sources)]] else NULL
  if (is.null(script)) {
    argument <- grep("^--file=", commandArgs(), value = TRUE)
    if (length(argument)) script <- sub("^--file=", "", argument[1])
  }
  if (is.null(script)) stop("Open scripts/preview.R and click Source, or source it from the project Console.")
  if (!file.exists(script) && file.exists(basename(script))) script <- basename(script)
  root <- dirname(dirname(normalizePath(script, winslash = "/", mustWork = TRUE)))
  sys.source(file.path(root, "scripts", "docker-helper.R"), envir = environment())
  wcrp_preview(root)
})
