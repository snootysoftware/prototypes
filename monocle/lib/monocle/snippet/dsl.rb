module Monocle
  class Snippet

    def self.sample_code(str)
      @sample_code = str
    end

    def self.sample_code_erb(str)
      @sample_code = Unparser.unparse(ERB2Builder::Erb2Builder.parse_without_whitespace(str))
    end

    def self.match_on(data_path, options={})
      define_method(:can_generate_code?) do
        puts "Current snippet: #{name}" if ENV['DEBUG']
        value = query_dst(data_path)
        options[:value] ? options[:value] == value : value
      end

      define_method(:on_match) do
        if options[:default_value]
          update_dst(data_path, options[:default_value]) unless query_dst(data_path)
        elsif options[:value]
          update_dst(data_path, options[:value])
        end
      end
    end

    def self.placeholder(id, options)
      meth = :"placeholder_#{options[:type]}"
      if respond_to?(meth)
        send(meth, id, options)
      else
        raise ArgumentError, "Unsupported placeholder type '#{options[:type]}'"
      end
    end

    def self.placeholder_const_or_symbol(id, options)
      define_replacer(id) do
        if options[:match]
          self.instance_exec(&options[:match])
        elsif options[:data_path]
          query_dst(options[:data_path]).to_sym
        else
          raise 'Invalid options'
        end
      end

      define_matcher(id, options) do |ast|
        if options[:match]
          result = self.instance_exec(&options[:match]).to_sym
          result == ast
        elsif options[:data_path]
          update_dst(options[:data_path], ast.to_s)
          true
        else
          raise 'Invalid options'
        end
      end
    end

    class << self
      alias_method :placeholder_const, :placeholder_const_or_symbol
      alias_method :placeholder_symbol, :placeholder_const_or_symbol
    end

    def self.placeholder_child_snippets_or_list_of_methods(id, options)
      get_snippets = Proc.new do |mutator|
        snippet_names = [options[:only], options[:child_snippets]].flatten.compact
        snippet_names.map do |name|
          raise "Missing snippet: #{name}" if mutator.snippets[name].nil?
          [name, mutator.snippets[name]]
        end
      end

      define_replacer(id) do
        generated_code_pieces = []
        data_path_prefix = DataPath.new(@data_path_prefix, options[:data_path_prefix])

        if options[:linked_array]
          query_dst(options[:linked_array])&.size&.times do |linked_array_index|
            data_path = DataPath.new(data_path_prefix, options[:linked_array], linked_array_index)
            result = nil
            get_snippets.call(mutator).flat_map {|s| s.last}.each do |klass|
              success, result = klass.new(self.mutator).dst2code(@dst, data_path)
              break if success
            end
            raise MissingChildSnippetsError if result.nil?
            generated_code_pieces << result
          end
        else
          get_snippets.call(mutator).each do |snippet_name, snippets|
            result = nil
            snippets.each do |klass|
              success, result = klass.new(mutator).dst2code(@dst, data_path_prefix)
              break if success
            end

            if options[:required] == :all && result.nil?
              # TODO raising is not correct here, or we need to rescue somewhere else.
              # For example, we could have multiple root snippets, and if in the first one we can't
              # find all the child snippets, we should try the second one, instead of just erroring.
              raise MissingChildSnippetsError, "Snippet #{snippet_name} not found, but all child snippets were required."
            end

            generated_code_pieces << result
          end
        end
        {replace_entire_node: true, result: generated_code_pieces.join("\n")}
      end

      define_matcher(id, options) do |ast|
        data_path_prefix = DataPath.new(@data_path_prefix, options[:data_path_prefix])
        snippets = get_snippets.call(mutator).flat_map {|s| s.last}
        snippets.any? do |klass|
          data_path = options[:linked_array] ? DataPath.new(data_path_prefix, options[:linked_array], @ast_for_snippet_count) : data_path_prefix
          success, result = klass.new(mutator).ast2dst(ast, @dst, data_path)
          # TODO: proper response format instead of this hacky stuff
          if result[:result][:__ignore_in_linked_array]
            @ast_for_snippet_count -= 1
          else
            @dst = result
          end
          success
        end
      end
    end

    class << self
      alias_method :placeholder_child_snippets, :placeholder_child_snippets_or_list_of_methods
      alias_method :placeholder_list_of_methods, :placeholder_child_snippets_or_list_of_methods
    end

    def self.placeholder_ivar(id, options)
      define_replacer(id) { "@" + self.instance_exec(&options[:match]) }
      define_matcher(id, options) do |ast|
        ast.children.first.to_s == ("@" + self.instance_exec(&options[:match]))
      end
    end

    def self.placeholder_send(id, options)
      if options[:data_path]
        define_replacer(id) { query_dst(options[:data_path]) }
        define_matcher(id, options) do |ast|
          update_dst(options[:data_path], ast.children.last.to_s)
          true
        end
      elsif options[:match]
        define_replacer(id) { self.instance_exec(&options[:match]) }
        define_matcher(id, options) do |ast|
          ast.children.last.to_s == self.instance_exec(&options[:match]).to_s
        end
      else
        raise 'no supported option found'
      end
    end

    def self.placeholder_method_name(id, options)
      if options[:data_path]
        define_replacer(id) { query_dst(options[:data_path]) }
      else
        define_replacer(id) { self.instance_exec(&options[:match]) }
        define_matcher(id, options) do |ast|
          ast.children.first.to_s == self.instance_exec(&options[:match]).to_s
        end
      end
    end

    def self.placeholder_block_arg(id, options)
      define_replacer(id) { self.instance_exec(&options[:match]) }
      define_matcher(id, options) do |ast|
        ast.to_s == self.instance_exec(&options[:match]).to_s
      end
    end

    def self.placeholder_string(id, options)
      define_replacer(id) do
        {type: :string, result: query_dst(options[:data_path])}
      end
      define_matcher(id, options) do |ast|
        if ast.type == :str
          value = ast.children.first
          value = value.strip if options[:strip]
          update_dst(options[:data_path], value) if options[:data_path]
          true
        end
      end
    end

    def self.placeholder_list_of_symbols(id, options)
      define_replacer(id) do
        symbols = query_dst(options[:data_path]).map(&:to_sym).map(&:inspect).join(', ')
        {replace_entire_node: true, result: symbols }
      end
      define_matcher(id, options) do |ast|
        if ast.map(&:type).uniq == [:sym] || ast == []
          update_dst(options[:data_path], ast.map(&:children).map(&:first).map(&:to_s))
        end
      end
    end

    def self.define_replacer id, &block
      define_method(:"replace_#{id}", &block)
    end

    def self.define_matcher id, options, &block
      define_method(:"match_options_#{id}") { options }
      define_method(:"match_#{id}?", &block)
    end
  end
end
