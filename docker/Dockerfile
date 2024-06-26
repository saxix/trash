# syntax=docker/dockerfile:1
ARG PYTHON_VER=3.12
ARG PKG_DIR=/code/__pypackages__/${PYTHON_VER}
ARG CHECKSUM
ARG VERSION=0.1.0
ARG BUILD_DATE=not_provided

ARG APATH=${PKG_DIR}/bin
ARG APYTHONPATH=${PKG_DIR}/lib/

FROM python:${PYTHON_VER}-slim-bookworm AS python_base
ARG APATH
ENV APATH=$APATH
ARG APYTHONPATH
ENV APYTHONPATH=$APYTHONPATH
ARG PKG_DIR
ENV PKG_DIR=$PKG_DIR

ARG CHECKSUM
ENV CHECKSUM=$CHECKSUM
ARG VERSION
ENV VERSION=$VERSION
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
ARG SOURCE_COMMIT
ENV SOURCE_COMMIT=$SOURCE_COMMIT
ARG GITHUB_SERVER_URL
ENV GITHUB_SERVER_URL=$GITHUB_SERVER_URL
ARG GITHUB_REPOSITORY
ENV GITHUB_REPOSITORY=$GITHUB_REPOSITORY

ARG GOSU_VERSION=1.17
ARG GOSU_SHA256=bbc4136d03ab138b1ad66fa4fc051bafc6cc7ffae632b069a53657279a450de3
ARG TINI_VERSION=0.19.0
ARG TINI_SHA256=93dcc18adc78c65a028a84799ecf8ad40c936fdfc5f2a57b1acda5a8117fa82c
ARG WAITFOR_IT_VERSION=2.4.1
ARG WAITFOR_IT_MD5=cd67c8e45436c4a7b2b707d7a5b15a66


RUN set -x \
  && buildDeps=" \
  wget \
  " \
  && apt-get update && apt-get install -y --no-install-recommends ${buildDeps} \
  && rm -rf /var/lib/apt/lists/* \
  && wget --quiet -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-amd64" \
  && echo "$GOSU_SHA256 /usr/local/bin/gosu" | sha256sum --check --status \
  && chmod +x /usr/local/bin/gosu \
  && wget --quiet -O /usr/local/bin/tini "https://github.com/krallin/tini/releases/download/v$TINI_VERSION/tini-amd64" \
  && echo "$TINI_SHA256 /usr/local/bin/tini" | sha256sum --check --status \
  && chmod +x /usr/local/bin/tini \
  && wget --quiet -O /usr/local/bin/waitforit "https://github.com/maxcnunes/waitforit/releases/download/v$WAITFOR_IT_VERSION/waitforit-linux_amd64" \
  && echo "$WAITFOR_IT_MD5 /usr/local/bin/waitforit" | md5sum --check --status \
  && chmod +x /usr/local/bin/waitforit  \
  && apt-get purge -y --auto-remove $buildDeps


RUN \
    --mount=type=cache,target=/var/cache/apt \
    apt-get clean \
    && apt-get update  \
    && apt-get install -y --no-install-recommends  \
      postgresql-client \
      libxml2  \
      mime-support  \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --gid 1024 app \
    && adduser --disabled-login --disabled-password --no-create-home --ingroup app -q user \
    && echo $CHECKSUM > /CHECKSUM


COPY docker/bin/* /usr/local/bin/
COPY docker/conf/* /conf/

FROM python_base AS build_deps
ENV buildDeps="build-essential \
  gcc \
  libpcre3-dev \
  wget \
  zlib1g-dev \
"

RUN set -x \
    && buildDeps="build-essential \
        cmake \
        curl \
        gcc \
        libgdal-dev \
        libgif-dev \
        libjpeg-dev \
        liblapack-dev \
        libopenblas-dev \
        libpng-dev  \
        libpq-dev \
        libwebp-dev \
        libssl-dev \
        libxml2-dev  \
        python3-dev \
        zlib1g-dev  \
    " \
    && apt-get update \
    && apt-get install -y --no-install-recommends $buildDeps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PATH=${APATH}:${PATH} \
    PYTHONPATH=${APYTHONPATH}:/code/app/src \
    PYTHONDONTWRITEBYTCODE=1


FROM build_deps AS python_dev_deps
ARG CHECKSUM
ENV CHECKSUM=$CHECKSUM
ARG VERSION
ENV VERSION=$VERSION
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
ARG SOURCE_COMMIT
ENV SOURCE_COMMIT=$SOURCE_COMMIT
ARG GITHUB_SERVER_URL
ENV GITHUB_SERVER_URL=$GITHUB_SERVER_URL
ARG GITHUB_REPOSITORY
ENV GITHUB_REPOSITORY=$GITHUB_REPOSITORY


LABEL date=$BUILD_DATE
LABEL version=$VERSION
LABEL checksum=$CHECKSUM

WORKDIR /code
COPY pyproject.toml pdm.lock ./
COPY docker/conf/config.toml /etc/xdg/pdm/config.toml
RUN <<EOF cat> /RELEASE
{"version": "$VERSION",
 "commit": "$SOURCE_COMMIT",
 "date": "$BUILD_DATE",
 "checksum": "$CHECKSUM",
 "source": "${GITHUB_SERVER_URL}/$${GITHUB_REPOSITORY}/tree/${SOURCE_COMMIT:-master}/"
}
EOF

RUN set -x \
    && pip install -U pip pdm \
    && mkdir -p $PKG_DIR \
    && pdm sync --no-editable -v --no-self


FROM python_dev_deps AS python_prod_deps
ARG PKG_DIR
ARG CHECKSUM
ENV CHECKSUM=$CHECKSUM
ARG VERSION
ENV VERSION=$VERSION
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
ARG SOURCE_COMMIT
ENV SOURCE_COMMIT=$SOURCE_COMMIT
ARG GITHUB_SERVER_URL
ENV GITHUB_SERVER_URL=$GITHUB_SERVER_URL
ARG GITHUB_REPOSITORY
ENV GITHUB_REPOSITORY=$GITHUB_REPOSITORY

LABEL date=$BUILD_DATE
LABEL version=$VERSION
LABEL checksum=$CHECKSUM

WORKDIR /code
COPY docker/conf/config.toml /etc/xdg/pdm/config.toml
COPY pyproject.toml pdm.lock ./
COPY ./src /code/src


RUN mkdir -p $PKG_DIR \
    && pip install -U pdm \
    && pdm sync --no-editable -v --prod


FROM python_base AS dist

ARG PKG_DIR
ARG CHECKSUM
ENV CHECKSUM=$CHECKSUM
ARG VERSION
ENV VERSION=$VERSION
ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE
ARG SOURCE_COMMIT
ENV SOURCE_COMMIT=$SOURCE_COMMIT
ARG GITHUB_SERVER_URL
ENV GITHUB_SERVER_URL=$GITHUB_SERVER_URL
ARG GITHUB_REPOSITORY
ENV GITHUB_REPOSITORY=$GITHUB_REPOSITORY

RUN <<EOF cat> /RELEASE
{"version": "$VERSION",
 "commit": "$SOURCE_COMMIT",
 "date": "$BUILD_DATE",
 "checksum": "$CHECKSUM",
 "source": "${GITHUB_SERVER_URL}/$${GITHUB_REPOSITORY}/tree/${SOURCE_COMMIT:-master}/"
}
EOF

WORKDIR /code
COPY --chown=user:app --from=python_prod_deps /code /code
COPY --chown=user:app --from=python_prod_deps /RELEASE /RELEASE

VOLUME /var/run/app/
EXPOSE 8000
ENTRYPOINT exec docker-entrypoint.sh "$0" "$@"
CMD ["run"]

LABEL maintainer="mnt@app.io"
LABEL org.opencontainers.image.authors="author@app.io"
LABEL org.opencontainers.image.created="$BUILD_DATE"
LABEL org.opencontainers.image.description="App runtime image"
LABEL org.opencontainers.image.documentation="https://github.com/saxix/trash"
LABEL org.opencontainers.image.licenses="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/blob/${SOURCE_COMMIT:-master}/LICENSE"
LABEL org.opencontainers.image.revision=$SOURCE_COMMIT
LABEL org.opencontainers.image.source="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/tree/${SOURCE_COMMIT:-master}/"
LABEL org.opencontainers.image.title="App"
LABEL org.opencontainers.image.url="https://app.io/"
LABEL org.opencontainers.image.vendor="App ltd"
LABEL org.opencontainers.image.version="$VERSION"

