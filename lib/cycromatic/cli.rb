require 'optparse'
require 'rainbow'
require 'pathname'

module Cycromatic
  class CLI
    attr_reader :args

    def self.start(args = ARGV)
      self.new(args).run
    end

    def initialize(args)
      @args = args

      OptionParser.new do |opts|
        opts.on("--format FORMAT") {|fmt| @format = fmt }
      end.parse!(args)
    end

    def run
      formatter = @format == 'json' ? JSONFormatter.new(io: STDOUT) : TextFormatter.new(io: STDOUT)

      FileEnumerator.new(paths: paths).each do |path|
        formatter.started path: path
        begin
          node = Parser::CurrentRuby.parse(path.read, path.to_s)
          if node
            Calculator.new(node: node).each_complexity do |complexity|
              formatter.calculated(path: path, complexity: complexity)
            end
          end
        rescue => exn
          formatter.error(path: path, exception: exn)
        ensure
          formatter.finished path: path
        end
      end

      formatter.completed
    end

    def paths
      args.map {|arg| Pathname(arg) }
    end
  end
end
