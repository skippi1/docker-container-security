FROM alpine:3.12.0

ARG BUILD_DATE
ARG REVISION
ARG VERSION
ARG IMAGE

LABEL name="lp/hugo-builder" \
      version="0.1" \
      release="1.0" \
      architecture="x86_64" \
      vendor="markus" \ 
      maintainer="markus" \
      io.k8s.description="Live Project Example using Hugo Builder" \
      io.k8s.display-name="Hugo Builder" \
      io.openshift.expose-services="1313:http" \
      io.openshift.tags="builder" 
LABEL  org.opencontainers.image.created="${BUILD_DATE}"
LABEL  org.opencontainers.image.authors="Markus Breuer" 
LABEL  org.opencontainers.image.url="https://github.com/skippi1/docker-container-security" 
LABEL  org.opencontainers.image.documentation="live project user content" 
LABEL  org.opencontainers.image.source="https://github.com/skippi1/docker-container-security" 
LABEL  org.opencontainers.image.version="${VERSION}" 
LABEL  org.opencontainers.image.revision="${REVISION}" 
LABEL  org.opencontainers.image.vendor="n/a" 
LABEL  org.opencontainers.image.licenses="n/a" 
LABEL  org.opencontainers.image.ref.name="${IMAGE}"

ENV BUILD_DATE ${BUILD_DATE:-not-set}

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

HEALTHCHECK --interval=5s --timeout=3s CMD if [ -f /src/public/index.html ] ; then exit 0; else exit 1; fi

# hadolint ignore=DL3018
RUN apk add --no-cache \
    curl \
    git \
    openssh-client \
    rsync \
    gnupg

ENV VERSION 0.64.0

RUN mkdir -p /usr/local/src

WORKDIR  /usr/local/src 

RUN curl -L \
      https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_checksums.txt | grep "hugo_${VERSION}_Linux-64bit.tar.gz" > hugo_${VERSION}_checksums.txt \
    && curl -L --output hugo_${VERSION}_Linux-64bit.tar.gz \
      https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_Linux-64bit.tar.gz \
    && sha256sum -c hugo_${VERSION}_checksums.txt \
    && tar xzvf hugo_${VERSION}_Linux-64bit.tar.gz \
    && mv hugo /usr/local/bin/hugo \
    && addgroup -Sg 1000 hugo \
    && adduser -SG hugo -u 1000 -h /src hugo \
    && rm -rf /usr/local/src

ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /tini.asc
RUN gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 \
 && gpg --batch --verify /tini.asc /tini && \
 chmod +x /tini


WORKDIR /src

EXPOSE 1313

#USER hugo

CMD [ "hugo", "server", "-w", "--bind=0.0.0.0" ]
