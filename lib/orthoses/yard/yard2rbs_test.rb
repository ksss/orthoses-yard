require 'yard'

module YARD2RBSTest
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

  def test_method(t)
    ::YARD::Registry.clear
    ::YARD.parse(__FILE__)
    yardoc = ::YARD::Registry.at('YARD2RBSTest')
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
end
