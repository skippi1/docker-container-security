FROM alpine:3.12.0

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

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

HEALTHCHECK --interval=5s --timeout=3s CMD curl -f http://localhost:1313/ || exit 1;

# hadolint ignore=DL3018
RUN apk add --no-cache \
    curl \
    git \
    openssh-client \
    rsync

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

WORKDIR /src

EXPOSE 1313

USER hugo

CMD [ "hugo", "server", "-w", "--bind=0.0.0.0" ]
