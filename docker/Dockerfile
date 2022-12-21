ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION-alpine

RUN apk add --update --no-cache \
    make \
    gcc \
    libc-dev

# setup non ruby user
ARG DOCKER_UID
ARG DOCKER_GID
ARG USER=ruby
ENV DOCKER_UID $DOCKER_UID
ENV DOCKER_GID $DOCKER_GID
ENV USER $USER
ENV LIB_PATH /home/ruby/lib

RUN addgroup -g $DOCKER_GID $USER \
  && adduser -D -u $DOCKER_UID -G $USER $USER

# Setup bundle:
ENV BUNDLE_PATH /gems
ENV BUNDLE_HOME /gems
ENV GEM_HOME /gems
ENV GEM_PATH /gems
ENV PATH /gems/bin:$PATH

RUN mkdir -p $GEM_HOME && mkdir -p $LIB_PATH \
  && chown $USER:$USER $GEM_HOME \
  && chown $USER:$USER $LIB_PATH \
  && gem update --system \
  && gem install bundler

WORKDIR $LIB_PATH
USER $USER

COPY --chown=ruby:ruby /docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]