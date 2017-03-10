# LTI 2.1 Reference Tool Provider
An LTI tool provider intended to be used as a reference for implementing the IMS LTI 2.1 specification. Section numbers in the comments (i.e. “6.1.2”) refer to sections of the IMS LTI 2.1 specification.

## Setup
1. Install [Sinatra](https://github.com/sinatra/sinatra)
2. `bundle install`
3. `bundle exec rake db:create`
4. `bundle exec rake db:migrate`
5. `bundle exec rackup`

## Running Tests
1. `bundle exec rake db:migrate RACK_ENV=test`
2. `bundle exec rspec <path/to/spec>`
