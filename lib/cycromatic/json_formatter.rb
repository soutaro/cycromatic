module Cycromatic
  class JSONFormatter
    attr_reader :io

    def initialize(io:)
      @io = io
      @results = {}
    end

    def started(path:)
      @path_results = []
      @results[path.to_s] = { results: @path_results }
    end

    def finished(path:)
      @path_results = nil
    end

    def completed
      @io.puts @results.to_json
    end

    def error(path:, exception:)
      @results[path.to_s] = {
        error: {
          message: exception.to_s,
          trace: exception.backtrace
        }
      }
    end

    def calculated(path:, complexity:)
      loc = complexity.node.loc
      name = case complexity.type
             when :toplevel
               "[toplevel]"
             when :method
               complexity.node.children.find {|c| c.is_a? Symbol }.to_s
             end

      @path_results << {
        method: name,
        line: [loc.first_line, loc.last_line],
        complexity: complexity.value
      }
    end
  end
end
