#!/bin/bash

echo "Rebuilding PREPROD reverse proxy..."

docker compose \
  -p dba-preprod \
  --env-file env/preprod.env \
  -f docker-compose.proxy.yml \
  up -d --force-recreate --build reverse-proxy

echo "Done. Current proxy container:"
docker ps | grep dba-preprod-reverse-proxy

