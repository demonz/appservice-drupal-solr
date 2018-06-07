./build.sh

# import variables
REGISTRY=demonz
NAME=appservice-drupal-solr
VERSION=7.x-5.5

set -ex
docker push ${REGISTRY}/${NAME}:${VERSION}
