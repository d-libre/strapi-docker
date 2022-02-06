ARG NODE_BASE=12-alpine
ARG STRAPI_VER=3.6.2
# Final target path
ARG APP_PATH=/srv/app

# Shared stage/base image
FROM node:${NODE_BASE} AS base
ARG STRAPI_VER
ARG SRC_PATH=/src
LABEL maintainer="salvador.dev@outlook.com"

# Building stage
FROM base AS builder
ARG STRAPI_VER

ARG DEFAULT_DB_CLIENT=postgres
ARG DEFAULT_DB_HOST=localhost
ARG DEFAULT_DB_PORT=5432
ARG DEFAULT_DB_NAME=strapi
ARG DEFAULT_DB_USERNAME=strapi
ARG DEFAULT_DB_PASSWORD=DefaultPassphrase2bSet

WORKDIR ${SRC_PATH}

# Generate & Build a new Strapi app (from scratch)
RUN DOCKER=true npx create-strapi-app@${STRAPI_VER} . \
    --dbclient="${DEFAULT_DB_CLIENT}" \
    --dbhost="${DEFAULT_DB_HOST}" \
    --dbport="${DEFAULT_DB_PORT}" \
    --dbname="${DEFAULT_DB_NAME}" \
    --dbusername="${DEFAULT_DB_USERNAME}" \
    --dbpassword="${DEFAULT_DB_PASSWORD}" \
    --no-run \
    && yarn --frozen-lockfile --production \
    && yarn build


# Deployment Stage (only target/binaries)
FROM base AS final
ARG APP_PATH
ARG STRAPI_VER

ENV VERSION=STRAPI_VER

WORKDIR ${APP_PATH}

COPY --from=builder ${SRC_PATH}/ ./

VOLUME ["${APP_PATH}", "${APP_PATH}/api", "${APP_PATH}/extensions"]

EXPOSE 1337

ENTRYPOINT [ "yarn", "develop" ]
