ARG RUBY_VERSION=4
FROM ruby:${RUBY_VERSION}-slim

ENV BUNDLE_PATH /usr/local/bundle/gems
ENV LIB_PATH /var/grape

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential curl git pkg-config libyaml-dev libjemalloc2 && \
    gem update --system && gem install bundler

ENV LD_PRELOAD libjemalloc.so.2
ENV MALLOC_CONF dirty_decay_ms:1000,narenas:2,background_thread:true
ENV RUBYOPT --enable-frozen-string-literal --yjit

WORKDIR $LIB_PATH

COPY /docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
