# syntax=docker/dockerfile:experimental

ARG base
FROM lambci/lambda:build-${base}

WORKDIR /tmp/src
ADD Gemfile Gemfile.lock ./
RUN bundle --deployment
ADD gnupg.asc Rakefile versions.json ./
RUN --mount=type=cache,target=/opt/archives bundle exec rake build
RUN --mount=type=cache,target=/opt/archives,ro bundle exec rake package
