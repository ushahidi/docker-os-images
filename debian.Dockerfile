FROM debian:bullseye

ARG TARGETPLATFORM
ARG TARGETARCH

LABEL platform="$TARGETPLATFORM"
LABEL arch="$TARGETARCH"

ENV DOCKERIZE_VERSION=v0.7.0 \
    DOCKERIZE_TEMPLATE_DIR=/tmpl \
    S6_OVERLAY_VERSION=v3.2.0.0

RUN apt-get update && \
    apt-get install -y cron xz-utils curl findutils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN case "${TARGETPLATFORM}" in \
         "linux/amd64")  S6_ARCH=x86_64  ;; \
         "linux/arm64")  S6_ARCH=aarch64  ;; \
         "linux/arm/v7") S6_ARCH=armhf  ;; \
         "linux/arm/v6") S6_ARCH=arm  ;; \
         "linux/386")    S6_ARCH=i686   ;; \
    esac && \
    curl -L https://github.com/just-containers/s6-overlay/releases/download/${S6_OVERLAY_VERSION}/s6-overlay-${S6_ARCH}.tar.xz | \
         tar -C / -xJv && \
    case "${TARGETPLATFORM}" in \
         "linux/amd64")  DOCKERIZE_ARCH=amd64  ;; \
         "linux/arm64")  DOCKERIZE_ARCH=armhf  ;; \
         "linux/arm/v7") DOCKERIZE_ARCH=armhf  ;; \
         "linux/arm/v6") DOCKERIZE_ARCH=armel  ;; \
         "linux/386")    DOCKERIZE_ARCH=386   ;; \
    esac && \
    curl -L https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/dockerize-linux-${DOCKERIZE_ARCH}-${DOCKERIZE_VERSION}.tar.gz | \
      tar -C /usr/local/bin -xzv

# Add utilities for Cascading Entrypoint Scripts
# To be deprecated: substituted by s6-overlay
ENV DOCKERCES_MANAGE_UTIL=/manage.CES.sh \
    DOCKERCES_ENTRYPOINT_CHAIN=/entrypoints.CES \
    DOCKERCES_ENDPOINT_FILE=/endpoint.CES \
    DOCKERCES_ENTRYPOINT=/entrypoint.CES.sh \
    DOCKERCES_DEBUG=1
COPY /entrypoint.CES.sh $DOCKERCES_ENTRYPOINT
RUN ln -s /entrypoint.CES.sh $DOCKERCES_MANAGE_UTIL
# Set up Cacading Entrypoint Scripts as master entrypoint
ENTRYPOINT [ "/bin/bash", "/entrypoint.CES.sh" ]

# Add dockerize initializer
COPY /init.dockerize.sh /
RUN $DOCKERCES_MANAGE_UTIL add /init.dockerize.sh

# TODO to introduce s6 overlay
# Add services
# ADD services.d/ /etc/services.d/

# Set s6-overlay as the CES endpoint
# RUN $DOCKERCES_MANAGE_UTIL endpoint /init
