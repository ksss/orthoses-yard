module YARDTest
  # @param [Boolean] a
  # @param [String, nil] b
  # @param [Array<Float>] c
  # @param [String] d
  # @param [Symbol, nil] e
  # @param [Hash{Symbol => String, nil}] f
  # @return [void]
  def foo(a, b = nil, *c, d:, e: nil, **f)
    1
  end

  def test_yard(t)
    store = Orthoses::YARD.new(
      ->{ Orthoses::Utils.new_store },
      globs: ["lib/orthoses/yard_test.rb"]
    ).call
    actual = store["YARDTest"].to_rbs
    expect = <<~RBS
      module YARDTest
        # @param [Boolean] a
        # @param [String, nil] b
        # @param [Array<Float>] c
        # @param [String] d
        # @param [Symbol, nil] e
        # @param [Hash{Symbol => String, nil}] f
        # @return [void]
        def foo: (bool a, ?String? b, *Array[Float] c, d: String, ?e: Symbol?, **Hash[Symbol, String?] f) -> void
      end
    RBS

    unless expect == actual
      t.error("expect=\n```rbs\n#{expect}```\n, but got \n```rbs\n#{actual}```\n")
    end
  end
end
