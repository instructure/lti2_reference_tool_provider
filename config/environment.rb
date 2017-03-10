require 'bundler/setup'

Bundler.require(:default)
Bundler.require(Sinatra::Base.environment)

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: 'db/tp.sqlite3'
)

require_all 'app'
