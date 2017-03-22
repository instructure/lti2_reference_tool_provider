require_relative './config/environment'
require 'sinatra/activerecord/rake'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = %w(--force-exclusion)
end

# Run tests
task default: :spec
