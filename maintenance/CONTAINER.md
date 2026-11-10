# Container and dependency maintenance

## Design

The image contains R, Python, Quarto, system libraries/fonts, and locked packages.
Compose mounts this checkout at `/project`; rendered `_book` stays on your computer.
R packages live at `/opt/R/library`, Python at `/opt/venv`, outside the mount. The
host `renv/library` cannot replace the container library. The renv project autoloader
is disabled inside Docker. Both `RETICULATE_PYTHON` and `QUARTO_PYTHON` select the
same interpreter. All workstations use Linux/amd64.

`R_LIBS` explicitly prioritizes the locked R library ahead of Rocker's bundled
packages. Temporary container mounts hide the host's `renv/library`, `renv/python`,
`renv/staging`, and `.quarto` folders. Each render gets a fresh Quarto cache; host
libraries/caches remain intact. Explicit project render targets limit discovery
to the book's QMD sources.

The preview service serves existing HTML on localhost:8000 without rerendering.
The `.dockerignore` allowlist excludes source, local environments, Git history,
data, and credentials from the image. Source is mounted at runtime. No Netlify
token is needed for the existing Git-based publication workflow.

## Locally validated toolchain

| Component | Version |
| --- | --- |
| R / Rocker | 4.6.1; base image pinned by digest |
| Python | 3.14.8 |
| Quarto | 1.10.18; release checksum checked |
| uv | 0.12.23; image pinned by digest |
| renv bootstrap | 1.3.0 |

This environment passed the image build, both execution-engine checks, exact R
package-version checks, R/Python conversion, all ten chapters, and local-link
validation. See `CHANGELOG.md` for limits and the tested image ID. All 66 R packages
are recorded in `renv.lock`; all 45 Python packages are pinned with hashes in
`docker/requirements.lock.txt`. See [the version comparison](DEPENDENCY-CHANGES.md).

Ubuntu system packages come from maintained repositories at image-build time; those
packages may change upstream. Rebuilding is not guaranteed to
produce identical image bytes. Keep a tested image and record its image ID. A future
shared registry with immutable image digests would allow exact image reuse by the team.

## Deliberate dependency upgrade / initial migration

### RStudio helper maintenance

`scripts/preview.R` and `scripts/stop-preview.R` load the base-R implementation in
`scripts/docker-helper.R` into a temporary environment. They leave the user's
working directory and global workspace unchanged. The preview helper compares
MD5 fingerprints of `Dockerfile`, `.dockerignore`, `compose.yaml`, `renv.lock`, and
`docker/requirements.lock.txt`, plus the current renderer image ID. Its local build
record is `.build-validation/preview-image.rds` (ignored by Git). A missing or
changed record/image triggers a build; source-content changes only trigger rendering.
These fingerprints detect changes; package download verification still uses the
checksums/hashes configured by the Docker build.

The helper stops only the project's preview before rebuilding/rendering. It restarts
the server and opens a browser only after render and link checks pass and the HTTP
server responds. An error leaves preview stopped. The background server must be
stopped explicitly using `source("scripts/stop-preview.R")` or Docker Compose.

`.Rprofile` no longer activates local renv by default. Maintainers who explicitly
need a native R session can set `WCRP_USE_LOCAL_RENV=true` in their ignored
`.Renviron` and restart R. They then need the matching local R version and packages;
this is separate from the supported Docker content-editing workflow.

Run helper regression checks without Docker using:

```powershell
Rscript --vanilla scripts/tests/test-preview-helper.R
```

### Updating dependencies

Use a maintenance branch and clean worktree. Ordinary content editors do not need
these commands:

```powershell
docker build --platform linux/amd64 --target toolchain -t sab-wcrp-toolchain:local .
docker run --rm --platform linux/amd64 --mount "type=bind,source=$($PWD.Path),target=/project" sab-wcrp-toolchain:local Rscript --vanilla scripts/update-r-dependencies.R
docker run --rm --platform linux/amd64 --mount "type=bind,source=$($PWD.Path),target=/project" sab-wcrp-toolchain:local uv pip compile requirements.in --python /opt/venv/bin/python --upgrade --generate-hashes --output-file docker/requirements.lock.txt
docker compose build book
docker compose run --rm book quarto check
docker compose run --rm book Rscript scripts/check-environment.R
docker compose run --rm book uv pip check --python /opt/venv/bin/python
docker compose run --rm book
docker compose run --rm book python scripts/check-render.py
docker compose up preview
```

The R script installs current direct/required dependencies in a temporary library,
including recommended packages such as Matrix and lattice, then snapshots installed
packages and regenerates `renv/activate.R`. It can take several minutes to compile
native packages. The Python lock pins all transitive versions and
hashes. Commit both locks only after validation. Do not manually edit lock versions
to simulate an installation.

For runtime upgrades, check official stable releases, update pins and base digest,
and avoid prereleases. If Rocker changes Ubuntu version, update the Linux package
repository in the R script accordingly. Retest the full book after each upgrade group.

## Acceptance checks

- Build the renderer from the locks; rendering should not install packages.
- `quarto check` must confirm usable knitr and Jupyter engines.
- `scripts/check-environment.R` must pass using normal R startup (without `--vanilla`);
  it checks locked versions, interpreter selection, conversion, and table formatting.
- Render all 10 source documents uncached and check the exit code.
- Review tables, figures, sidebar, navigation, and references in a browser.
- Check missing local links/images and unresolved reference warnings.
- Review `_book` changes; a Quarto upgrade can replace many generated library files.
- Record `docker image inspect sab-wcrp-renderer:local --format '{{.Id}}'`, versions,
  and results in the change log.
- Verify Netlify on the next authorized push. Local validation itself does not deploy.

Retain prior locks in Git and the prior built image until accepting an upgrade.
Do not discard unrelated local changes when reverting a failed upgrade.
