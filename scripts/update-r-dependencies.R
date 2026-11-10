# Run ONLY in the toolchain container; see maintenance/CONTAINER.md.
# Start from a clean library so unrelated packages cannot enter the lockfile.
stopifnot(Sys.getenv("RENV_CONFIG_AUTOLOADER_ENABLED") == "false")
options(repos = c(CRAN = "https://packagemanager.posit.co/cran/__linux__/noble/latest"))
packages <- c("renv", "knitr", "rmarkdown", "flextable", "magrittr", "reticulate")
available <- available.packages()
dependencies <- tools::package_dependencies(
  packages, db = available, which = c("Depends", "Imports", "LinkingTo"), recursive = TRUE
)
required <- intersect(unique(c(packages, unlist(dependencies))), rownames(available))
library <- tempfile("wcrp-r-library-")
dir.create(library)
.libPaths(c(library, .libPaths()))
install.packages(required, lib = library, Ncpus = 2L)
stopifnot(all(required %in% rownames(installed.packages(lib.loc = library))))
renv::snapshot(
  project = tempdir(),
  library = library,
  lockfile = "/project/renv.lock",
  packages = packages,
  prompt = FALSE
)

# Refresh the generated bootstrap without changing the owner's local R library.
bootstrap <- tempfile("wcrp-renv-bootstrap-")
dir.create(bootstrap)
renv::scaffold(project = bootstrap)
stopifnot(file.copy(
  file.path(bootstrap, "renv", "activate.R"),
  "/project/renv/activate.R",
  overwrite = TRUE
))
activation <- readLines("/project/renv/activate.R")
writeLines(sub("[ \t]+$", "", activation), "/project/renv/activate.R")
