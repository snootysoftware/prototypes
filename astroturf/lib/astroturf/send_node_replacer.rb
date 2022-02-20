module Astroturf
  class SendNodeReplacer < Parser::Rewriter
    def initialize old_node, content
      @old_node, @content = old_node, content
    end

    def on_send(node)
      if !@replaced
        replace @old_node.location.expression, @content
        @replaced = true
      end
    end
  end
end