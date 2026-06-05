#
# conductor:ui - Conductor UI
# Multi-stage build: React static bundle served by nginx.
# Runtime env vars:
#   WF_SERVER  - Conductor server base URL (default: http://localhost:8080)
#   PORT       - Port nginx listens on      (default: 5000)
#

# ── Stage 1: build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder
LABEL maintainer="Orkes OSS <oss@orkes.io>"

RUN apk update && apk add --no-cache python3 py3-pip make g++

WORKDIR /usr/src/app

COPY ./ui/package.json ./
# Install deps; explicitly add @types/react* so TypeScript finds them at the
# top-level node_modules (yarn 1.x doesn't always hoist them from react-scripts)
RUN yarn install \
    && yarn add --dev @types/react@^18 @types/react-dom@^18 \
    && mkdir -p public && cp -r node_modules/monaco-editor public/

COPY ./ui .

# Remove playwright component-test files — they conflict with CRA's TS compilation
RUN find . -name "*.test.pw.tsx" -o -name "*.test.pw.ts" | xargs rm -f

# Bundle monaco locally so the image works without CDN access
ENV REACT_APP_MONACO_EDITOR_USING_CDN=false
ENV REACT_APP_ENABLE_ERRORS_INSPECTOR=true
RUN yarn build

# ── Stage 2: serve ───────────────────────────────────────────────────────────
FROM nginx:1.27-alpine

# CVE-2026-31789: upgrade OpenSSL to 3.3.7+
# CVE-2025-48174: libavif <1.3.0 (not yet in Alpine repos); remove the only
#   dependent chain nginx-module-image-filter → libgd → libavif since the
#   conductor UI does not use nginx image filtering.
RUN apk update \
    && apk upgrade --no-cache \
    && apk del --no-cache nginx-module-image-filter \
    && rm -rf /var/cache/apk/*

# Copy React build output
COPY --from=builder /usr/src/app/build /usr/share/nginx/html

# Nginx config template (WF_SERVER and PORT substituted at startup)
COPY docker/ui/nginx.conf.template /etc/nginx/conf.d/default.conf.template

# Entrypoint runs envsubst then starts nginx
COPY docker/ui/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 5000

ENTRYPOINT ["/entrypoint.sh"]
