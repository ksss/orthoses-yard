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

  def run_test(t, const_name, expects)
    yardoc = ::YARD::Registry.at(const_name)
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs, skippable|
      res << [namespace, docstring, rbs, skippable]
    end

    unless expects.length == res.length
      t.error("expect #{expects.length} results, But got #{res.length}")
    end

    expects.zip(res).each do |expect, actual|
      unless expect == actual
        t.error("expect `#{expect}`, but got `#{actual}`")
      end
    end
  end

  class NoTagsInitialize
    def initialize(a)
    end
  end

  def test_not_tags_initialize(t)
    run_test(
      t,
      'YARD2RBSTest::NoTagsInitialize',
      [
        ["YARD2RBSTest::NoTagsInitialize", "", nil, false],
        ["YARD2RBSTest::NoTagsInitialize", "", "def initialize: (untyped a) -> void", true]
      ]
    )
  end

  class WithParamInitialize
    # @param [String] a
    def initialize(a)
    end
  end

  def test_with_param_initialize(t)
    run_test(
      t,
      'YARD2RBSTest::WithParamInitialize',
      [
        ["YARD2RBSTest::WithParamInitialize", "", nil, false],
        ["YARD2RBSTest::WithParamInitialize", "@param [String] a", "def initialize: (String a) -> void", false]
      ]
    )
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

    def no_doc_method(a, b = nil, c:, d: nil)
    end

    def initialize
    end
  end

  def test_method(t)
    run_test(
      t,
      'YARD2RBSTest::Methods',
      [
        ["YARD2RBSTest::Methods", "", nil, false],
        [
          "YARD2RBSTest::Methods",
          "@yieldparam [String] a\n@yieldreturn [String]",
          "def foo: () { (String a) -> String } -> untyped",
          false
        ],
        [
          "YARD2RBSTest::Methods",
          "@param [String] a\n@return [void]",
          "def bar: (String a) -> void",
          false
        ],
        [
          "YARD2RBSTest::Methods",
          "@param [String] a\n@yieldparam [String]\n@yieldreturn [String]\n@return [void]",
          "def baz: (String a) { (String) -> String } -> void",
          false
        ],
        [
          "YARD2RBSTest::Methods",
          "\n@yieldreturn [String]\n",
          "def qux: () { () -> String } -> untyped",
          false
        ],
        [
          "YARD2RBSTest::Methods",
          "@param [List<String>] a\n@param [Array<String>] b\n@return [Hash<String>]",
          "def collection_type: (List[String] a, Array[String] b) -> Hash[untyped, untyped]",
          false
        ],
        [
          "YARD2RBSTest::Methods",
          "",
          "def no_doc_method: (untyped a, ?untyped b, c: untyped, ?d: untyped) -> untyped",
          true
        ],
        [
          "YARD2RBSTest::Methods",
          "",
          "def initialize: () -> void",
          true
        ]
      ]
    )
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
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs, skippable|
      res << [namespace, docstring, rbs, skippable] if rbs
    end

    [
      ["YARD2RBSTest::Attributes", "@return [Integer]", "attr_reader self.r: Integer", false],
      ["YARD2RBSTest::Attributes", "@return [Integer]", "private attr_writer self.w: Integer", false],
      ["YARD2RBSTest::Attributes", "@return [Integer]", "attr_accessor a: Integer", false],
      ["YARD2RBSTest::Attributes", "Returns the value of attribute no_return_reader.", "attr_reader no_return_reader: untyped", true],
      ["YARD2RBSTest::Attributes", "Sets the attribute no_return_writer\n" + "@param value the value to set the attribute no_return_writer to.", "attr_writer no_return_writer: untyped", true],
      ["YARD2RBSTest::Attributes", "Returns the value of attribute no_return_accessor.", "attr_accessor no_return_accessor: untyped", true]
    ].zip(res).each do |expect, actual|
      unless expect == actual
        t.error("expect `#{expect}`, but got `#{actual}`")
      end
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
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs, skippable|
      res << [namespace, docstring, rbs, skippable]
    end

    [
      ["YARD2RBSTest::Const", "", nil, false],
      ["YARD2RBSTest::Const", "@return [Integer]", "CONST: Integer", false],
      ["YARD2RBSTest::Const", "", "NO_RETURN: untyped", true]
    ].zip(res).each do |expect, actual|
      unless expect == actual
        t.error("expect `#{expect}`, but got `#{actual}`")
      end
    end
  end

  module ClassVariable
    # @return [Integer]
    @@classvariable = 1

    @@no_return = 2
  end

  def test_classvariable(t)
    run_test(
      t,
      'YARD2RBSTest::ClassVariable',
      [
        ["YARD2RBSTest::ClassVariable", "", nil, false],
        ["YARD2RBSTest::ClassVariable", "@return [Integer]", "@@classvariable: Integer", false],
        ["YARD2RBSTest::ClassVariable", "", "@@no_return: untyped", true]
      ]
    )
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
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs, skippable|
      res << [namespace, docstring, rbs, skippable]
    end

    [
      ["YARD2RBSTest::Aliases", "", nil, false],
      ["YARD2RBSTest::Aliases", "@return [Integer]", "def foo: () -> Integer", false],
      ["YARD2RBSTest::Aliases", "", "alias bar foo", false],
      ["YARD2RBSTest::Aliases", "@return [Integer] \n", "def bar: () -> Integer", false],
      ["YARD2RBSTest::Aliases", "", "alias baz foo", false],
      ["YARD2RBSTest::Aliases", "@return [Integer] \n", "def baz: () -> Integer", false]
    ].zip(res).each do |expect, actual|
      unless expect == actual
        t.error("expect `#{expect}`, but got `#{actual}`")
      end
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
