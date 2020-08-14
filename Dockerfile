ARG base
FROM lambci/lambda:build-${base}

WORKDIR /tmp/src
ADD Gemfile Gemfile.lock ./
RUN bundle --deployment
ADD gnupg.asc Rakefile versions.json ./
RUN bundle exec rake fetch
RUN bundle exec rake build
RUN bundle exec rake package
