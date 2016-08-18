require 'optparse'
require 'rainbow'

module Cycromatic
  class CLI
    attr_reader :args

    def self.start(args = ARGV)
      self.new(args).run
    end

    def initialize(args)
      @args = args
    end

    def run
      analyze_scripts args do |path, stmt, complexity|
        case stmt
        when Contror::ANF::AST::Stmt::Base
          loc = stmt.node.loc
          l = "#{loc.first_line}:#{loc.column}"

          if stmt.is_a?(Contror::ANF::AST::Stmt::Def)
            puts "#{path}\t#{stmt.name}:#{l}\t#{complexity}"
          else
            puts "#{path}\t[toplevel]:#{l}\t#{complexity}"
          end
        else
          # error
          puts Rainbow("#{path}:1:1\t(error)").red
        end
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
        each_ruby_script0(path, &block)
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
