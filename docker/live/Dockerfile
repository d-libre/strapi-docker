ARG STRAPI_BASE_TAG=v3.6.8-n14

# -----| Base |-----
# Shared stage/base image
FROM libre/strapi:${STRAPI_BASE_TAG} AS base

ARG STRAPI_BASE_TAG

LABEL org.opencontainers.image.title="Strapi Live Image" \
      org.opencontainers.image.version="${STRAPI_BASE_TAG}"

LABEL org.opencontainers.image.source=https://github.com/d-libre/strapi-docker/blob/main/docker/live/Dockerfile

LABEL org.opencontainers.image.base.name=docker.io/libre/strapi-base:${STRAPI_BASE_TAG}


# ---| Cache |---
# Pre-build cache
FROM libre/strapi-cache:${STRAPI_BASE_TAG} AS cache


# -----| Live |-----
# Final Deployment Stage (only target app+modules)
FROM base AS live

# Get Generated/Pre-Built Strapi app (from Cache)
# with all db dependencies included already
COPY --from=cache --chown=strapi:strapi ${APP_PATH}/    ${APP_PATH}/
COPY --from=cache --chown=strapi:strapi /srv/bin/       ${APP_PATH}/

VOLUME [ \
    "${APP_PATH}/api" \
    "${APP_PATH}/extensions" \
    "${APP_PATH}/public" \
]

EXPOSE 1337

HEALTHCHECK CMD curl -I 0.0.0.0:1337/_health || exit 1 \
    --interval=36s \
    --timeout=6s \
    --start-period=6s \
    --retries=3

CMD [ "develop" ]
