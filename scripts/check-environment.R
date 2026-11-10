# Exercise the actual R/Python boundary, not just independent imports.
lock <- jsonlite::read_json("renv.lock")
stopifnot(getRversion() == package_version(lock$R$Version))
for (package in names(lock$Packages)) {
  if (packageVersion(package) != package_version(lock$Packages[[package]]$Version)) {
    stop(sprintf("%s: loaded %s, expected %s", package, packageVersion(package), lock$Packages[[package]]$Version))
  }
}
library(reticulate)
config <- py_config()
stopifnot(config$python == "/opt/venv/bin/python")
pandas <- import("pandas")
roundtrip <- pandas$DataFrame(data.frame(species = c("salmon", "eel"), km = c(1.5, 2.5)))
stopifnot(identical(roundtrip$species, c("salmon", "eel")))
stopifnot(isTRUE(all.equal(roundtrip$km, c(1.5, 2.5))))
library(flextable)
source("content/Rscripts/table_formatting.R")
table <- format_flextable(flextable(data.frame(Species = c("Salmon", "Eel"), Habitat = c(1.5, 2.5))))
stopifnot(inherits(table, "flextable"))
cat("R", as.character(getRversion()), "\n")
cat("Python", as.character(config$version), "\n")
cat("pandas", pandas$`__version__`, "\n")
cat("flextable", as.character(packageVersion("flextable")), "\n")
cat("R/Python data conversion and table formatting passed.\n")
