module ERB2Builder
  class Builder2Erb
    def self.parse input
      result = new(input).convert
      result.is_a?(Hash) ? [result] : result
    end

    def initialize input
      @root = Parser::CurrentRuby.parse input
    end

    def convert node=@root
      if node.nil?
        []
      elsif node.type == :block
        # matches: xml.html do
        if node.children.first.type == :send &&
            node.children.first.children.first.children == [nil, :xml]
          children = begin_to_children node.children.last
          { type: :html_tag,
            tag: [{ type: :text, value: node.children.first.children[1].to_s}],
            attributes: convert_attributes(node.children.first.children[2]),
            children: children}
        # matches: regular block
        else
          args = node.children[1].children.map(&:children).map(&:last)
          code = Unparser.unparse(node.children.first)
          children = begin_to_children node.children.last
          {:type=>:block,
          :args=>args,
          :print_output=>false,
          :lvasgn=>nil,
          :children=>children,
          :code=>code}
        end
      elsif node.type == :send
        # matches: plain text
        if node.children[0..1] == [s(:send, nil, :xml), :<<]
          value = node.children.last
          if value.type == :str
            {:type=>:text, :value=> value.children.last}
          else
            if node.children.last.type == :block
              blk = node.children.last
              args = blk.children[1].children.map(&:children).map(&:last)
              code = Unparser.unparse(blk.children.first)
              children = begin_to_children blk.children.last
              {:type=>:block,
              :args=>args,
              :print_output=>true,
              :lvasgn=>nil,
              :children=>children,
              :code=>code}
            else 
              code = Unparser.unparse(node.children.last)
              {:type=>:code, :print_output=>true, :code=> " #{code} "}
            end
          end
        elsif node == Parser::CurrentRuby.parse("xml.declare!(:DOCTYPE, :html)")
          {:type=>:doctype, :value=>"<!DOCTYPE html>"}
        elsif node.children[0] == s(:send, nil, :xml)
          { type: :html_tag,
            tag: [{ type: :text, value: node.children[1].to_s}],
            attributes: convert_attributes(node.children[2]),
            children: []}
        else
          code = Unparser.unparse(node)
          {:type=>:code, :lvasgn => nil, :print_output=>false, :code=> " #{code} "}
        end
      elsif node.type == :if
        code = Unparser.unparse(node.children.first)
        {:type=>:if,
        :lvasgn=>nil,
        :keyword=>"if",
        :print_output=>false,
        :true_children=>begin_to_children(node.children[1]),
        :false_children=>begin_to_children(node.children[2]),
        :code=>code}
      elsif node.type == :begin
        node.children.map { |n| convert(n) }
      elsif node.type == :lvasgn
        convert(node.children.last).merge(lvasgn: node.children.first.to_s)
      else
        raise 'unmatched builder construct.'
      end
    end

    private

    def convert_attributes attributes
      return {} unless attributes
      raise if attributes.children.find do |n|
        ![:sym, :str].include?(n.children.first.type) ||
        ![:sym, :str].include?(n.children.last.type)
      end # No support for interpolated attributes yet
      attributes.children.map do |n|
        [
          [{:type => :text, :value => n.children.first.children.first}],
          [{:type => :text, :value => n.children.last.children.first}]
        ]
      end.to_h
    end

    def begin_to_children node
      if  node == nil
        []
      elsif node.type == :begin
        node.children.map{ |child| convert(child) }
      else
        [convert(node)]
      end.compact
    end

    def s(tag, *args)
      Astrolabe::Node.new(tag, args)
    end
  end
end