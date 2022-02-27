ARG NODE_BASE=14-alpine
ARG STRAPI_VER=3.6.8
# Final target path
ARG APP_PATH=/srv/app
# The custom User/Group Id
ARG UID=1000

# Shared stage/base image
FROM node:${NODE_BASE} AS base
ARG STRAPI_VER
ARG UID
ARG SRC_PATH=/src
LABEL maintainer="SalDevOps <hector@salvador.codes>"
# Make Strapi Version available to both install scripts & containers
ENV VERSION=$STRAPI_VER

# Install Bash for both builder and final
# Also remove the "node" user:group pair
# and create the new ones to run strapi
RUN apk add --no-cache bash \
    && rm /usr/local/bin/docker-entrypoint.sh \
    && deluser --remove-home node \
    && addgroup -g ${UID} -S strapi \
    && adduser -h /home/strapi -u ${UID} -G strapi -D strapi

# Building stage
FROM base AS builder

# Add curl+jq for builder only
RUN apk add --no-cache curl jq

ARG DEFAULT_DB_CLIENT=-
ARG DEFAULT_DB_HOST=-
ARG DEFAULT_DB_PORT=-
ARG DEFAULT_DB_NAME=-
ARG DEFAULT_DB_USERNAME=-
ARG DEFAULT_DB_PASSWORD=-

# Full github url or shorthand (user/template-name)
ARG STRAPI_TEMPLATE_REPO

ADD scripts/* .

WORKDIR ${SRC_PATH}

# Generate & Build a new Strapi app (from scratch)
# by using our bash script helper
RUN ../install-strapi.sh \
    -S ${VERSION} \
    -c "${DEFAULT_DB_CLIENT}" \
    -h "${DEFAULT_DB_HOST}" \
    -p "${DEFAULT_DB_PORT}" \
    -d "${DEFAULT_DB_NAME}" \
    -U "${DEFAULT_DB_USERNAME}" \
    -P "${DEFAULT_DB_PASSWORD}" \
    -qx

# Import Strapi Template (if provided)
RUN ../import-template.sh ${STRAPI_TEMPLATE_REPO}

# Final Build & Lockfile freeze
RUN yarn --production \
    && yarn build \
    && yarn --frozen-lockfile

# Deployment Stage (only target app+modules)
FROM base AS final
ARG APP_PATH

# Replacing the default Node entrypoint
COPY --from=builder /docker-entrypoint.sh /usr/local/bin/entrypoint

USER strapi:strapi

COPY --from=builder --chown=strapi:strapi ${SRC_PATH}/ ${APP_PATH}/

WORKDIR ${APP_PATH}

VOLUME [ "${APP_PATH}/api", "${APP_PATH}/extensions" ]

EXPOSE 1337

ENTRYPOINT [ "entrypoint" ]

CMD [ "start" ]
