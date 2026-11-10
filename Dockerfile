# syntax=docker/dockerfile:1
# Linux/amd64 is intentional: everyone renders with the same platform.
FROM ghcr.io/astral-sh/uv:0.12.23@sha256:61d393e44e249f2e4b526b6c7ddcecce245946826e608e11c93ad4f5bba55b21 AS uv
FROM rocker/r-ver:4.6.1@sha256:268e4c559c905a78519793f1a8c9ec5c8051a6ac98a16cbf489135ccdad330bb AS toolchain

ARG QUARTO_VERSION=1.10.18
ARG PYTHON_VERSION=3.14.8
ARG RENV_VERSION=1.3.0

ENV DEBIAN_FRONTEND=noninteractive \
    UV_PYTHON_INSTALL_DIR=/opt/python \
    UV_PYTHON_PREFERENCE=only-managed \
    R_LIBS_USER=/opt/R/library \
    RENV_CONFIG_AUTOLOADER_ENABLED=false \
    RENV_CONFIG_CACHE_ENABLED=false \
    RETICULATE_PYTHON=/opt/venv/bin/python \
    QUARTO_PYTHON=/opt/venv/bin/python \
    PYTHONDONTWRITEBYTECODE=1 \
    PATH=/opt/venv/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl git make g++ pkg-config libuv1-dev \
    libcurl4-openssl-dev libssl-dev libxml2-dev \
    libcairo2-dev libfontconfig1-dev libfreetype6-dev \
    libharfbuzz-dev libfribidi-dev libpng-dev libtiff-dev libjpeg-dev \
    fonts-dejavu fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

COPY --from=uv /uv /usr/local/bin/uv
RUN uv python install ${PYTHON_VERSION} \
    && uv venv --python ${PYTHON_VERSION} /opt/venv

RUN curl -fsSL -o /tmp/quarto.deb "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb" \
    && curl -fsSL -o /tmp/checksums.txt "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-checksums.txt" \
    && cd /tmp \
    && grep " quarto-${QUARTO_VERSION}-linux-amd64.deb$" checksums.txt | sed 's|quarto-.*-linux-amd64.deb|quarto.deb|' | sha256sum --check --strict - \
    && dpkg -i /tmp/quarto.deb \
    && rm /tmp/quarto.deb /tmp/checksums.txt

RUN mkdir -p /opt/R/library \
    && (curl -fsSL -o /tmp/renv.tar.gz "https://cran.r-project.org/src/contrib/renv_${RENV_VERSION}.tar.gz" \
        || curl -fsSL -o /tmp/renv.tar.gz "https://cran.r-project.org/src/contrib/Archive/renv/renv_${RENV_VERSION}.tar.gz") \
    && Rscript --vanilla -e "install.packages('/tmp/renv.tar.gz', repos = NULL, type = 'source'); stopifnot(as.character(packageVersion('renv')) == '${RENV_VERSION}')" \
    && rm /tmp/renv.tar.gz

WORKDIR /project

FROM toolchain AS python-dependencies
COPY docker/requirements.lock.txt /tmp/requirements.txt
RUN uv pip sync --python /opt/venv/bin/python --require-hashes /tmp/requirements.txt

FROM python-dependencies AS renderer
COPY renv.lock /tmp/renv.lock
RUN Rscript --vanilla -e 'renv::restore(lockfile="/tmp/renv.lock", library="/opt/R/library", prompt=FALSE)'
# Rocker's Renviron.site otherwise puts its bundled libraries before R_LIBS_USER.
ENV R_LIBS=/opt/R/library
CMD ["quarto", "render", "--no-cache"]
