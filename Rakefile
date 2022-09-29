# frozen_string_literal: true

require "bundler/gem_tasks"
require "rgot/cli"
require 'pathname'

task :test do
  require 'orthoses-yard'

  # build cache
  Orthoses::Utils.rbs_environment(collection: true)

  Orthoses.logger.level = :warn
  Rgot::Cli.new(%w[-v lib]).run
end

task :sig do
  require 'orthoses-yard'

  Pathname('sig').rmtree rescue nil
  Orthoses::Builder.new do
    use Orthoses::CreateFileByName,
      base_dir: 'sig',
      header: '# GENERATED FILE'
    use Orthoses::Filter do |name, _|
      name.start_with?('Orthoses::YARD')
    end
    use Orthoses::YARD,
      globs: 'lib/orthoses/**/*.rb'
    run -> {}
  end.call
end

task default: :test
