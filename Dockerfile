FROM ruby:2.4
MAINTAINER Instructure

ENV RACK_ENV "production"
# Install postgres
RUN apt-get update && apt-get install -y \
    postgresql-client

# Install app
WORKDIR /usr/src/app
ADD Gemfile /usr/src/Gemfile
ADD Gemfile.lock /usr/src/Gemfile.lock
RUN bundle install --without development test
RUN mkdir tmp
ADD . /usr/src/app

# Clean up APT and bundler when done.
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Run app
CMD bundle exec rackup