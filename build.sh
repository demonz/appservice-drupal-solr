#!/usr/bin/env bash
set -x -e


# import variables
REGISTRY=nbcwebcontainers.azurecr.io
NAME=appservice-drupal-solr
VERSION=7.x-5.5


docker build \
  --build-arg SOLR_VER=5.5 --build-arg SEARCH_API_SOLR_VER=7.x-1.12 \
  -t "${REGISTRY}/${NAME}:${VERSION}" -t "${REGISTRY}/${NAME}:latest" \
  .

