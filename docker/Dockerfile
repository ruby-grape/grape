ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION-alpine

ENV BUNDLE_PATH /usr/local/bundle/gems
ENV LIB_PATH /var/grape

RUN apk add --update --no-cache make gcc git libc-dev gcompat && \
    gem update --system && gem install bundler

WORKDIR $LIB_PATH

COPY /docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
