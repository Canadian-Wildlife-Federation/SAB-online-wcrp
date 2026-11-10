# Project assessment — 2026-10-03

## Build and deployment

This is a Quarto HTML book with 10 configured source documents: the index, seven
chapters, and two appendices. R/knitr renders CSV tables through `flextable` and
`magrittr`; `reticulate` is loaded in two chapters. The index selects Jupyter.

The owner confirmed: render locally, commit the source and generated `_book`, push
to GitHub, and Netlify publishes the committed static site. Docker belongs at the
rendering step. Netlify does not need this container or R/Python. No GitHub Actions
workflow is present; adding one is a separate future decision.

## Initial environment

| Component | At the start of this assessment |
| --- | --- |
| R | `renv.lock` and local installation: 4.4.1 |
| Python | lock metadata: 3.11.3; Netlify: 3.11; local PATH: 3.12.0 |
| Quarto | local 1.5.57; no repository version pin |
| R libraries | mixed older/newer packages in `renv.lock` |
| Python libraries | pinned packages, but incomplete Jupyter rendering stack |
| Python path | lock refers to `renv-python-3.8` despite recording Python 3.11.3 |
| Netlify | only Python version configured; publish settings implicit |
| System libraries/fonts | not declared |
| Docker | Desktop 4.36.0 / Engine 27.3.1; engine became unreachable during inspection |

The old README describes an additional Jupyter book and limits Python to <=3.11.
Those claims were not validated against the present source. Runtime upgrades need
package resolution and full rendering tests, not just changes to version numbers.

## Data and content findings

- Hidden Python chunks in `index.qmd` and `content/connectivity-status.qmd` request
  Nova Scotia/Cheticamp (`CHETI`) data despite the PEI content. Their assigned values
  are not interpolated into the displayed book. The owner confirmed these calls are
  broken and should be ignored for now. Both chunks are temporarily `eval: false`.
- The owner wants live data on future builds. Caching/freezing are disabled, but
  that does not repair or enable the currently disabled API integration.
- Published tables read local CSVs. No automatic tracking-XLSX-to-CSV pipeline was found.
- `api_calls.py` is an unused Horsefly/BC module with requests at import time.
- `api_calls_v2.py` includes an unused reader for the missing
  `content/data/combined_output_table_vw.csv`.
- The unused `connectivity_assess.py` uses chained pandas assignment and removed
  `Styler.applymap`; modernize and review its scientific boundaries before reuse.
- The sidebar logo path was wrong; it now points to `content/images/logo.png`.
- Rainbow Smelt placeholders and unfinished scientific content remain unchanged.
- `_book/` must remain tracked for deployment. `summary/`, notebook copies, and
  tracked bytecode are future cleanup candidates, not active book sources.

## Upgrade acceptance

A release becomes this project's working version after a clean image build,
Jupyter/knitr and R/Python bridge checks, complete uncached render, and visual review
of navigation, tables, figures, and references. Dependency resolution alone is not
proof of compatibility. Record results in `CHANGELOG.md`.

Use explicit runtimes and locked libraries; upgrade deliberately rather than on
each render. After APIs are restored, changed live data can still change output
between builds even when software versions are identical.

## References

- [Quarto releases](https://github.com/quarto-dev/quarto-cli/releases/latest)
- [R releases](https://www.r-project.org/)
- [Python releases](https://www.python.org/downloads/)
- [Rocker versioned images](https://rocker-project.org/images/versioned/r-ver.html)
- [Quarto execution](https://quarto.org/docs/projects/code-execution.html)
- [Netlify dependency detection](https://docs.netlify.com/build/configure-builds/manage-dependencies/)
- [Netlify configuration](https://docs.netlify.com/build/configure-builds/file-based-configuration/)
- [uv resolution](https://docs.astral.sh/uv/concepts/resolution/)
