# frozen_string_literal: true
require 'orthoses'
require_relative "yard/version"
require_relative "yard/yard2rbs"

module Orthoses
  # use Orthoses::YARD, parse: "lib/**/*.rb"
  class YARD
    def initialize(loader, parse:)
      @loader = loader
      @parse = Array(parse)
    end

    # @return [void]
    def call
      @loader.call.tap do |store|
        require 'yard'

        ::YARD.parse(@parse)
        ::YARD::Registry.root.children.each do |yardoc|
          # Skip anonymous yardoc
          next unless yardoc.file

          # Skip external doc (e.g. pry-doc)
          next unless @parse.any? { |pattern| File.fnmatch(pattern, yardoc.file) }

          case yardoc.type
          when :class, :module
            YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
              comment = docstring.each_line.map { |line| "# #{line}" }.join
              if rbs.nil? && comment && !store.has_key?(namespace)
                store[namespace].comment = comment
              else
                Orthoses.logger.debug("#{namespace} << #{rbs}")
                store[namespace] << "#{comment}\n#{rbs}"
              end
            end
          end
        end
      end
    end
  end
end
