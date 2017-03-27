FROM ruby:2.4
MAINTAINER Instructure

RUN useradd -r -U docker
ENV RACK_ENV "production"
# Install postgres
RUN apt-get update && apt-get install -y \
    postgresql-client && rm -rf /var/lib/apt/lists/*

# Install app
WORKDIR /usr/src/app
COPY Gemfile* ./
RUN bundle install --jobs=8 --quiet --without development test
COPY . .

RUN chown -R docker:docker $APP_HOME /usr/local/bundle

USER docker
