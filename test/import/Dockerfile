FROM libre/gget AS source

ADD test/import/token.key /run/secrets/github_token
ADD docker/assets/utils/import-strapi.sh /usr/local/bin/import-strapi

RUN import-strapi salvatorius/test \
    --secret github_token \
    --output /var/files \
    --no-merge

RUN echo "Imported Files in /var/files/template:" \
    && ls -la /var/files/template


FROM node:14-alpine AS import

ENV VERSION 3.6.8

RUN apk add --no-cache bash curl jq

COPY --from=source /usr/local /usr/local
COPY --from=source /var/files /src

WORKDIR /srv/app
ADD test/import/package.ini package.json

# Files confirmed in /src (from the previous stage)
RUN [[ -d /src/template/api/article ]] || { echo "Not in src!!"; exit 9; }

RUN import-strapi --from /src

# Smoke Tests
RUN [[ -f package.json ]] \
    && [[ -d api/article ]] \
    && [[ -d components/shared ]] \
    && [[ -d data/uploads ]] \
    && [[ ! -d extra/data ]] \
    || { echo "Directory structure does not match the criteria"; ls -la; exit 10; }
