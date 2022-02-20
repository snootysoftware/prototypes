require 'astrolabe/builder'

module Astroturf
  class Node < Astrolabe::Node
    def xml
      XMLAST.new(self)
    end
    def xpath *xpaths
      results = xpaths.map do |str|
        xml.xpath(str).map do |n|
          if n.respond_to?(:attributes) && n.attributes['id']
            result = each_node.find {|m| m.object_id.to_s == n.attributes['id']}
            raise 'node missing' unless result
            result
          else
            n
          end
        end
      end
      results.flatten
    end

    alias_method :ctypes, :each_child_node
    alias_method :dtypes, :each_descendant

    def ctype(q)
      children.find{ |d| d.kind_of?(Node) && d.type == q }
    end

    def cval(q)
      children.find{ |d| d.children.include?(q) }
    end

    def cvals(q)
      children.select do |d|
        d.respond_to?(:children) && d.children.include?(q)
      end
    end

    def dtype(q)
      descendants.find{ |d| d.type == q }
    end

    def dval(q)
      descendants.find{ |d| d.children.include?(q) }
    end

    def innermost_send
      current = self
      loop do
        if current.send_receiver&.send_type?
          current = current.send_receiver 
        else
          return current
        end
      end
    end

    def unfold_send_chain
      result = [self]
      current = self
      loop do
        if current.send_receiver&.send_type?
          current = current.send_receiver
          result.unshift current
        else
          return result
        end
      end
    end

    def send_receiver
      children.first
    end

    def send_message
      children[1]
    end

    def send_args
      children[2..-1]
    end

    def block_contents
      if_false_contents
    end

    def if_false_contents
      if children[2]&.begin_type?
        children[2].children
      elsif children[2] == nil
        []
      else
        [children[2]]
      end
    end
      
    def if_true_contents
      if children[1]&.begin_type?
        children[1].children
      elsif children[1] == nil
        []
      else
        [children[1]]
      end
    end

    def replace_send_args
      head = children[0..1]
      tail = yield(send_args)
      updated(nil, head + tail)
    end

    def sym_value
      children.first
    end

    def str_value; sym_value ; end

    def safe_value
      if sym_type?
        sym_value
      elsif true_type?
        true
      elsif false_type?
        false
      elsif str_type?
        str_value
      else
        self
      end
    end

    def safe_hash_value
      raise 'invalid node type' unless hash_type?
      result = {}
      children.each do |pair|
        result[pair.children.first.safe_value] = pair.children.last.safe_value
      end
      result
    end
  end
end