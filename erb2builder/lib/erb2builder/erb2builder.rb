module ERB2Builder
  class Erb2Builder
    def self.parse input
      new(input).convert
    end

    def self.parse_without_whitespace input
      compressor = HtmlCompressor::Compressor.new(
        preserve_patterns: [HtmlCompressor::Compressor::SERVER_SCRIPT_TAG_PATTERN],
        remove_intertag_spaces: true
      )
      input = compressor.compress(input)
      new(input, false).convert
    end

    def initialize input, preserve_whitespace=true
      @preserve_whitespace = preserve_whitespace
      @intermediate = View.new('test.erb', input).intermediate_view
      @local_variable_stack = []
    end

    def with_local_variables local_variables
      raise unless local_variables.is_a?(Array) && local_variables.map(&:class).uniq == [Symbol]
      @local_variable_stack.push local_variables
      result = yield
      @local_variable_stack.pop
      result
    end

    def parse_with_context code
      args = @local_variable_stack.flatten.map(&:to_s).join(", ")
      args = "|#{args}|" unless args.empty?
      Parser::CurrentRuby.parse("nop do #{args} \n #{code} \n end").children.last
    end

    def convert node=@intermediate
      return s(:begin, *node.map { |n| convert(n) }.compact) if node.is_a?(Array)
      #ap node
      #ap parse_with_context("if @foo; 'foo'; else; 'not foo'; end")
      if node[:type] == :html_tag
        # binding.pry if node[:tag].first[:value].to_sym == :p
        attributes = convert_attributes(node[:attributes])
        send_ast = if attributes
          s(:send, s(:send, nil, :xml), node[:tag].first[:value].to_sym, attributes)
        else
          s(:send, s(:send, nil, :xml), node[:tag].first[:value].to_sym)
        end

        if node[:children].empty?
          send_ast
        else
          s(:block, send_ast, s(:args), s(:begin, *node[:children].map {|n| convert(n) }.compact))
        end
      elsif node[:type] == :code
        if node[:print_output]
          s(:send,
            s(:send, nil, :xml), :<<,
              parse_with_context(node[:code]))
        else
          parse_with_context(node[:code])
        end
      elsif node[:type] == :block
        raise 'lavsgn not supported' if node[:lvasgn]
        result = with_local_variables(node[:args]) do
          s(:block,
          parse_with_context(node[:code]),
          s(:args,
            *node[:args].map{ |arg| s(:arg, arg) }),
          s(:begin,
            *node[:children].map{ |child| convert child }.compact))
        end
        if node[:print_output]
          s(:send,
            s(:send, nil, :xml), :<<, result)
        else
          result
        end
      elsif node[:type] == :if
        raise 'lavsgn not supported' if node[:lvasgn]
        true_children = node[:true_children].map{ |child| convert child }
        false_children = node[:false_children].map{ |child| convert child }
        if node[:keyword] == 'unless'
          true_children, false_children = false_children, true_children
        end
        result = s(:if,
                  parse_with_context(node[:code]),
                  s(:begin,
                    *true_children),
                  s(:begin,
                    *false_children))
        if node[:print_output]
          s(:send,
            s(:send, nil, :xml), :<<, result)
        else
          result
        end
      elsif node[:type] == :text && (@preserve_whitespace || !node[:value].strip.empty?)
        s(:send,
          s(:send, nil, :xml), :<<,
            s(:str, node[:value]))
      elsif node[:type] == :text && !(@preserve_whitespace || !node[:value].strip.empty?)
        nil
      elsif node[:type] == :doctype
        if node[:value] == "<!DOCTYPE html>"
          parse_with_context("xml.declare!(:DOCTYPE, :html)")
        else
          raise "unsupported doctype"
        end
      else
        require 'pry';binding.pry
        raise "node type not supported yet"
      end
    end

    def convert_attributes(attributes)
      return nil if [nil, {}].include?(attributes)
      raise unless attributes.to_a.flatten.map{|n| n[:type]}.uniq == [:text] # No support for interpolated attributes yet
      result = attributes.map do |k,v|
        s(:pair, s(:str, k.first[:value]), s(:str, v.first[:value]))
      end
      s(:hash, *result)
    end

    def s(tag, *args)
      Astrolabe::Node.new(tag, args)
    end
  end
end