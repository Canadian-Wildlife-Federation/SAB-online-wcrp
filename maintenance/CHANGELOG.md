# Migration change log

## 2026-10-03 — RStudio preview helpers

- Added `scripts/preview.R`: run `source("scripts/preview.R")` in the RStudio
  Console, or open the script and click Source. It checks Docker/Linux containers,
  builds when image inputs change, renders, validates local links, starts preview,
  waits for HTTP readiness, and opens the browser in an interactive R session.
- Added `scripts/stop-preview.R` to stop only this project's preview service.
- Shared implementation uses base R only, preserves the caller's working directory
  and workspace, and stores an ignored local build record. It stops preview during
  rendering and leaves it stopped if building, rendering, or validation fails.
- Changed `.Rprofile` so opening the project does not bootstrap/install host renv
  packages. Native R development remains opt-in with `WCRP_USE_LOCAL_RENV=true`.
- Updated README, content-editing guide, and maintenance instructions with setup,
  save/edit/re-preview steps, stop instructions, and troubleshooting. RStudio's
  built-in Render/Preview buttons remain unchanged and should not be used for
  the Docker workflow.
- Validation: first-use helper run passed end to end; a normal-R-startup `source()`
  run reused the existing image and passed all ten chapters and local-link checks.
  Stop helper and workspace/working-directory preservation passed. Automated tests
  also cover dependency/image changes, daemon/build/render/link/start failures,
  nested sourcing, `chdir=TRUE`, and paths containing spaces.
- RStudio GUI clicking and automatic browser launch were not exercised in this
  session; the same `source()` entry point was tested through Rscript. The HTTP
  preview is available at <http://localhost:8000>. No commit or push was performed.

## 2026-10-03 — container migration and dependency upgrade

### Decisions confirmed with the owner

- Preserve local render → commit/push `_book` → Netlify publication.
- Refresh live APIs every build after the broken PEI integration is repaired.
- Ignore broken PEI calls for now; do not change scientific figures or endpoints.
- Make incremental, documented changes and validate before accepting upgrades.

### Changes made

1. Assessed the Quarto/R/Python source, local data, legacy files, dependency locks,
   and publishing workflow. Findings are in `PROJECT-ASSESSMENT.md`.
2. Added `Dockerfile`, `compose.yaml`, and `.dockerignore`. The image installs
   R 4.6.1, Python 3.14.8, Quarto 1.10.18, uv 0.12.23, and renv 1.3.0. R and uv
   base images are pinned by digest; the Quarto download is checksum-verified.
3. Installed and locked 66 R packages, regenerated the renv activation helper, and
   installed 45 hash-locked Python packages. `DEPENDENCY-CHANGES.md` lists before
   and after versions. Python now includes the complete Jupyter execution stack.
4. Declared Linux libraries/fonts, including the new `fs` requirement `libuv1-dev`.
   The update script explicitly installs dependencies such as Matrix/lattice rather
   than inheriting unrecorded versions from the base image.
5. Set `R_LIBS` so ordinary R startup prioritizes the locked library. Checked both
   isolated startup and the normal startup used when rendering.
6. Configured temporary mounts for host R/Python library folders and Quarto cache.
   This resolved the initial render's slow filesystem discovery and prevents host
   environment/cache state from affecting a container render. Local folders remain
   intact. Explicit QMD render targets exclude non-book maintenance content.
7. Temporarily set `eval: false` on the two unused, broken PEI API chunks; added
   comments explaining how to restore them. Enabled uncached/unfrozen execution
   for future working API chunks. No scientific values or API endpoints changed.
8. Corrected the sidebar logo path. The prior book had ten broken logo references;
   the regenerated book includes the logo and passes all local-link checks.
9. Made Netlify's root base and `_book` publication directory explicit. Its command
   checks only that `_book/index.html` exists. Moved Python's lock under `docker/`
   so Netlify does not install a separate Python environment from a root requirements file.
10. Added reusable environment/link checks, content-editing instructions, dependency
    maintenance instructions, ignore rules, and LF rules for container inputs.
11. Regenerated all ten `_book` pages with the new renderer. New hashed CSS filenames
    and updated Quarto JavaScript are expected generated changes; stage additions
    and deletions together with `git add -A _book`.

### Validation completed

- Toolchain and final Docker image build: passed.
- Clean restore from the generated R lock: passed; 65 packages restored, plus the
  already installed locked renv bootstrap.
- Python hash-checked installation and dependency validation: all 45 packages passed.
- Quarto Jupyter and knitr engine rendering checks: passed.
- Exact runtime/R-package version checks and R/Python data conversion: passed.
- Project's flextable formatting function: passed under flextable 0.10.1.
- Full uncached book render: all ten documents passed, exit code 0.
- Local page, image, script, stylesheet, and anchor validation: all ten HTML pages passed.
- All nine rendered tables have the same content as the pre-upgrade book; all
  previous figure files have identical hashes. The sidebar logo is newly included.
- Compose and Netlify TOML configuration parsing: passed.
- Source diff whitespace check: passed. Quarto's generated HTML/JS contains upstream
  trailing whitespace; generated files were retained as produced by Quarto.
- Local HTTP preview: running at <http://localhost:8000> for owner review.

Tested renderer image ID:

```text
sha256:71349f1c25985f336f071efc83dbbf38fe71813f1f85a1d03b79da6e44bf9bce
```

Docker initially returned HTTP 500 / `no route to host`; the owner restarted its
background engine, after which builds succeeded. The installed Jupyter kernel emits
an informational TCP transport warning; the rendering service publishes no ports.
There were no render failures or unresolved-reference warnings in the final build.

### Remaining user steps / limits

1. Visually review <http://localhost:8000>, especially table widths, figures, sidebar,
   and mobile layout. No browser was connected to the automation session, so visual
   layout has not been signed off despite passing structural/content checks.
2. Review the source and dependency changes, then commit/push when ready. No commit,
   push, Netlify-account change, or live deployment has been performed.
3. Confirm the Netlify repository/production branch and check the first deployment.
   The repository configuration is prepared; account/deployment settings were not accessed.
4. Repair the PEI API integration separately before enabling live scientific updates.
   Manual PEI values, CSVs, and placeholders are still maintained as before.
5. Optional later work: retire unused notebooks/legacy helpers/tracked bytecode;
   share a tested image through a registry if identical image reuse across the team is desired.

Local validation logs and a copy of the original book are under the ignored
`.build-validation/` folder. Stop the preview with `docker compose down` when finished.
