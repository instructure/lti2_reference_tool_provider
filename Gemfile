source 'https://rubygems.org'

BUNDLER_VERSION = '1.13.7'.freeze
if Gem::Version.new(Bundler::VERSION) < Gem::Version.new(BUNDLER_VERSION)
  abort "Bundler version >= #{BUNDLER_VERSION} is required"
end

gem 'activesupport'
gem 'httparty'
gem 'json-jwt'
gem 'puma'
gem 'rake'
gem 'require_all'
gem 'simple_oauth', git: 'https://github.com/westonkd/simple_oauth.git'
gem 'sinatra'
gem 'sinatra-activerecord', require: 'sinatra/activerecord'

group :docker do
  gem 'pg'
end

group :test, :development do
  gem 'pry-byebug'
  gem 'rb-readline'
  gem 'rubocop', '~> 0.47.1', require: false
  gem 'sqlite3'
end

group :test do
  gem 'database_cleaner'
  gem 'rack-test'
  gem 'rspec'
end
