# Content editing uses Docker, so opening RStudio should not install host packages.
# Native-R development is available explicitly through WCRP_USE_LOCAL_RENV=true.
if (identical(tolower(Sys.getenv("WCRP_USE_LOCAL_RENV")), "true")) {
  source("renv/activate.R")
}
