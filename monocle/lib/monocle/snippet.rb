require_relative 'snippet/dsl'

module Monocle
  class Snippet
    class MissingChildSnippetsError < Exception; end

    attr_reader :mutator
    attr_accessor :dst
    attr_accessor :ast_for_snippet_count

    def initialize(mutator)
      # When using child_snippets, we need to have a reference to the mutator that called us.
      @mutator = mutator
    end

    def sample_code
      self.class.instance_variable_get :@sample_code
    end

    def inspect
      location = self.class.instance_variable_get(:@source_location)
      "#<#{self.class.superclass.name} (#{location.join(':')})>"
    end

    # Examples of selectors: name, person.name, posts.2.title
    def query_dst(selector)
      path = DataPath.new(@data_path_prefix, selector)
      curr = @dst
      path.each do |part|
        return nil unless curr
        curr = curr[curr.is_a?(Array) ? part.to_i : part.to_sym]
      end
      curr
    end

    def update_dst(selector, value)
      path = DataPath.new(@data_path_prefix, selector)

      # Create intermediate objects as required, analog to mkdir -p
      curr = @dst
      path[0..-2].each_with_index do |part, index|
        part = curr.is_a?(Array) ? part.to_i : part.to_sym
        curr[part] ||= path[index+1] =~ /^\d+$/ ? [] : {}.with_indifferent_access
        curr = curr[part]
      end

      key = path.pop
      parent = query_dst(selector.sub(/(^[^\.]+|\.\w+)$/,''))
      parent[key] = value
    end

    def result
      @dst[:result]
    end

    def context
      @dst[:context]
    end

    # Override this method in subclasses to be more restrictive
    def can_generate_code?
      true
    end

    def ast2dst(ast, dst, data_path_prefix = nil)
      # If we didn't get a successful match, we don't want to retain the changes to the dst
      puts "Current snippet: #{name}" if ENV['DEBUG']
      @dst = dst.deep_dup
      @data_path_prefix = DataPath.new(data_path_prefix)
      success = DSTExtractor.new(self).extract_from(ast)
      on_match if respond_to?(:on_match) && success

      @dst = dst unless success
      return [success, @dst]
    end

    def dst2code(dst, data_path_prefix = nil)
      @dst = dst
      @data_path_prefix = DataPath.new(data_path_prefix)
      return [false, nil] unless can_generate_code?
      begin
        result = CodeGenerator.rewrite(self, dst, sample_code)
        [true, result]
      rescue MissingChildSnippetsError
        [false, nil]
      end
    end

    private

    def name
      self.class.instance_variable_get(:@name)
    end

    include Astrolabe::Sexp

  end
end