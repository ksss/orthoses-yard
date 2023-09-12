# frozen_string_literal: true

require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new do |task|
  task.warning = false
  task.libs = ["lib", "test"]
  task.test_files = FileList["lib/**/*_test.rb"]
end

task :sig do
  require 'orthoses-yard'
  require 'pathname'

  Pathname('sig').rmtree rescue nil
  Orthoses::Builder.new do
    use Orthoses::CreateFileByName,
      base_dir: 'sig',
      header: '# GENERATED FILE'
    use Orthoses::Filter do |name, _|
      name.start_with?('Orthoses::YARD')
    end
    use Orthoses::YARD,
      parse: 'lib/orthoses/**/*.rb'
    run -> {}
  end.call
end

task default: :test
