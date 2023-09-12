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

  Orthoses::Builder.new do
    use Orthoses::CreateFileByName,
      depth: 1,
      to: 'sig',
      header: '# GENERATED FILE',
      rmtree: true
    use Orthoses::Filter do |name, _|
      name.start_with?('Orthoses::YARD')
    end
    use Orthoses::YARD,
      parse: Dir.glob("lib/**/*.rb").grep_v(/_test\.rb\z/)
    run -> {}
  end.call
end

task default: [:test, :sig]
