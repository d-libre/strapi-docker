ARG STRAPI_VER=3.6.8
FROM node:14-alpine AS builder

#RUN apk add --update --no-cache python3 \
#    && ln -sf python3 /usr/bin/python
ARG STRAPI_VER
ENV VERSION=$STRAPI_VER
ENV LIB_PATH=custom/strapi/generator

RUN npm install -g \
    strapi@${VERSION} \
    lodash

WORKDIR /usr/local/lib/${LIB_PATH}

ADD scripts/* .

# Symlinks for all custom bash scripts to the /usr/local/bin location
RUN /usr/local/lib/${LIB_PATH}/symlink.sh \
    && cp -r /usr/local/lib/node_modules/strapi/node_modules/strapi-generate-new/lib .
    

# /usr/local/lib/node_modules/strapi/node_modules/strapi-generate-new/lib/resources
#RUN strapi new app \
#    --use-npm --debug \
#    --quickstart \
#    --no-run \
#    && npm run-script build

FROM alpine AS join

COPY --from=builder /usr/lib /node/lib
COPY --from=builder /usr/local/share /node/local/share
COPY --from=builder /usr/local/lib /node/local/lib
COPY --from=builder /usr/local/include /node/local/include
COPY --from=builder /usr/local/bin /node/local/bin

FROM alpine AS final
ARG STRAPI_VER
ENV VERSION=$STRAPI_VER
ENV NODE_PATH=/usr/local/lib/node_modules

COPY --from=builder /opt /opt
COPY --from=join /node /usr
# COPY --from=builder /app /app

ENTRYPOINT [ "sh" ]
