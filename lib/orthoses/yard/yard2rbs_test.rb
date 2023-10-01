require 'test_helper'

module YARD2RBSTest
  ::YARD::Registry.clear
  ::YARD.parse(__FILE__)

  def class_instance(name, args = [])
    ::RBS::Types::ClassInstance.new(name: name, args: [], location: nil)
  end

  def test_primitive_type(t)
    yardoc = ::YARD::CodeObjects::ClassObject.new(:root, :Test)
    g = Orthoses::YARD::YARD2RBS.new(yardoc: yardoc, block: ->(){})
    [
      [["123"], "123"],
      [["String"], "String"],
      [["Boolean"], "bool"],
      [["true"], "bool"],
      [["TrueClass"], "bool"],
      [["false"], "bool"],
      [["FalseClass"], "bool"],
      [["true", "false"], "bool"],
      [["TrueClass", "FalseClass"], "bool"],
      [["void"], "void"],
      [["self"], "self"],
      [["Object"], "untyped"],
      [["nil"], "nil"],
      [["nil", "nil"], "nil"],
      [["NilClass"], "nil"],
      [["Object", "nil"], "untyped"],
      [["String", "nil"], "String?"],
      [["String", "Symbol"], "String | Symbol"],
      [["Array"], "Array[untyped]"],
      [["Array<Symbol>"], "Array[Symbol]"],
      [["Array<Symbol, String>"], "Array[Symbol | String]"],
      [["Array(Symbol)"], "[Symbol]"],
      [["Array<Array<Symbol>>"], "Array[Array[Symbol]]"],
      [["Array(Array(Symbol))"], "[[Symbol]]"],
      [["Hash"], "Hash[untyped, untyped]"],
      [["Hash{Symbol => String}"], "Hash[Symbol, String]"],
      [["_aaa"], "untyped"]
    ].each do |tags, type|
      actual = g.tag_types_to_rbs_type(tags)
      expect = ::RBS::Parser.parse_type(type)
      unless expect == actual
        t.error("expect #{tags} convert \"#{type}\", but got \"#{actual}\"")
      end
    end
  end

  class NoTagsInitialize
    def initialize(a)
    end
  end

  def test_not_tags_initialize(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::NoTagsInitialize')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    unless res.empty?
      t.error("No tags initailize should not generate RBS")
    end
  end

  class WithParamInitialize
    # @param [String] a
    def initialize(a)
    end
  end

  def test_with_param_initialize(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::WithParamInitialize')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    expect = [[
      "YARD2RBSTest::WithParamInitialize",
      "@param [String] a",
      "def initialize: (String a) -> void"
    ]]
    unless res == expect
      t.error("expect #{expect}. But not")
    end
  end

  module Methods
    # @yieldparam [String] a
    # @yieldreturn [String]
    def foo
    end

    # @param [String] a
    # @return [void]
    def bar(a)
    end

    # @param [String] a
    # @yieldparam [String]
    # @yieldreturn [String]
    # @return [void]
    def baz(a)
    end

    #
    # @yieldreturn [String]
    #
    def qux
    end

    # @param [List<String>] a
    # @param [Array<String>] b
    # @return [Hash<String>]
    def collection_type(a, b)
    end

    def no_doc_method
    end
  end

  def test_method(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::Methods')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    expect = [
      "YARD2RBSTest::Methods",
      "@yieldparam [String] a\n@yieldreturn [String]",
      "def foo: () { (String a) -> String } -> untyped"
    ]
    actual = res[0]
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = [
      "YARD2RBSTest::Methods",
      "@param [String] a\n@return [void]",
      "def bar: (String a) -> void"
    ]
    actual = res[1]
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = [
      "YARD2RBSTest::Methods",
      "@param [String] a\n@yieldparam [String]\n@yieldreturn [String]\n@return [void]",
      "def baz: (String a) { (String) -> String } -> void"
    ]
    actual = res[2]
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = [
      "YARD2RBSTest::Methods",
      "\n@yieldreturn [String]\n",
      "def qux: () { () -> String } -> untyped"
    ]
    actual = res[3]
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = [
      "YARD2RBSTest::Methods",
      "@param [List<String>] a\n@param [Array<String>] b\n@return [Hash<String>]",
      "def collection_type: (List[String] a, Array[String] b) -> Hash[untyped, untyped]"
    ]
    actual = res[4]
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end

  module Attributes
    # @return [Integer]
    attr_accessor :a

    attr_reader :no_return_reader
    attr_writer :no_return_writer
    attr_accessor :no_return_accessor

    class << self
      # @return [Integer]
      attr_reader :r

      private

      # @return [Integer]
      attr_writer :w
    end
  end

  def test_attribute(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::Attributes')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    unless res.length == 3
      return t.error("unexpected singnatures")
    end

    expect = ["YARD2RBSTest::Attributes", "@return [Integer]", "attr_reader self.r: Integer"]
    actual = res[0]
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = ["YARD2RBSTest::Attributes", "@return [Integer]", "private attr_writer self.w: Integer"]
    actual = res[1]
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = ["YARD2RBSTest::Attributes", "@return [Integer]", "attr_accessor a: Integer"]
    actual = res[2]
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end

  module Const
    # @return [Integer]
    CONST = 1

    NO_RETURN = 2
  end

  def test_const(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::Const')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    unless res.length == 1
      return t.error("unexpected singnatures")
    end

    expect = ["YARD2RBSTest::Const", "@return [Integer]", "CONST: Integer"]
    actual = res[0]
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end

  module ClassVariable
    # @return [Integer]
    @@classvariable = 1

    @@no_return = 2
  end

  def test_classvariable(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::ClassVariable')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    unless res.length == 1
      return t.error("unexpected singnatures")
    end

    expect = "@@classvariable: Integer"
    actual = res[0].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end

  module Aliases
    # @return [Integer]
    def foo
    end
    alias bar foo
    alias_method :baz, :foo
  end

  def test_aliases(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::Aliases')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    expect = "def foo: () -> Integer"
    actual = res[0].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = "alias bar foo"
    actual = res[1].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = "alias baz foo"
    actual = res[2].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end

  class Resolver
    module Foo
      class Bar
      end
    end

    include Foo

    # @return [Bar]
    def foo
    end
  end
  def test_resolver(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::Resolver')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    expect = "def foo: () -> YARD2RBSTest::Resolver::Foo::Bar"
    actual = res[0].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end
end
