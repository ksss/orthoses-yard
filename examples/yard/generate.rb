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

Pathname("out").join("EXTERNAL_TODO.rbs").write(<<~RBS)
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
