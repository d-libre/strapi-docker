ARG NODE_BASE=14-alpine

# -----| base |-----
# Shared stage/base image
FROM node:${NODE_BASE} AS base

ARG NODE_BASE
# The custom User/Group Id
ARG UID=1000
ARG USR_PATH=/usr/local/lib/docker

LABEL maintainer="github.com/SalvadorCodes"

LABEL org.opencontainers.image.title="Boostrapi-Tools" \
      org.opencontainers.image.version="node-${NODE_BASE}"

LABEL org.opencontainers.image.description="Containerized tools to generate/maintain a ci/cd ready docker image with your Strapi application"
LABEL org.opencontainers.image.authors="github.com/SalvadorCodes"

LABEL org.opencontainers.image.url=https://hub.docker.com/repository/docker/libre/strapi \
      org.opencontainers.image.documentation=https://github.com/d-libre/strapi-docker#readme

LABEL org.opencontainers.image.source=https://github.com/d-libre/strapi-docker/blob/main/docker/base/tools/Dockerfile

LABEL org.opencontainers.image.base.name=docker.io/library/node:${NODE_BASE}

COPY --from=libre/gget  /usr/local/ /usr/local/
ADD assets/utils/ ${USR_PATH}/utils/

# Install Bash, Curl & jq for both builder and final
# + Remove the "node" user:group pair & create the new ones to run strapi
# + Symlinks for all custom bash scripts to the /usr/local/bin location
RUN apk add --no-cache bash curl vim jq \
    && deluser --remove-home node \
    && addgroup -g ${UID} -S strapi \
    && adduser -h /home/strapi -u ${UID} -G strapi -D strapi \
    && rm /usr/local/bin/docker-entrypoint.sh \
    && ${USR_PATH}/utils/binlink.sh ${USR_PATH} 2 sh

ENTRYPOINT [ "/bin/bash" ]