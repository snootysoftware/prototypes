require 'rexml/document'

module Astroturf
  class XMLAST
    include REXML

    attr_reader :doc

    def initialize sexp
      @doc = Document.new "<root></root>" 
      root = @doc.root

      populate_tree(root, sexp)
    end

    def pp
      doc.write($stdout, 2)
    end

    def xpath x
      XPath.match(doc, x)
    end

  private

    def populate_tree xml, sexp
      if sexp.is_a?(String) || sexp.is_a?(Symbol) || sexp.is_a?(Numeric) || sexp.is_a?(NilClass)
        el = Element.new sexp.class.to_s.downcase
        el.add_attribute 'value', sexp.to_s
        xml.add_element el
      elsif sexp.str_type? || sexp.ivar_type?
        el = Element.new "#{sexp.type}-node"
        el.add_attribute('id', sexp.object_id)
        el.add_attribute('value', sexp.children.first)
        xml.add_element el
      else 
        el = Element.new "#{sexp.type}-node"
        el.add_attribute('id', sexp.object_id)

        if sexp.type == :send
          el.add_attribute('message', sexp.children[1].to_s)
        elsif sexp.type == :def
          el.add_attribute('name', sexp.children[0].to_s)
        end

        sexp.children.each {|n| populate_tree(el, n) }
        xml.add_element el
      end
    end
  end
end