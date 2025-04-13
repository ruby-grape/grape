ARG RUBY_VERSION=3
FROM ruby:${RUBY_VERSION}-alpine

ENV BUNDLE_PATH /usr/local/bundle/gems
ENV LIB_PATH /var/grape
ENV RUBYOPT --enable-frozen-string-literal --yjit
ENV LD_PRELOAD libjemalloc.so.2
ENV MALLOC_CONF dirty_decay_ms:1000,narenas:2,background_thread:true

RUN apk add --update --no-cache make gcc git libc-dev yaml-dev gcompat jemalloc && \
    gem update --system && gem install bundler

WORKDIR $LIB_PATH

COPY /docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
