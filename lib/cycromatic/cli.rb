require 'optparse'
require 'rainbow'
require 'json'
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
      start_analyze()
      analyze_scripts args do |path, stmt, complexity|
        add_result path, stmt, complexity
      end
      done_analyze()
    end

    def start_analyze
      if @format == "json"
        @results = []
      end
    end

    def add_result(path, stmt, complexity)
      if @format == "json"
        @results << [path, stmt, complexity]
      else
        case stmt
        when Contror::ANF::AST::Stmt::Base
          loc = stmt.node.loc
          name = if stmt.is_a?(Contror::ANF::AST::Stmt::Def)
                   stmt.name
                 else
                   "[toplevel]"
                 end

          puts "#{path}\t#{name}:#{loc.first_line}:#{loc.last_line}\t#{complexity}"
        else
          # error
          puts Rainbow("#{path}:1:1\t(error)").red
        end
      end
    end

    def done_analyze
      if @format == "json"
        hash = {}

        @results.group_by(&:first).each do |path, results|
          case results.first[1]
          when Contror::ANF::AST::Stmt::Base
            # success
            hash[path.to_s] = {
              results: results.map {|r|
                stmt = r[1]
                loc = stmt.node.loc

                name = if stmt.is_a?(Contror::ANF::AST::Stmt::Def)
                         stmt.name
                       else
                         "[toplevel]"
                       end
                {
                  method: name,
                  line: [loc.first_line, loc.last_line],
                  complexity: r.last
                }
              }
            }
          when StandardError
            # error
            error = results.first[1]

            hash[path.to_s] = {
              message: error.to_s,
              trace: error.backtrace
            }
          end
        end

        puts hash.to_json
      end
    end

    def analyze_scripts(args)
      each_ruby_script args do |path|
        begin
          node = Parser::CurrentRuby.parse(path.read, path.to_s)
          if node
            stmt = Contror::ANF::Translator.new.translate(node: node)
            builder = Contror::Graph::Builder.new(stmt: stmt)
            builder.each_graph do |graph|
              cc = graph.edges.count - graph.vertexes.count + 2
              stmt = graph.stmt

              yield path, stmt, cc
            end
          end
        rescue => exn
          yield path, exn, 0
        end
      end
    end

    def each_ruby_script(args, &block)
      args.each do |arg|
        path = Pathname(arg)
        case
        when path.file?
          yield path
        when path.directory?
          each_ruby_script0(path, &block)
        end
      end
    end

    def each_ruby_script0(path, &block)
      if path.basename.to_s =~ /\A\.[^\.]+/
        return
      end

      case
      when path.directory?
        path.children.each do |child|
          each_ruby_script0 child, &block
        end
      when path.file?
        if path.extname == ".rb"
          yield path
        end
      end
    end
  end
end
