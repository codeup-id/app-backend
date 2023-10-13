ARG NODE_VERSION=18-alpine

FROM node:${NODE_VERSION} as base_builder

ARG TARGETPLATFORM

RUN \
  if [ "$TARGETPLATFORM" = 'linux/arm64' ]; then \
  apk --no-cache add \
  python3 \
  build-base \
  && ln -sf /usr/bin/python3 /usr/bin/python \
  ; fi

FROM base_builder as builder
WORKDIR /app
COPY /dist .
RUN npm install
RUN rm *.tgz

FROM node:${NODE_VERSION}

# Default environment variables
# (see https://docs.directus.io/reference/environment-variables/)
ENV \
  PORT=80 \
  EXTENSIONS_PATH="/app/extensions" \
  STORAGE_LOCAL_ROOT="/app/uploads"

RUN \
  # Upgrade system and install 'ssmtp' to be able to send mails
  apk upgrade --no-cache && apk add --no-cache \
  ssmtp \
  # Add support for specifying the timezone of the container
  # using the "TZ" environment variable.
  tzdata \
  # Create directory for Directus with corresponding ownership
  # (can be omitted on newer Docker versions since WORKDIR below will do the same)
  && mkdir /app && chown node:node /app

# Switch to user 'node' and directory '/app'
USER node
WORKDIR /app

# disable npm update warnings
RUN echo "update-notifier=false" >> ~/.npmrc

COPY --from=builder --chown=node:node /app .

RUN \
  # Create data directories
  mkdir -p \
    extensions \
    uploads

# Expose data directories as volumes
# VOLUME \
#   /app/extensions \
#   /app/uploads

EXPOSE 80
CMD npx directus bootstrap && npx directus start
