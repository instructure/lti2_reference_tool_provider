require_relative './config/environment'
require 'sinatra/activerecord/rake'

environment = Sinatra::Base.environment

puts '####################'
puts environment
puts '####################'
if %w(test development).include? environment
  require 'rspec/core/rake_task' if environment == 'test'
  require 'rubocop/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  RuboCop::RakeTask.new(:rubocop) do |t|
    t.options = %w(--force-exclusion)
  end
  # Run tests
  task default: :spec
end
