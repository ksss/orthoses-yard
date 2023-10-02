# frozen_string_literal: true
require 'orthoses'
require_relative "yard/version"
require_relative "yard/yard2rbs"

module Orthoses
  # use Orthoses::YARD, parse: "lib/**/*.rb"
  class YARD
    # @param loader
    # @param [<String>, String] parse Target files
    # @param [Boolean] use_cache Use cache .yardoc
    # @param [Symbol, nil] log_level Set YARD log level
    # @param [Boolean] allow_empty_doc Generate RBS also from empty doc
    def initialize(loader, parse:, use_cache: true, log_level: nil, allow_empty_doc: false)
      @loader = loader
      @parse = Array(parse)
      @use_cache = use_cache
      @log_level = log_level
      @allow_empty_doc = allow_empty_doc
    end

    # @return [void]
    def call
      @loader.call.tap do |store|
        require 'yard'

        log.level = @log_level if @log_level

        ::YARD::Registry.load if @use_cache
        ::YARD.parse(@parse)
        ::YARD::Registry.save(true) if @use_cache
        ::YARD::Registry.root.children.each do |yardoc|
          # Skip anonymous yardoc
          next unless yardoc.file

          # Skip external doc (e.g. pry-doc)
          next unless @parse.any? { |pattern| File.fnmatch(pattern, yardoc.file, File::FNM_EXTGLOB | File::FNM_PATHNAME) }

          case yardoc.type
          when :class, :module
            YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs, skippable|
              next if skippable && !@allow_empty_doc
              comment = docstring.empty? ? '' : "# #{docstring.gsub("\n", "\n# ")}"
              if rbs.nil? && comment && !store.has_key?(namespace)
                store[namespace].comment = comment
              else
                Orthoses.logger.debug("#{namespace} << #{rbs}")
                store[namespace] << "#{comment.chomp}\n#{rbs}"
              end
            end
          end
        end
      end
    end
  end
end
