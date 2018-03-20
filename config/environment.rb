# frozen_string_literal: true

require 'bundler/setup'

Bundler.require(:default)
Bundler.require(Sinatra::Base.environment)

ActiveRecord::Base.dump_schema_after_migration = false if ENV['RACK_ENV'] == 'production'

set :database_file, ENV['DATABASE_CONFIG'] || 'default_database.yml'

set :cache, ActiveSupport::Cache::MemoryStore.new

require_all 'app'
