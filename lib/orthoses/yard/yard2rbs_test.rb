require 'yard'

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
      [["true"], "true"],
      [["false"], "false"],
      [["void"], "void"],
      [["self"], "self"],
      [["Object"], "untyped"],
      [["nil"], "nil"],
      [["nil", "nil"], "nil"],
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
    ].each do |tags, type|
      actual = g.tag_types_to_rbs_type(tags)
      expect = ::RBS::Parser.parse_type(type)
      unless expect == actual
        t.error("expect #{tags} convert \"#{type}\", but got \"#{actual}\"")
      end
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

    # @yieldreturn [String]
    def qux
    end
  end

  def test_method(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::Methods')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    expect = "def foo: () { (String a) -> String } -> untyped"
    actual = res[0].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = "def bar: (String a) -> void"
    actual = res[1].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = "def baz: (String a) { (String) -> String } -> void"
    actual = res[2].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = "def qux: () { () -> String } -> untyped"
    actual = res[3].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end

  module Attributes
    # @return [Integer]
    attr_accessor :a
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

    expect = "attr_reader self.r: Integer"
    actual = res[0].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = "private attr_writer self.w: Integer"
    actual = res[1].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end

    expect = "attr_accessor a: Integer"
    actual = res[2].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end

  module Const
    # @return [Integer]
    CONST = 1
  end

  def test_const(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::Const')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    expect = "CONST: Integer"
    actual = res[0].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end

  module ClassVariable
    # @return [Integer]
    @@classvariable = 1
  end

  def test_classvariable(t)
    yardoc = ::YARD::Registry.at('YARD2RBSTest::ClassVariable')
    res = []
    Orthoses::YARD::YARD2RBS.run(yardoc: yardoc) do |namespace, docstring, rbs|
      res << [namespace, docstring, rbs] if rbs
    end

    expect = "@@classvariable: Integer"
    actual = res[0].last
    unless expect == actual
      t.error("expect `#{expect}`, but got `#{actual}`")
    end
  end
end
