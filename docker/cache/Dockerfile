ARG NODE_BASE=14-alpine
ARG VERSION=3.6.8
# Final target path
ARG APP_PATH=/srv/app
ARG BIN_PATH=/srv/bin
ARG LIB_NAME=boostrapi

# -----| base |-----
# Shared stage/base image
FROM node:${NODE_BASE} AS build
ARG VERSION
ARG APP_PATH
ARG BIN_PATH
ARG LIB_NAME
ENV LIB_PATH /usr/local/lib/${LIB_NAME}

# Globally Install Strapi + node-gyp package
RUN npm install -g \
        strapi@${VERSION} \
        node-gyp

# Build/Install Boostrapi tools
ADD assets/generator/ ${LIB_PATH}/

WORKDIR ${LIB_PATH}

# TODO: Extract/Copy directly from package
RUN cp -r /usr/local/lib/node_modules/strapi/node_modules/strapi-generate-new/lib/*/ .

RUN npm install . 

WORKDIR ${APP_PATH}

# Generate & Build a new Strapi app (from scratch)
RUN DOCKER=true strapi new . \
    --quickstart \
    --use-npm \
    --debug \
    --no-run

# Using boostrapi tool to directly
# inject configurations for all db clients
RUN ${LIB_PATH}/set-db-dependencies.js

# Install dependencies
RUN yarn install --production

# Build final output files
RUN yarn build

WORKDIR ${BIN_PATH}

RUN mv ${APP_PATH}/build ${APP_PATH}/node_modules .


FROM busybox:1.35 AS cache

ARG APP_PATH
ARG BIN_PATH

ARG LIB=/usr/local/lib/node_modules
ARG BIN=/usr/local/bin

COPY --from=build ${LIB}/strapi/    ${LIB}/strapi/
COPY --from=build ${LIB}/node-gyp/  ${LIB}/node-gyp

RUN mkdir -p ${BIN} \
    && for lib in strapi node-gyp; do { ln -s ../lib/node_modules/${lib}/bin/${lib}.js ${BIN}/${lib}; } done

COPY --from=build ${APP_PATH}/      ${APP_PATH}/
COPY --from=build ${BIN_PATH}/      ${BIN_PATH}/

WORKDIR /srv
ENTRYPOINT sh
