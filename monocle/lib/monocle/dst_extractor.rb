require 'ap'

module Monocle
  class DSTExtractor
    def initialize snippet
      @snippet = snippet
      @template_ast = RubyParser.parse(snippet.sample_code)
    end

    def extract_from(ast)
      match_nodes?(ast, @template_ast)
    end

    def match_placeholder?(id, node)
      if !@snippet.respond_to?(:"match_#{id}?")
        puts @snippet.sample_code
      end

      @snippet.send(:"match_#{id}?", node)
    end

    def match_nodes?(node, template)
      if $extensive_mutator_logging
        puts "--------------- compare nodes -----------------"
        ap node
        puts "template: -------------------------------------"
        ap template
        puts "-----------------------------------------------"
      end
      if template.is_a?(Symbol)
        match_symbol?(node, template)
      elsif template.is_a?(Astrolabe::Node)
        meth = :"match_#{template.type}_node?"
        if respond_to?(meth)
          send(meth, node, template)
        else
          if template.type != node&.type
            raise 'unexpected node type mismatch: #{template.type} != #{node&.type}'
          end
          template.type == node&.type && match_children?(node, template)
        end
      else
        node == template
      end
    end

    def match_children? node, template, range=0..-1
      node.children[range].each_with_index do |child, index|
        return false unless match_nodes?(child, template.children[range][index])
      end
      true
    end

    def match_symbol? node, template
      if id = Monocle.extract_placeholder_id(template)
        match_placeholder?(id, node)
      else
        node == template
      end
    end

    def match_const_node? node, template
      return unless template.type == node.type
      if id = Monocle.extract_placeholder_id(template.children.last)
        match_placeholder?(id, node.children.last) &&
        match_children?(node, template, 0..-2)
      else
        match_children? node, template
      end
    end

    def match_ivar_node? node, template
      return unless template.type == node.type
      if id = Monocle.extract_placeholder_id(template.children.first)
        match_placeholder?(id, node)
      else
        node == template
      end
    end

    def match_block_arg_node? node, template
      return unless template.type == node.type
      if id = Monocle.extract_placeholder_id(template.children.first)
        match_placeholder?(id, node)
      else
        node == template
      end
    end

    def match_send_node? node, template
      if id = Monocle.extract_placeholder_id(template.children[1])
        raise if template.children.size > 2
        match_placeholder?(id, node)
      elsif node&.type == :lvar
        # This code deals with the following edgecase:
        #
        # `a.each {|b| b}` when parsing this, the second `b` will be an 
        # lvar node, because the parser knows there is a local var with 
        # that name. When parsing the block contents separately, it'll 
        # become a send node, because the parser doesn't know there is a
        # local var. So, if a child-snippet contains block contents, any
        # local vars will be send nodes in the snippet ast, but lvar nodes
        # in the real ast. 
        return unless template.children[0] || template.children.size < 3
        node.children.first == template.children[1]
      else
        return unless template&.type == node&.type
        first_arg = template.children[2]
        # TODO: if type is send, and there is a child of send which happens to
        # be a placeholder and the placeholder ast2dst_meta method tells us
        # that it's child snippets that have link_to_array, then we need to
        # match each of the ast elements to that placeholder, while keeping
        # track of an index (to construct the data_path prefix for the
        # elmement in the linked_array) # in a snippet instance variable
        if first_arg&.type == :send &&
          (id = Monocle.extract_placeholder_id(first_arg.children[1])) &&
          @snippet.respond_to?(:"match_options_#{id}") &&
          @snippet.send(:"match_options_#{id}")[:type] == :list_of_symbols
          match_children?(node, template, 0..1) && match_placeholder?(id, node.children[2..-1])
        else
          match_children? node, template
        end
      end
    end

    def match_class_or_block? node, template
      return unless template.type == node.type
      return unless match_children?(node, template, 0..1)
      current_ast_node = 0
      children = node.children[2]&.children || []
      snippet_children = template.children[2]&.children || []
      snippet_children.each do |snippet_child|
        if id = Monocle.extract_placeholder_id(snippet_child.type == :send && snippet_child.children[1])

          # TODO: Implement a ast2dst_meta2 method that tells us if we have to match *all* methods.
          @snippet.ast_for_snippet_count = 0 # is used in the snippet when dealing with linked_array
          while children.size > current_ast_node && match_placeholder?(id, children[current_ast_node])
            current_ast_node += 1
            @snippet.ast_for_snippet_count += 1
          end
        else
          return unless match_nodes?(children[current_ast_node], snippet_child)
          current_ast_node += 1
        end
      end
      current_ast_node == children.size
    end

    alias_method :match_class_node?, :match_class_or_block?
    alias_method :match_block_node?, :match_class_or_block?

    def match_ivasgn_node? node, template
      return unless template.type == node.type
      if id = Monocle.extract_placeholder_id(template.children.first)
        match_placeholder?(id, node) &&
        match_children?(node, template, 1..-1)
      else
        match_children? node, template
      end
    end

    def match_def_node? node, template
      return unless template.type == node.type
      if id = Monocle.extract_placeholder_id(template.children.first)
        match_placeholder?(id, node) &&
        match_children?(node, template, 1..-1)
      else
        match_children? node, template
      end
    end
  end
end