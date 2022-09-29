# frozen_string_literal: true
require 'orthoses'
require_relative "yard/version"
require_relative "yard/yard2rbs"

module Orthoses
  # use Orthoses::YARD, globs: "lib/**/*.rb"
  class YARD
    def initialize(loader, globs:)
      @loader = loader
      @globs = Array(globs)
    end

    def call
      @loader.call.tap do |store|
        require 'yard'

        ::YARD.parse(@globs)
        ::YARD::Registry.root.children.each do |yardoc|
          case yardoc.type
          when :class, :module
            YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
              if rbs.nil?
                store[namespace]
              else
                Orthoses.logger.debug("#{namespace} << #{rbs}")
                all = docstring.all.then { |it| it.empty? ? "" : "#{it.gsub(/^/, '# ')}\n" }
                store[namespace] << "#{all}#{rbs}"
              end
            end
          end
        end
      end
    end
  end
end
