module Cycromatic
  class TextFormatter
    attr_reader :io

    def initialize(io:)
      @io = io
    end

    def started(path:)
    end

    def finished(path:)
    end

    def completed
    end

    def error(path:, exception:)
      io.puts "#{path}\t(error)"
    end

    def calculated(path:, complexity:)
      loc = complexity.node.loc
      name = case complexity.type
             when :toplevel
               "[toplevel]"
             when :method
               complexity.node.children.find {|c| c.is_a? Symbol }.to_s
             end

      io.puts "#{path}\t#{name}:#{loc.first_line}\t#{complexity.value}"
    end
  end
end
