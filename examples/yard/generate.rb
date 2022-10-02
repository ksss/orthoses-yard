require 'orthoses-yard'
require 'fileutils'
require 'pathname'

FileUtils.rm_rf('out')
Orthoses.logger.level = :warn
Orthoses::Builder.new do
  use Orthoses::CreateFileByName,
    base_dir: 'out'
  use Orthoses::Filter do |name, content|
    name.start_with?('YARD') ||
      name.start_with?('Ripper') ||
      name.start_with?('OpenStruct') ||
      name.start_with?('SymbolHash') ||
      name.start_with?('Rake') ||
      name.start_with?('WEBrick') ||
      name.start_with?('RDoc')
  end
  use Orthoses::Tap do |store|
    store['YARD'].header = 'module YARD'
    store['YARD::CodeObjects'].header = 'module YARD::CodeObjects'
    store['YARD::Handlers'].header = 'module YARD::Handlers'
    store['YARD::Handlers::C'].header = 'module YARD::Handlers::C'
    store['YARD::Handlers::Common'].header = 'module YARD::Handlers::Common'
    store['YARD::Handlers::Ruby'].header = 'module YARD::Handlers::Ruby'
    # TODO: support generics
    store['YARD::Tags::Library'] << 'def self.labels: () -> SymbolHash'

    # FIXME: YARD's issue?
    store['YARD::CLI::YardocOptions'].delete("# @return [Numeric] An index value for rendering sequentially related templates\nattr_accessor index: Numeric")
  end
  use Orthoses::YARD,
    parse: [
      'src/lib/yard.rb',
      'src/lib/yard/**/*.rb'
    ]
  use Orthoses::Autoload
  run -> {
    require 'yard'
    YARD::Tags::Library.define_tag("YARD Tag Signature", 'yard.signature'.to_sym, nil)
    YARD::Tags::Library.define_tag("YARD Tag", 'yard.tag'.to_sym, :with_types_and_name)
    YARD::Tags::Library.define_tag("YARD Directive", 'yard.directive'.to_sym, :with_types_and_name)
    # YARD::Tags::Library.visible_tags -= ['yard.tag'].map(&:to_sym)
  }
end.call

out = Pathname("out")
out.join("EXTERNAL_TODO.rbs").write(<<RBS)
  # !!! GENERATED CODE !!!
  class OpenStruct
  end

  class Ripper
  end

  module Rake
    class TaskLib
    end
  end


  module WEBrick
    module HTTPServlet
      class AbstractServlet
      end
    end
  end

  module RDoc
    module Markup
      class ToHtml
      end
    end
  end
RBS

out.join("manifest.yaml").write(<<~YAML)
dependencies:
  - name: rubygems
  - name: set
  - name: optparse
  - name: logger
  - name: monitor
YAML

out.join('_scripts').tap(&:mkpath).join("test").write(<<~SHELL)
#!/usr/bin/env bash

# Exit command with non-zero status code, Output logs of every command executed, Treat unset variables as an error when substituting.
set -eou pipefail
# Internal Field Separator - Linux shell variable
IFS=$'
	'
# Print shell input lines
set -v

# Set RBS_DIR variable to change directory to execute type checks using `steep check`
RBS_DIR=$(cd $(dirname $0)/..; pwd)
# Set REPO_DIR variable to validate RBS files added to the corresponding folder
REPO_DIR=$(cd $(dirname $0)/../../..; pwd)
# Validate RBS files, using the bundler environment present
bundle exec rbs --repo $REPO_DIR -r yard:0.9 -r rubygems -r set -r optparse -r logger -r monitor -r rack:2.2.2 validate --silent

cd ${RBS_DIR}/_test
# Run type checks
bundle exec steep check
SHELL

out.join('_test').tap(&:mkpath).join("yard.rb").write(<<~RUBY)
require 'yard'

YARD::Registry.root.children.each do |child|
  child.name(false)
  child.docstring.all
end
RUBY

out.join('_test').join('Steepfile').write(<<~RUBY)
D = Steep::Diagnostic

target :test do
  check "."
  signature '.'

  repo_path "../../../"

  library "rubygems"
  library "set"
  library "optparse"
  library "logger"
  library "monitor"

  library "yard:0.9"
  library "rack:2.2.2"

  configure_code_diagnostics(D::Ruby.all_error)
end
RUBY
