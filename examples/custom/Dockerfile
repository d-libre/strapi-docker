ARG STRAPI_VER=3.6.8
ARG LIB_NAME=boostrapi
ARG USR_PATH=/usr/local/lib/docker/
ARG APP_PATH=/src/app/
ARG CFG_PATH=/var/local/strapi/configs/

FROM node:14-alpine AS clean
LABEL maintainer="SalvadorCodes <hector@salvador.codes>"

FROM clean AS builder

ARG STRAPI_VER
ARG LIB_NAME
ARG USR_PATH
ARG APP_PATH
ARG CFG_PATH

ENV VERSION=$STRAPI_VER
ENV LIB_PATH=$USR_PATH$LIB_NAME/

RUN apk add --no-cache jq \
    && npm install -g \
        strapi@${VERSION} \
        node-gyp

WORKDIR ${APP_PATH}

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

WORKDIR ${APP_PATH}

RUN yarn --production \
    && yarn build


FROM clean AS final

ARG STRAPI_VER
ARG USR_PATH
ARG CFG_PATH

ENV VERSION $STRAPI_VER
ENV DB_CONFIGS_PATH $CFG_PATH
ENV APP_PATH /srv/app/

COPY --from=builder /src/app ${APP_PATH}
COPY --from=builder ${USR_PATH} ${USR_PATH}
COPY --from=builder ${CFG_PATH} ${CFG_PATH}

ADD docker-entrypoint.sh ${USR_PATH}entrypoint.sh

RUN apk add --no-cache bash jq \
    && ${USR_PATH}utils/symlink.sh ${USR_PATH} sh \
    && rm /usr/local/bin/docker-entrypoint.sh

WORKDIR ${APP_PATH}

VOLUME [ "${APP_PATH}/api", "${APP_PATH}/extensions" ]

EXPOSE 1337

ENTRYPOINT [ "entrypoint" ]

CMD [ "develop" ]
