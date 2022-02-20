require 'active_support/core_ext/string/indent'

module Monocle
  class CodeGenerator < Parser::TreeRewriter
    def initialize snippet, dst
      @snippet, @dst = snippet, dst
    end

    def get_replacement(placeholder_id)
      meth = :"replace_#{placeholder_id}"
      result = if @snippet.respond_to? meth
        @snippet.send(meth)
      else
        # Raise NoMethodError manually to force inclusion of output from Snippet#inspect
        # The NoMethodError raised by Object#send uses a default description
        # when the output of #inspect is too long
        raise NoMethodError, "undefined method `#{meth}' for #{@snippet.inspect}"
      end

      raise "unexpected nil replacement for placeholder #{placeholder_id}" unless result
      result
    end

    def on_const(node)
      if id = Monocle.extract_placeholder_id(node.children.last)
        replace node.location.name, get_replacement(id)
      end
      super
    end

    def on_sym(node)
      symbol_id = node.children[0].id2name
      if id = Monocle.extract_placeholder_id(symbol_id)
        replace node.location.expression, ":#{get_replacement(id)}"
      end
    end

    def on_send(node)
      if id = Monocle.extract_placeholder_id(node.children[1])
        result = get_replacement(id)
        if result.is_a?(String)
          replace node.location.selector, result
        elsif result.is_a?(Hash) && result[:type] && result[:type] == :string
          replace node.location.expression,
                  Unparser.unparse(Astrolabe::Node.new(:str,[result[:result]]))
        elsif result.is_a?(Hash) && result[:replace_entire_node]
          replace node.location.expression, result[:result].indent(node.loc.column).strip
        end
      end

      super node
    end

    def on_ivasgn(node)
      if id = Monocle.extract_placeholder_id(node.children[0])
        replace node.location.name, get_replacement(id)
      end
      super
    end

    def on_def(node)
      if id = Monocle.extract_placeholder_id(node.children[0])
        replace node.location.name, get_replacement(id)
      end
      super
    end

    def on_argument(node)
      if id = Monocle.extract_placeholder_id(node.children[0])
        replace node.location.name, get_replacement(id)
      end
      super
    end

    def on_ivar(node)
      if id = Monocle.extract_placeholder_id(node.children[0])
        result = get_replacement(id)
        if result.is_a?(String)
          replace node.location.name, result
        elsif result.is_a?(Hash) && result[:replace_entire_node]
          replace node.location.expression, result[:result]
        else
          raise 'unhandled ivar'
        end
      end
      super
    end

    def self.rewrite snippet, dst, code
      rewriter = new(snippet, dst)
      buffer        = Parser::Source::Buffer.new('(example)')
      buffer.source = code
      node = RubyParser.new.parse(buffer)
      rewriter.rewrite(buffer, node)
    end
  end
end