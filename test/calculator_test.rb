require_relative 'test_helper'

class CalculatorTest < Minitest::Test
  def calculate(script)
    node = Parser::CurrentRuby.parse(script, "(script)")
    yield Cycromatic::Calculator.new(node: node).each_complexity.find {|x| x.type == :toplevel }, node
  end

  def test_sequential
    calculate <<-EOS do |complexity|
      foo()
      bar()
    EOS
      assert_equal 1, complexity.value
    end
  end

  def test_if
    calculate <<-EOS do |complexity|
      if test()
        foo()
      end
    EOS
      assert_equal 2, complexity.value
    end
  end

  def test_and_or
    calculate "a&&b" do |complexity|
      assert_equal 2, complexity.value
    end

    calculate "a||b" do |complexity|
      assert_equal 2, complexity.value
    end
  end

  def test_loop
    calculate <<-EOS do |comp|
      for x in []
        puts x
      end
    EOS
      assert_equal 2, comp.value
    end

    calculate <<-EOS do |comp|
      while x = gets
        puts x
      end
    EOS
      assert_equal 2, comp.value
    end

    calculate <<-EOS do |comp|
      begin
        puts x
      end while x
    EOS
      assert_equal 2, comp.value
    end
  end

  def test_case
    # Counts when and else as complexity
    calculate <<-EOS do |comp|
      case x
      when 1
        puts 1
      when 2, 3
        puts 2
      else
        puts :else
      end
    EOS
      assert_equal 4, comp.value
    end
  end

  def test_rescue
    calculate <<-EOS do |comp|
      begin
        f()
      rescue E1
        puts :E1
      rescue E2, E3
        puts :E2, :E3
      rescue
        puts
      else
        puts :else
      end
    EOS
      assert_equal 5, comp.value
    end
  end

  def test_csend
    # Counts as complexity
    calculate "x&.f()" do |comp|
      assert_equal 2, comp.value
    end
  end

  def test_block
    # Does not count as complexity
    calculate "x.tap {|y| y.tap {|z| z } }" do |comp|
      assert_equal 1, comp.value
    end

    # Optional parameter count as complexity
    calculate "x.tap {|y=3| y }" do |comp|
      assert_equal 2, comp.value
    end
  end

  def test_method_def
    node = Parser::CurrentRuby.parse(<<-EOS)
      def f(x)
        if test
          foo(x)
        end
      end
    EOS
    calculator = Cycromatic::Calculator.new(node: node)

    complexities = calculator.each_complexity
    assert_equal 2, complexities.count

    toplevel_complexity = complexities.find {|comp| comp.type == :toplevel }
    refute_nil toplevel_complexity
    assert_equal 1, toplevel_complexity.value

    method_complexity = complexities.find {|comp| comp.type == :method }
    refute_nil method_complexity
    assert_equal 2, method_complexity.value
  end

  def test_nested_def
    node = Parser::CurrentRuby.parse(<<-EOS)
      def f()
        def g()
          def h()
            x || y
          end
        end
      end
    EOS

    calculator = Cycromatic::Calculator.new(node: node)

    complexities = calculator.each_complexity
    assert_equal 4, complexities.count

    assert complexities.any? {|c| c.type == :method && c.node.children[0] == :f && c.value == 1 }
    assert complexities.any? {|c| c.type == :method && c.node.children[0] == :g && c.value == 1 }
    assert complexities.any? {|c| c.type == :method && c.node.children[0] == :h && c.value == 2 }
  end

  def test_method_arg_complexity
    node = Parser::CurrentRuby.parse(<<-EOS)
      def f(a, b=a||1, *c, d:, e:2, **f)
      end
    EOS
    calculator = Cycromatic::Calculator.new(node: node)

    complexities = calculator.each_complexity

    method_complexity = complexities.find {|comp| comp.type == :method }
    refute_nil method_complexity
    assert_equal 4, method_complexity.value
  end

  def test_singleton_method_def
    node = Parser::CurrentRuby.parse(<<-EOS)
      def (a && b && c).f
        1 || 2
      end
    EOS
    calculator = Cycromatic::Calculator.new(node: node)

    complexities = calculator.each_complexity
    assert_equal 2, complexities.count

    toplevel_complexity = complexities.find {|comp| comp.type == :toplevel}
    assert_equal 3, toplevel_complexity.value

    method_complexity = complexities.find {|comp| comp.type == :method }
    assert_equal 2, method_complexity.value
  end
end
