module Monocle
  class SourceUpdater
    ExplanationComments = {
  # TODO rename to monocle instead of app builder, and make sure the tests still pass
      :remove  => "# NOTE: App Builder removed code at this location and found these comments:",
      :replace => "# NOTE: App Builder updated the code below and found these comments:"
    }

    def self.update_file filename, target_source
      source = File.read filename
      result = update source, target_source
      File.open(filename, 'w') {|f| f.write(result) }
    end

    def self.update source, target_source
      updater = new
      updater.process source, target_source
    end

    def process source, target_source
      buffer = Parser::Source::Buffer.new('(string)')
      buffer.source = source
      pre_ast = RubyParser.new.parse(buffer)
      target_ast = RubyParser.parse(target_source)

      @rewriter = Parser::Source::TreeRewriter.new(buffer)
      if pre_ast.nil?
        separator = source.empty? ? '' : "\n"
        @rewriter.insert_after(buffer.source_range, separator + target_source)
      else
        compare pre_ast, target_ast
      end
      @rewriter.process
    end

    private

    # Compares two AST nodes recursively to figure out how to update the one into the other
    # while preserving comments.
    #
    # @param before [AST::Node]
    # @param after [AST::Node, nil]
    def compare before, after
      if after.nil?
        remove before
        return
      end

      # skip identical nodes
      return if before == after

      # replace the entire expression if the node type is different
      if before.type != after.type
        replace before, after
        return
      end

      meth = "compare_#{before.type}_node".to_sym
      if respond_to?(meth, true)
        send meth, before, after
      else
        # replace the entire node if any children are different
        if before.children != after.children
          replace before, after
        end
      end
    end

    def compare_children before, after
      before.children.zip(after.children).each do |cs|
        compare *cs unless cs[0].nil? || cs[1].nil?
      end
    end

    def compare_class_node before, after
      before_body = before.children.last
      if before_body.nil?
        replace before, after
      else
        compare_children before, after
      end
    end

    def compare_def_node before, after
      if before.loc.name.source != after.loc.name.source
        @rewriter.replace before.loc.name, after.loc.name.source
      else
        replace before, after
      end
    end

    def compare_begin_node before, after
      case after.children.size <=> before.children.size
      when -1 # fewer children than before
        removed = before.children - after.children
        if before.children - removed == after.children
          # one or more children were removed, the rest were unchanged
          removed.each do |node|
            remove node
          end
        else
          # complex change
          replace before, after
        end
      when 0 # same number of children as before
        compare_children before, after
      when 1 # more children than before
        added = after.children - before.children
        if after.children - added == before.children
          # one or more children were added, the rest were unchanged
          added.each_with_index do |node, index_correction|
            idx = after.children.index(node) - index_correction
            if idx < before.children.length
              @rewriter.insert_before(before.children[idx].loc.expression, node.loc.expression.source + "\n")
            else
              @rewriter.insert_after(before.loc.expression, "\n" + node.loc.expression.source)
            end
          end
        else
          # complex change
          replace before, after
        end
      end
    end

    # Replace expression with just its comments
    def remove node
      duplicate_comments_and_insert_before node, ExplanationComments[:remove]
      @rewriter.remove node.loc.expression
    end

    # Replace entire expression. Preserve comments by prepending them to the result
    def replace before, after
      duplicate_comments_and_insert_before before, ExplanationComments[:replace]
      @rewriter.replace before.loc.expression, after.loc.expression.source
    end

    def duplicate_comments_and_insert_before node, note
      _, comments = RubyParser.parse_with_comments(node.loc.expression.source)
      unless comments.empty?
        texts = [note, *comments.map(&:text)]
        @rewriter.insert_before node.loc.expression, texts.join("\n") + "\n"
      end
    end

  end
end