# Solr for Drupal Docker Container Image

* Base image: Docker official solr:5.5-alpine
* [Docker Hub](https://hub.docker.com/_/solr)

Supported tags and respective `Dockerfile` links:

* `7.x-5.5`, `latest` [_(Dockerfile)_](./Dockerfile)


## Building an image based on this repository

    git clone git@github.com:demonz/appservice-dupal-solr.git
    cd appservice-drupal-solr
    ./build.sh


## Environment Variables

| Variable                                   | Default Value              | Description                      |
| ------------------------------------------ | -------------------------- | -------------------------------- |
| `SOLR_HEAP           `                     |                            | REQUIRED                         |


## Orchestration Actions

### Initialise a default core

    docker-compose up -d
    docker-compose exec solr /usr/local/bin/init_solr localhost