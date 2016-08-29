module Cycromatic
  class Calculator
    attr_reader :node

    def initialize(node:)
      @node = node
    end

    def each_complexity(&block)
      if block_given?
        calculate_toplevel node, &block
      else
        enum_for :each_complexity
      end
    end

    private

    COMPLEX_NODE_TYPES = Set.new([:if, :while, :while_post, :when, :resbody, :csend, :for,
                                  :and, :or,
                                  :optarg, :kwoptarg])

    def calculate_toplevel(node, &block)
      value = calculate_node(node, &block)
      yield Complexity.new(type: :toplevel, node: node, value: value + 1)
    end

    def calculate_def(node, &block)
      value = 0

      case node.type
      when :def
        args = node.children[1]
        body = node.children[2]
      when :defs
        args = node.children[2]
        body = node.children[3]
      end

      value += calculate_node(args, &block)
      value += calculate_node(body, &block) if body

      yield Complexity.new(type: :method, node: node, value: value + 1)
    end

    def calculate_node(node, &block)
      count = 0

      case node.type
      when :def
        calculate_def node, &block
        return 0
      when :defs
        calculate_def node, &block
        return calculate_node(node.children[0], &block)
      when :case
        if node.children.last.type != :when
          count = 1
        end
      when :rescue
        if node.children.last.type != :resbody
          count = 1
        end
      else
        if COMPLEX_NODE_TYPES.include?(node.type)
          count = 1
        end
      end

      count + node.children.flat_map do |child|
        if child.is_a? Parser::AST::Node
          [calculate_node(child, &block)]
        else
          []
        end
      end.inject(0) {|x, y| x + y }
    end
  end
end
