# https://hub.docker.com/_/alpine/
FROM alpine:3.9

LABEL maintainer="andrew.cooper@novatechweb.com"

RUN apk update \
 && apk upgrade \
 && apk add --no-cache \
            rsync \
 && rm -rf /var/cache/apk/*
