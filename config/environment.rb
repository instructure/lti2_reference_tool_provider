require 'bundler/setup'

Bundler.require(:default)
Bundler.require(Sinatra::Base.environment)

require_all 'app'
