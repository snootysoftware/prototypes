require "rexml/document"

module ERB2Builder
  class IntermediateView
    include REXML
    attr_reader :result

    def initialize(doc, tree, snippets, index2line)
      @snippets = snippets
      @index2line = index2line
      @debug = false
      @debug_indent = 0
      fumbled = fumble_xml(doc.children)
      raise 'oh no' unless supported_format?(fumbled)
      flattened = flatten_children(fumbled)
      normalized = normalize(flattened)
      if tree
        if tree.begin_type?
          @result = doubletree_recurse(normalized, tree.children)
        else
          @result = doubletree_recurse(normalized, [tree].flatten)
        end
      else
        @result = doubletree_recurse(normalized, [])
      end
    end

    def normalize elements
      elements.map do |n|
        if n[:type] == :html_tag
          result = {
            type: :html_tag,
            tag: normalize_textish(n[:tag]),
            children: normalize(n[:children]),
            attributes: {}
          }
          n[:attributes].each do |k,v|
            result[:attributes][normalize_textish(k)] = normalize_textish(v)
          end
          result
        else
          [:true_children, :false_children, :children].each do |c|
            n[c] = normalize(n[c]) if n[c]
          end
          n
        end
      end
    end

    def normalize_textish elements
      elements.map do |n|
        if n.is_a? String
          {type: :text, value: n}
        else
          n.merge(type: :erb)
          {
            type: :code,
            print_output: n[:print_output],
            code: @snippets[n[:index]]
          }
        end
      end
    end

  # supporting erb tags that open a block or if statement, within an xml element name/attribute (example: <a href="<% if cake %> something <% end %>">) is extra complicated and likely unnecessary, so for now, we don't.
    def supported_format? element
      if element.is_a?(Array)
        return false if element.map { |n| supported_format?(n) }.include?(false)
      elsif element[:type] == :html_tag
        [
          element[:tag],
          element[:attributes].keys,
          element[:attributes].values
        ].flatten.each do |n|
          return false if n.is_a?(Hash) && !Astroturf.parse(@snippets[n[:index]])
        end
        return false if element[:children].map { |n| supported_format?(n) }.include?(false)
      end
      true
    end

    def flatten_children element
      result = []
      element.each do |n|
        if n[:type] == :html_tag
          n[:children] = flatten_children(n[:children])
          result << n
        elsif n[:type] == :text
          n[:values].each do |v|
            if v.is_a?(String)
              result << {type: :text, value: v}
            else
              result << v.merge(type: :erb)
            end
          end
        elsif [:comment, :doctype].include?(n[:type])
          result << n
        else
          raise 'wtf'
        end
      end
      result
    end

    def doubletree_recurse elements, tree
      @debug_indent += 2
      result = []
      skip_until = nil
      elements.each_with_index do |e,i|
        next if skip_until && skip_until > i

        indent_puts "#{i}: #{e[:type]}"

        if e[:type] == :text
          result << e#{ type: :text, value: e.to_s }
        elsif e[:type] == :erb
          snippet_index = e[:index]&.to_i

          code = @snippets[snippet_index]
          node = find_node(tree, snippet_index)

          indent_puts code
          indent_puts node.loc.expression.source
          indent_puts node.loc.last_line

  # some bug causes a little whitespace to be added to some erb tags, this strips it for now
  # TODO figure out root cause
          code = code.scan(/(\s?)\s*([^\n]+)\n\Z/m).flatten.join if code =~ /\A[^\n]+\n\Z/

          lvasgn = nil
          if node.lvasgn_type?
            lvasgn = node.children.first
            node = node.children.last
          end

          if node.block_type?
            start = i + 1
            finish = array_index_by_snippet_index(elements, node.loc.last_line) - 1

            result << {
              type: node.type,
              args: (node.children[1]&.children || []).map { |n| n.children.first },
              print_output: e[:print_output],
              lvasgn: lvasgn,
              children: doubletree_recurse(elements[start..finish], node.block_contents)
            }
            result.last[:code] = node.children.first.loc.expression.source

            skip_until = finish + 2
          elsif node.if_type?
            if node.loc.is_a?(Parser::Source::Map::Ternary) && node.loc.line == node.loc.last_line
              result << {
                type: :code,
                lvasgn: lvasgn,
                print_output: e[:print_output],
                code: code
              }
            elsif node.loc.is_a?(Parser::Source::Map::Ternary)
              raise '??'
            elsif node.loc.line == node.loc.last_line
              # this is for dealing with the following edge case: spec/fixtures/input/postfix-conditions.erb
              result << {
                type: :code,
                lvasgn: lvasgn,
                print_output: e[:print_output],
                code: code
              }
            else
              keyword = node.loc.keyword.source
              if node.loc.else
                if node.loc.else.source == "elsif"
                  raise UnexpectedERBError, "Sorry, we currently don't support the elsif statement in ERB tags. We're on it, but in the meantime please rewrite using only if/else statements if you want to convert this template."
                end
                else_index = array_index_by_snippet_index(elements, node.loc.else.line)

                start_t = i + 1
                finish_t = else_index - 1
                start_f = else_index + 1
                finish_f = array_index_by_snippet_index(elements, node.loc.last_line) - 1

                true_contents, false_contents = node.if_true_contents, node.if_false_contents
                if keyword == "unless"
                  true_contents, false_contents = false_contents, true_contents
                end

                result << {
                  type: node.type,
                  lvasgn: lvasgn,
                  keyword: keyword,
                  print_output: e[:print_output],
                  true_children: doubletree_recurse(
                    elements[start_t..finish_t],
                    true_contents
                  ),
                  false_children: doubletree_recurse(
                    elements[start_f..finish_f],
                    false_contents
                  )
                }

                skip_until = finish_f + 2
              else
                start = i + 1
                finish = array_index_by_snippet_index(elements, node.loc.last_line) - 1
                finish2 = finish
                contents = keyword == "unless" ? node.if_false_contents : node.if_true_contents

                result << {
                  print_output: e[:print_output],
                  type: node.type,
                  lvasgn: lvasgn,
                  keyword: keyword,
                  true_children: doubletree_recurse(elements[start..finish], contents),
                  false_children: []
                }

                skip_until = finish + 2
              end
              result.last[:code] = node.children.first.loc.expression.source
            end
          elsif Astroturf.parse(code)
            result << {
              type: :code,
              print_output: e[:print_output],
              code: code
            }
          else
            #ap node
            raise 'other wtf?'
          end
        elsif e[:type] == :html_tag
          result << {
            type: :html_tag,
            tag: e[:tag],
            attributes: e[:attributes],
            children: doubletree_recurse(e[:children], tree)
          }
        elsif [:comment, :doctype].include?(e[:type])
          result << e
        else
          raise 'wtf?'
        end
      end
      @debug_indent -= 2
      result
    end

    def indent_puts str
      return unless @debug
      str.to_s.split("\n").each do |l|
        puts "#{' ' * @debug_indent}#{l}"
      end
    end

    def fumble_xml nodes
      nodes.map do |n|

        if n.text?
          { type: :text, values: fumble_text(n.to_s) }
        elsif n.element?
          {
            type: :html_tag,
            tag: fumble_text(n.name),
            attributes: Hash[n.attributes.map { |a|
              [fumble_text(a.first), fumble_text(a.last.value)]
            }],
            children: fumble_xml(n.children)
          }
        elsif n.comment?
          if n.to_s.include?(Erb2xml::RandomToken)
            { type: :text, values: fumble_text(n.to_s.gsub(/(^<!-- | -->$)/,'')) }
          else
            { type: :comment, value: n.to_s }
          end
        elsif n.class == Nokogiri::XML::DTD
          { type: :doctype, value: n.to_xml }
        else
          raise '???'
        end

      end
    end

    def fumble_text text
      result = ['']
      text.scan(Erb2xml::ErbMatcher).flatten.each do |n|
        if n.size == 1
          result[result.size - 1] += n
        else
          result << fumble_erb_tag(n)
          result << ''
        end
      end
      result.pop if result.last.empty?
      result
    end

    def fumble_erb_tag tag
      output, index, strip = tag.scan(/erb-(.+?)-snippet_index-(\d+)-strip_whitespace-(.+)/).flatten
      {
        print_output: output == 'print',
        index: index.to_i,
        strip_whitespace: strip == 'true'
      }

    end

    def find_node tree, snippet_index
      (tree.respond_to?(:children) ? tree.children : tree).find do |n|
        @index2line[snippet_index].include? n.loc.line
      end
    end

    def array_index_by_snippet_index elements, index
      indent_puts index
      snippet_index = @index2line.find{ |n| n.include? index }
      indent_puts snippet_index
      index = @index2line.index(snippet_index)
      indent_puts index
      elements.each_with_index do |n,i|
        indent_puts n[:index]
        return i if n[:index]&.to_i == index
      end

      raise '???'
    end

    def self.reconstruct_lvasgn iv
      iv[:lvasgn] ? " #{iv[:lvasgn]} =" : ""
    end

    def self.whitespace indent
      indent ? "\n#{'  ' * indent}" : ''
    end

    def self.reconstruct_erb iv, show_edge_cases=false, escape_html=false, indent: nil
      result = ""
      iv.each do |n|
        if n[:type].to_sym == :text
          result += whitespace indent unless n[:value] == ''
          value = indent ? n[:value].strip : n[:value]
          if escape_html
            result += CGI.escape_html(value)
          else
            result += value
          end
        elsif n[:type].to_sym == :code
          result += whitespace indent
          result += "<%#{'=' if n[:print_output]}#{reconstruct_lvasgn(n)}#{n[:code]}%>"
        elsif [:comment, :doctype].include?(n[:type].to_sym)
          result += whitespace indent unless n[:type].to_sym == :doctype
          result += n[:value]
        elsif n[:type].to_sym == :block
          result += whitespace indent
          yields = n[:args].map(&:to_s).join(', ')
          yields = "|#{yields}| " unless yields.empty?
          result += "<%#{'=' if n[:print_output]} #{reconstruct_lvasgn(n)}#{n[:code]} do #{yields}%>"
          result += reconstruct_erb(n[:children], indent: indent&.+(1))
          result += whitespace indent
          result += "<% end %>"
        elsif n[:type].to_sym == :html_tag
          result += whitespace indent
          attrs = ""
          n[:attributes].each do |k,v|
            attrs += " #{reconstruct_erb k}=\"#{reconstruct_erb(v,false,true,indent: nil)}\""
          end
          tag = reconstruct_erb n[:tag]
          void_elems = %w(area base br col hr img input link meta param command keygen source)
          if n[:children].empty? && void_elems.include?(tag)
            result += "<#{tag}#{attrs} />"
          else
            kids = n[:children].map { |c| reconstruct_erb([c], indent: indent&.+(1)) }
            result += "<#{tag}#{attrs}>#{kids.join('')}"
            result += whitespace indent
            result += "</#{reconstruct_erb n[:tag]}>"
          end
        elsif n[:type].to_sym == :if
          result += whitespace indent
          if n[:false_children].empty?
            result += "<% #{reconstruct_lvasgn(n)}#{n[:keyword]} #{n[:code]} %>#{reconstruct_erb(n[:true_children], indent: indent&.+(1))}"
            result += whitespace indent
            result += "<% end %>"
          else
            result += "<% #{reconstruct_lvasgn(n)}#{n[:keyword]} #{n[:code]} %>#{reconstruct_erb(n[:true_children], indent: indent&.+(1))}"
            result += whitespace indent
            result += "<% else %>#{reconstruct_erb(n[:false_children], indent: indent&.+(1))}"
            result += whitespace indent
            result += "<% end %>"
          end
        else
          raise
        end

        if n[:edge_cases]
          n[:edge_cases].each do |e|
            result += "#{Erb2xml::RandomToken}-edgecase_index-#{e}-end"
          end
        end

      end
      result
    end

    def self.separate_edge_cases erb, edge_cases
      result = []
      r = /#{Erb2xml::RandomToken}-edgecase_index-(\d)-end/
      erb.split("\n").each_with_index do |n,i|
        n.scan(r).flatten.each do |e|
          result << {message: edge_cases[e.to_i], line_no: i + 1}
        end
      end
      [erb.gsub(r, ''), result]
    end
  end
end