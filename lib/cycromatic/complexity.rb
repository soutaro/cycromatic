module Cycromatic
  class Complexity
    attr_reader :type
    attr_reader :node
    attr_reader :value

    def initialize(type:, node:, value:)
      @type = type
      @node = node
      @value = value
    end
  end
end
