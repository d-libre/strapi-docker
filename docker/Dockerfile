ARG NODE_BASE=14-alpine
ARG STRAPI_VER=3.6.8
# Final target path
ARG APP_PATH=/srv/app/
ARG SRC_PATH=/src
ARG LIB_NAME=boostrapi
ARG USR_PATH=/usr/local/lib/docker/
ARG CFG_PATH=/var/local/strapi/configs/
# The custom User/Group Id
ARG UID=1000

# -----| base |-----
# Shared stage/base image
FROM node:${NODE_BASE} AS base
LABEL maintainer="SalvadorCodes <hector@salvador.codes>"

ARG UID
ARG SRC_PATH
ARG USR_PATH
ARG CFG_PATH
ARG STRAPI_VER

# Make Strapi Version available to both install scripts & containers
ENV VERSION $STRAPI_VER

# Install Bash, Curl & jq for both builder and final
# Also remove the "node" user:group pair
# and create the new ones to run strapi
RUN apk add --no-cache bash curl jq \
    && deluser --remove-home node \
    && addgroup -g ${UID} -S strapi \
    && adduser -h /home/strapi -u ${UID} -G strapi -D strapi


# -----| builder |-----
# Building stage
FROM base AS builder

ARG LIB_NAME

ENV LIB_PATH=$USR_PATH$LIB_NAME/

RUN npm install -g \
        strapi@${VERSION} \
        node-gyp

WORKDIR ${SRC_PATH}

# Generate & Build a new Strapi app (from scratch)
RUN DOCKER=true strapi new . \
    --quickstart \
    --use-npm \
    --debug \
    --no-run

WORKDIR /assets
ADD assets .

# Copy & Symlinks for all custom bash scripts to the /usr/local/bin location
RUN mkdir -p ${LIB_PATH} \
    && cp -r utils ${USR_PATH} \
    && utils/symlink.sh ${USR_PATH} sh \
    && cp -r generator/* ${LIB_PATH} \
    && utils/symlink.sh ${LIB_PATH} js

WORKDIR ${LIB_PATH}

# TODO: Extract/Copy directly from package
RUN cp -r /usr/local/lib/node_modules/strapi/node_modules/strapi-generate-new/lib . \
    && npm install . \
    && mkdir -p ${CFG_PATH} \
    && generate-db-configs ${CFG_PATH} \
    && inject-all-db-clients \
    && rm -rf ${USR_PATH}${LIB_NAME%%/*}

WORKDIR ${SRC_PATH}

# Final Build
RUN yarn --production \
    && yarn build


# -----| final |-----
# Deployment Stage (only target app+modules)
FROM base AS final
ARG APP_PATH

ENV APP_PATH $APP_PATH
ENV DB_CONFIGS_PATH $CFG_PATH

COPY --from=builder --chown=strapi:strapi ${SRC_PATH} ${APP_PATH}
COPY --from=builder ${USR_PATH} ${USR_PATH}
COPY --from=builder ${CFG_PATH} ${CFG_PATH}
ADD docker-entrypoint.sh ${USR_PATH}entrypoint.sh

RUN ${USR_PATH}utils/symlink.sh ${USR_PATH} sh \
    && rm /usr/local/bin/docker-entrypoint.sh

USER strapi:strapi

WORKDIR ${APP_PATH}

VOLUME [ "${APP_PATH}/api", "${APP_PATH}/extensions" ]

EXPOSE 1337

HEALTHCHECK CMD curl -I 0.0.0.0:1337/_health || exit 1 \
    --interval=36s \
    --timeout=6s \
    --start-period=6s \
    --retries=3

ENTRYPOINT [ "entrypoint" ]

CMD [ "develop" ]
