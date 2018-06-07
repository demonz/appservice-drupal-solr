#!/usr/bin/env bash
set -x -e


# import variables
REGISTRY=demonz
NAME=appservice-drupal-solr
VERSION=7.x-5.5

SOLR_VERSION=5.5
SEARCH_API_SOLR_VERSION=7.x-1.12

docker pull solr:${SOLR_VERSION}-alpine


docker build \
  --build-arg SOLR_VER=${SOLR_VERSION} --build-arg SEARCH_API_SOLR_VER=${SEARCH_API_SOLR_VERSION} \
  -t "${REGISTRY}/${NAME}:${VERSION}" -t "${REGISTRY}/${NAME}:latest" \
  .
