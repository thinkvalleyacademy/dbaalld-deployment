#!/bin/bash

docker compose \
  -p dba-dev \
  --env-file env/dev.env \
  -f docker-compose.proxy.yml \
  up -d --force-recreate --build reverse-proxy

docker ps | grep reverse-proxy

