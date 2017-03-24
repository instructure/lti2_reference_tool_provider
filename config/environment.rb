require 'bundler/setup'

Bundler.require(:default)
Bundler.require(Sinatra::Base.environment)

set :database_file, ENV["DATABASE_CONFIG"] || "default_database.yml"

require_all 'app'
