# Future content updates

## One-time setup

Clone the repository with Git or download and extract its ZIP. Git is needed to
commit/push contributions. Install Docker Desktop and use Linux containers (WSL 2
on Windows). Start Docker and wait for **Engine running**. Internet access is needed
for the first environment build. Check `CHANGELOG.md` before publishing.

Use the RStudio helper below, or open a terminal in the checkout and run
`docker compose build book`. You can edit in RStudio, VS Code, or another editor;
Docker provides the R/Python/Quarto versions used to render the book.

## Using RStudio (recommended for RStudio users)

1. Open `sab-quarto.Rproj` from the downloaded/cloned folder.
2. Edit the QMD files, CSVs, or figures, then **save your changes**. The helper reads
   saved files on disk, not unsaved editor tabs.
3. In the RStudio **Console** (not Terminal), run:

   ```r
   source("scripts/preview.R")
   ```

   Alternatively, open `scripts/preview.R` and click **Source** to run the whole file.
4. Wait for **Preview ready: http://localhost:8000**. The helper opens your browser;
   if it does not, open that address yourself. Review the changed pages and tables.
5. After saving more edits, run the same command again. There is no automatic
   live reload; each invocation renders the complete book. Refresh any existing
   browser tab if it still shows the previous page.

The helper checks Docker, builds the environment on first use or when build inputs
change, renders, checks local links/assets, and starts preview in the background.
Later content-only edits reuse the image. The first build can take several minutes.
You do not need to run `renv::restore()` or install the project's packages locally.
Your RStudio installation still needs its usual R interpreter; the helper uses
base R, and all book computation happens inside Docker.

**Use the helper instead of RStudio's usual Render/Preview buttons.** Those buttons
have not been redirected to Docker. Opening the project defaults to the Docker
workflow and no longer activates a host renv library automatically.

The preview is temporarily stopped while rebuilding/rendering so it cannot serve
partially written output. If a build, render, or check fails, it stays stopped and
the Console explains the failure. Fix the error and rerun the helper; do not publish
the failed run's `_book`. An already open browser tab can retain its previously
loaded page until refreshed.

To stop preview when finished, run:

```r
source("scripts/stop-preview.R")
```

This stops only this project's preview service. It keeps content, generated HTML,
and the Docker image. Closing RStudio alone does not stop the background preview.
Nothing is committed, pushed, or published by either helper.

If Docker is not found, install/start Docker Desktop and restart RStudio so it sees
the updated PATH. If the engine is unavailable, wait for **Engine running** and
retry. If port 8000 is occupied by another program, stop that program or ask the
project maintainer for help; the helper will not stop unrelated services.

## Every update

RStudio users can use `source("scripts/preview.R")` in place of terminal steps 5–6
below, and `source("scripts/stop-preview.R")` for step 7. The review/commit steps
are the same for both workflows.

1. Check `git status`, preserve uncommitted work, and pull the team's changes.
2. Edit `index.qmd` or the relevant `content/*.qmd`. Preserve cross-reference labels
   such as `#tbl-...`, `#fig-...`, and `@...` unless changing references intentionally.
3. Update tables in `content/data/Table*.csv`, retaining required column names.
   Editing tracking spreadsheets alone does not update published tables.
4. Update figures in `content/images/` and corresponding captions/dates as needed.
5. Run `docker compose run --rm book` and wait for success. Then run
   `docker compose run --rm book python scripts/check-render.py`. If either fails,
   do not publish the partially generated `_book`; fix the cause and rerender.
6. Run `docker compose up preview`, open <http://localhost:8000>, and review changed
   chapters, tables, figures, links, and navigation.
7. Stop preview with Ctrl+C, then run `docker compose down`.
8. Review and stage the intended source files plus all generated output:

   ```powershell
   git diff --stat
   git add index.qmd content _quarto.yml references.bib style.css
   git add -A _book
   git diff --cached --stat
   git commit -m "Update PEI restoration plan content"
   git push
   ```

   The source staging command is an example; stage only your intended changes.
9. Check the Netlify deployment and public website after the push.

Never edit `_book` directly. Edit references in `references.bib`, navigation in
`_quarto.yml`, and table formatting in `content/Rscripts/table_formatting.R`.
The `.ipynb` files and `summary/` are not sources for the configured Quarto book.
Ordinary content changes do not require dependency upgrades. The RStudio helper
detects changes to the image inputs and rebuilds automatically. Terminal users
must rebuild after changes to `Dockerfile`, `renv.lock`, or `docker/requirements.lock.txt`.

## Live data

Two unused API chunks are temporarily disabled because the PEI integration is
broken. A successful build today does not prove a live data refresh. Published PEI
numbers and CSVs are still manual inputs. Once the endpoint/watershed are confirmed,
a maintainer must remove both `eval: false` options, connect the intended values to
the text/tables, and verify results. Executable chunks will then run on every render.
An API outage should fail visibly; do not silently publish stale replacement data.

## Netlify

The repository specifies the root base directory, `_book` as the publish directory,
and a command that only checks `_book/index.html` exists. In Netlify, confirm the connected repository, production branch, and
root base directory. Keep the existing GitHub connection. Netlify should serve the
committed HTML without rendering Quarto or installing Python. Python's lock lives
under `docker/` to avoid root `requirements.txt` autodetection. File settings
override corresponding dashboard settings; account settings have not been verified.

## Recovery

For a bad deployment, use Netlify rollback or revert the associated commit,
including `_book`, and push the revert. Rerendering old source against changed live
data is not an exact rollback.

If Docker cannot reach its engine, use the system-tray **Quit Docker Desktop**,
reopen it, and wait for the engine. Closing the window alone may leave the backend
running. Persistent errors may need a Docker/WSL update or computer restart. Avoid
factory reset, which can remove unrelated Docker data.
