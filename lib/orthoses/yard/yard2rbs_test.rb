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
end
