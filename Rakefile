# frozen_string_literal: true

begin
  require "rspec/core/rake_task"
  RSpec::Core::RakeTask.new(:spec)
  task default: :spec
#rescue LoadError
  # If rspec isn't installed yet, keep a build fallback:
#  task default: :build
end
