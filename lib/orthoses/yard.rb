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

    def call
      @loader.call.tap do |store|
        require 'yard'

        ::YARD.parse(@parse)
        ::YARD::Registry.root.children.each do |yardoc|
          case yardoc.type
          when :class, :module
            YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
              comment = docstring.each_line.map { |line| "# #{line}" }.join
              if rbs.nil?
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
