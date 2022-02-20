module Monocle
  class RubyParser < Parser::CurrentRuby
    class NormalizingBuilder < Astrolabe::Builder
      def n(type, children, source_map)

        # If a class or block contains a single expression, the ast node for that expression is placed at children[2].
        #
        # RubyParser.parse('class Foo; bar; end')
        # => s(:class,
        #      s(:const, nil, :Foo), nil,
        #      s(:send, nil, :bar))
        #
        # If the class or block contains multiple expressions children[2] is set to a "begin" node which contains those expressions.
        #
        # RubyParser.parse('class Foo; bar; baz; end')
        # => s(:class,
        #      s(:const, nil, :Foo), nil,
        #      s(:begin,
        #        s(:send, nil, :bar),
        #        s(:send, nil, :baz)))
        #
        # This makes processing a hassle, since you always need to check whether something is a begin node or a direct reference
        # to the ast node of the child expression. Since the unparser gem doesn't care if a begin node only contains one child,
        # and neither does any of the other processing, we enforce that expressions are always wrapped in a begin node regardless
        # of whether there are one or multiple.'
        if [:class, :block].include?(type) && !children[2].nil? && children[2].type != :begin
          body = [children[2]]
          children[2] = Astrolabe::Node.new(:begin, body, location: collection_map(nil, body, nil))
        end
        super(type, children, source_map)
      end
    end

    def initialize(builder = NormalizingBuilder.new)
      super(builder)
    end
  end
end