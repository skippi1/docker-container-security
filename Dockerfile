FROM alpine:3.12.0

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

RUN CHECKSUM=$(curl -L \
      https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_checksums.txt | grep hugo_${VERSION}_Linux-64bit.tar.gz | awk '{ print $1}') \
    && echo "CHECKSUM=${CHECKSUM}" \
    && curl -L \
      https://github.com/gohugoio/hugo/releases/download/v${VERSION}/hugo_${VERSION}_linux-64bit.tar.gz | tee hugo_${VERSION}_linux-64bit.tar.gz | sha256 --check < (echo "${CHECKSUM}  -") \
    && tar xzvf hugo_${VERSION}_linux-64bit.tar.gz \
    && mv hugo /usr/local/bin/hugo \
    && addgroup -Sg 1000 hugo \
    && adduser -SG hugo -u 1000 -h /src hugo

WORKDIR /src

EXPOSE 1313
