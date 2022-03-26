ARG BASE_NODE_VERSION=14
ARG STRAPI_VER=3.6.8
# Final target path
ARG APP_PATH=/srv/app
ARG SRC_PATH=/src

ARG LIB_NAME=boostrapi
ARG USR_PATH=/usr/local/lib/docker/
ARG CFG_PATH=/var/local/strapi/configs/

# -----| base |-----
# Shared stage/base image
FROM libre/strapi-base:node-${BASE_NODE_VERSION} AS base

ARG SRC_PATH
ARG USR_PATH
ARG CFG_PATH
ARG BASE_NODE_VERSION
ARG STRAPI_VER

LABEL org.opencontainers.image.title="Strapi CI-CD" \
      org.opencontainers.image.version="v${STRAPI_VER}-n${BASE_NODE_VERSION}"

LABEL org.opencontainers.image.source=https://github.com/d-libre/strapi-docker/blob/main/docker/Dockerfile

LABEL org.opencontainers.image.base.name=docker.io/libre/strapi-base:node-${BASE_NODE_VERSION}

# Make Strapi Version available to both install scripts & containers
ENV VERSION $STRAPI_VER

# ---| Cache |---
# Pre-build cache
FROM libre/strapi-cache:v${STRAPI_VER}-n${BASE_NODE_VERSION} AS cache

# -----| builder |-----
# Building stage
FROM base AS builder

ARG LIB_NAME
ARG NODE_LIB=/usr/local/lib/node_modules

ENV LIB_PATH /usr/local/lib/$LIB_NAME/

COPY --from=base /usr/local/lib/ /tmp/local/lib/
COPY --from=base /usr/local/bin/ /tmp/local/bin/

# Get Strapi & node-gyp packages from pre-built cache
COPY --from=cache ${NODE_LIB}/      ${NODE_LIB}/
COPY --from=cache /usr/local/bin/   /usr/local/bin/

# Build/Install Boostrapi tools
WORKDIR ${LIB_PATH}
ADD assets/generator/ ./

# TODO: Extract/Copy directly from package
RUN cp -r ${NODE_LIB}/strapi/node_modules/strapi-generate-new/lib/*/ .

RUN npm install . \
    && binlink ${LIB_PATH} 1 js

# Using Custom tools to generate configurations for all db clients
RUN mkdir -p ${CFG_PATH} \
    && generate-db-configs ${CFG_PATH} \
    && set-db-dependencies

RUN diff-copy /tmp/local /usr/local /src/local


# # -----| final |-----
# Final Stage (only installed modules/libs)
FROM base AS final

ARG APP_PATH

ENV APP_PATH $APP_PATH
ENV DB_CONFIGS_PATH $CFG_PATH

COPY --from=builder     /src/local/ /usr/local/
COPY --from=builder     --chown=strapi:strapi \
                        ${CFG_PATH} ${CFG_PATH}

ADD docker-entrypoint.sh /usr/bin/entrypoint

USER strapi:strapi

WORKDIR ${APP_PATH}

ENTRYPOINT [ "entrypoint" ]

CMD [ "bash" ]
