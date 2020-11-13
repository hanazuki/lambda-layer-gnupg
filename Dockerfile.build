# syntax=docker/dockerfile:experimental

ARG base
FROM amazon/aws-sam-cli-build-image-${base}

WORKDIR /tmp/src
ADD Gemfile Gemfile.lock ./
RUN bundle --deployment
ADD Rakefile versions.yaml ./
RUN --mount=type=cache,target=/opt/archives bundle exec rake build
RUN --mount=type=cache,target=/opt/archives,ro bundle exec rake package
