FROM lambci/lambda:build-ruby2.5

WORKDIR /tmp/src
ADD docker/Gemfile docker/Gemfile.lock ./
RUN bundle --deployment
ADD docker/gnupg.asc docker/Rakefile ./
RUN bundle exec rake fetch
RUN bundle exec rake build
