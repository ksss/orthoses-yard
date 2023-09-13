# frozen_string_literal: true

require_relative "lib/orthoses/yard/version"

Gem::Specification.new do |spec|
  spec.name = "orthoses-yard"
  spec.version = Orthoses::YARD::VERSION
  spec.authors = ["ksss"]
  spec.email = ["co000ri@gmail.com"]

  spec.summary = "Orthoses extention for YARD."
  spec.description = "Orthoses extention for YARD."
  spec.homepage = "https://github.com/ksss/orthoses-yard"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    [
      %w[CODE_OF_CONDUCT.md LICENSE.txt README.md],
      Dir.glob("lib/**/*.rb").grep_v(/_test\.rb\z/),
      Dir.glob("sig/**/*.rbs")
    ].flatten
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "orthoses", ">= 1.5.0", "< 2.0"
  spec.add_dependency "yard"
end
