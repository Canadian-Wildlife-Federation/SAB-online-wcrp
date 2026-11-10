# Northeastern PEI Watershed Connectivity Restoration Plan

This Canadian Wildlife Federation project publishes a **Quarto book**. Edit the
source, render locally, review, and push the source **and `_book/`** to GitHub.
Netlify publishes the committed HTML.

The Docker build and all ten chapters have been validated locally. Visual review
and the first Netlify deployment remain user steps; see the
[validation record](maintenance/CHANGELOG.md).

## Build and review

### From RStudio

Start Docker Desktop with Linux containers, open `sab-quarto.Rproj`, and save your
content edits. In RStudio's **Console**, run:

```r
source("scripts/preview.R")
```

The helper prepares Docker when needed, renders and checks the book, and opens
<http://localhost:8000>. Run the same command again after saving further edits.
You can also open `scripts/preview.R` and click **Source**. Use this helper instead
of RStudio's normal Render/Preview buttons, which use local software.

To stop the background preview:

```r
source("scripts/stop-preview.R")
```

The helper needs only base R on the host. Opening the project no longer activates
a local renv environment automatically. See the [RStudio guide](maintenance/CONTENT-UPDATES.md#using-rstudio-recommended-for-rstudio-users).

### From a terminal

Start Docker Desktop with Linux containers. Open PowerShell in this folder:

```powershell
docker compose build book
docker compose run --rm book
docker compose up preview
```

Open <http://localhost:8000>. Stop preview with Ctrl+C, then `docker compose down`.
Build the image on first setup and after dependency changes; text edits only need
rendering. Local R, Python, Quarto, and RStudio versions are not used by these commands.

## Content sources

| Content | Source |
| --- | --- |
| Executive summary | `index.qmd` |
| Chapters/appendices | `content/*.qmd` listed in `_quarto.yml` |
| Tables | `content/data/Table*.csv` |
| Maps/figures | `content/images/` |
| References | `references.bib` |
| Navigation/settings | `_quarto.yml` |
| Table formatting | `content/Rscripts/table_formatting.R` |

Do not edit `_book/` directly. Notebook copies and `summary/` are not sources for
the configured book. Tracking spreadsheets do not automatically update the CSVs.

The broken PEI API integration is temporarily disabled. Its unused chunks do not
supply the currently displayed figures. Once repaired, APIs should refresh on each
render; caching/freezing are disabled.

Read the [content update guide](maintenance/CONTENT-UPDATES.md),
[container maintenance guide](maintenance/CONTAINER.md),
[project assessment](maintenance/PROJECT-ASSESSMENT.md), and
[change log](maintenance/CHANGELOG.md).
