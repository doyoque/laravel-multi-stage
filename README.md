# Laravel multi-stage docker

A simply laravel docker multi-stage image build.

## How To?

```bash
cd laravel-multi-stage/
docker build -t <your_image_name>:<additional_tag> .

# Long run multi stage build
# Either run synchronous or asynchronous build
# It simply build composer dependency, build front-end, then put it in the last stages
# As php images.
```

## Run as docker-compose (recommend)

Since this repo is only proivde a single images (and a single PHP services). I highly recommend to run it as docker-compose.

```yml
services:
  nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - 80:80
    volumes:
      - app-volume:/var/www/html
  php:
    image: <your_image_name>:<additional_tags>
    container_name: php
    ports:
      - 9000:9000
    volumes:
      - app-volume:/var/www/html
networks:
  app-network:
    driver: bridge

volumes:
  app-volume:
```