source 'http://rubygems.org'

BUNDLER_VERSION = '1.14.6'.freeze
if Gem::Version.new(Bundler::VERSION) < Gem::Version.new(BUNDLER_VERSION)
  abort "Bundler version >= #{BUNDLER_VERISION} is required"
end

gem 'sinatra'
gem 'activerecord', require: 'active_record'
gem 'sinatra-activerecord', require: 'sinatra/activerecord'
gem 'rake'
gem 'require_all'
gem 'sqlite3'
gem 'httparty'
gem 'simple_oauth', :git => "git://github.com/westonkd/simple_oauth.git"

group :test, :development do
  gem 'rb-readline'
  gem 'pry-byebug'
end

group :test do
  gem 'rack-test'
  gem 'rspec'
  gem 'database_cleaner'
end
