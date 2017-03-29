require 'bundler/setup'

Bundler.require(:default)
Bundler.require(Sinatra::Base.environment)
set :cache, ActiveSupport::Cache::MemoryStore.new

require_all 'app'
