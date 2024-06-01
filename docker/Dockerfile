# syntax=docker/dockerfile:1
ARG PYTHON_VER=3.12
ARG PKG_DIR=/code/__pypackages__/${PYTHON_VER}
ARG CHECKSUM
ARG VERSION=0.1.0
ARG BUILD_DATE=not_provided

ARG APATH=${PKG_DIR}/bin
ARG APYTHONPATH=${PKG_DIR}/lib/

FROM python:$PYTHON_VER-slim-bullseye AS python_base
ARG PKG_DIR
ENV PKG_DIR=$PKG_DIR
ARG CHECKSUM
ENV CHECKSUM=$CHECKSUM
ARG VERSION
ENV VERSION=$VERSION
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
ARG APATH
ENV APATH=$APATH
ARG APYTHONPATH
ENV APYTHONPATH=$APYTHONPATH

ARG GOSU_VERSION=1.17
ARG GOSU_SHA256=bbc4136d03ab138b1ad66fa4fc051bafc6cc7ffae632b069a53657279a450de3
ARG TINI_VERSION=0.19.0
ARG TINI_SHA256=93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c
SHELL ["/bin/bash", "-c"]

#COPY <<EOT /etc/profile.d/environment.sh
#export VERSION=$VERSION
#export CHECKSUM=$CHECKSUM
#export PKG_DIR=$PKG_DIR
#export BUILD_DATE=$BUILD_DATE
#export PATH=${PKG_DIR}/bin:${PATH}:/usr/local/bin/
#export PYTHONPATH=${PKG_DIR}/lib/
#export PDM_CHECK_UPDATE=0
#export PDM_CACHE_DIR=/cache/
#export PDM_USE_VENV=0
#export PDM_INSTALL_PARALLEL=0
#EOT

RUN set -x \
  && buildDeps=" \
  wget \
  " \
  && apt-get update && apt-get install -y --no-install-recommends $buildDeps \
  && rm -rf /var/lib/apt/lists/* \
  && wget --quiet -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
  && echo "$GOSU_SHA256 /usr/local/bin/gosu" | sha256sum --check --status \
  && chmod +x /usr/local/bin/gosu \
  && wget --quiet -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini-amd64" \
  && echo "$TINI_SHA256 /usr/local/bin/tini" | sha256sum --check --status \
  && chmod +x /usr/local/bin/tini \
  && apt-get purge -y --auto-remove $buildDeps

RUN \
    --mount=type=cache,target=/var/cache/apt \
    apt-get update  \
    && apt-get install -y --no-install-recommends  \
      postgresql-client \
      mime-support  \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig

RUN ln -s -f /bin/true /usr/bin/chfn \
    && groupadd --gid 1024 app \
    && adduser --disabled-login --disabled-password --no-create-home --ingroup app -q user \
    && echo $CHECKSUM > /CHECKSUM \
    && echo $VERSION > /VERSION


COPY docker/bin/* /usr/local/bin/
COPY docker/conf/* /conf/

FROM python_base AS build_deps
ENV buildDeps="build-essential \
 "

RUN apt-get update  \
    && apt-get install -y --no-install-recommends \
    $buildDeps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


FROM build_deps AS python_dev_deps
ARG PKG_DIR
ARG CHECKSUM
ARG VERSION
ARG BUILD_DATE
ARG APATH
ARG APYTHONPATH

LABEL date=$BUILD_DATE
LABEL version=$VERSION
LABEL checksum=$CHECKSUM
ENV PATH=${APATH}:${PATH} \
    PYTHONPATH=${APYTHONPATH}:/code/app/src \
    PYTHONDONTWRITEBYTCODE=1\
    PDM_CHECK_UPDATE=0 \
    PDM_CACHE_DIR=/cache/ \
    PDM_USE_VENV=0 \
    PDM_INSTALL_PARALLEL=0
WORKDIR /code
COPY pyproject.toml .
COPY pdm.lock .
RUN pip install -U pip setuptools pdm \
    && mkdir -p /code/__pypackages__ \
    && pdm sync --no-editable -v --no-self


FROM build_deps AS python_prod_deps
WORKDIR /code
COPY pdm.lock .
COPY ./src /code/src
ENV PATH=${APATH}:${PATH} \
    PYTHONPATH=${APYTHONPATH} \
    PYTHONDONTWRITEBYTCODE=1 \
    PDM_CHECK_UPDATE=0 \
    PDM_CACHE_DIR=/cache/ \
    PDM_USE_VENV=0 \
    PDM_INSTALL_PARALLEL=0

RUN pip install -U pip setuptools pdm \
    && mkdir -p /code/__pypackages__ \
    && pdm sync --no-editable -v --prod \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

#FROM python_base AS dev
#COPY --chown=app:user --from=python_dev_deps /code/__pypackages__ /code/__pypackages__
#COPY ./src /code/src


FROM python_base AS dist
LABEL maintainer="mnt@app.io"
LABEL org.opencontainers.image.title="App"
LABEL org.opencontainers.image.description="App runtime image"
LABEL org.opencontainers.image.url="https://app.io/"
LABEL org.opencontainers.image.documentation="https://github.com/saxix/trash"
LABEL org.opencontainers.image.vendor="App ltd"
LABEL org.opencontainers.image.authors="author@app.io"

ARG PKG_DIR
ARG CHECKSUM
ARG VERSION
ARG BUILD_DATE
LABEL date=$BUILD_DATE
LABEL version=$VERSION
LABEL checksum=$CHECKSUM

WORKDIR /code
COPY --chown=hde:hope --from=python_prod_deps /code/__pypackages__ /code/__pypackages__
USER user
CMD "run"
ENTRYPOINT exec docker-entrypoint.sh "$0" "$@"


LABEL org.opencontainers.image.revision=$SOURCE_COMMIT
LABEL org.opencontainers.image.source="${{env.GITHUB_SERVER_URL}}/${{env.GITHUB_REPOSITORY}}/tree/${SOURCE_COMMIT:-master}/"
LABEL org.opencontainers.image.licenses="${{env.GITHUB_SERVER_URL}}/${{env.GITHUB_REPOSITORY}}/blob/${SOURCE_COMMIT:-master}/LICENSE"