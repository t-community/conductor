#!/bin/sh
set -e

export WF_SERVER="${WF_SERVER:-http://localhost:8080}"
export PORT="${PORT:-5000}"

# Substitute only our variables, leaving nginx $variables intact
envsubst '${WF_SERVER} ${PORT}' \
  < /etc/nginx/conf.d/default.conf.template \
  > /etc/nginx/conf.d/default.conf

exec nginx -g 'daemon off;'
