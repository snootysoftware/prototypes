module RailsMonocles
  class Model
    include Monocle::BaseMutator

    snippet(:root) do
      sample_code <<-RUBY
        class Placeholder_0 < ApplicationRecord
          placeholder_1
          placeholder_2
        end
      RUBY

      match_on "result"
      placeholder 1, type: :child_snippets,
                    only: [:belongs_to, :has_one, :has_many, :has_many_through, :has_and_belongs_to_many],
                    linked_array: 'result.associations'
      placeholder 2, type: :child_snippets,
                    only: [:presence],
                    linked_array: 'result.validations'

      def match_0?(ast)
        result[:name] = ast.to_s
        true
      end

      def replace_0
        result[:name].camelize
      end
    end

    snippet(:belongs_to) do
      sample_code <<~RUBY
        belongs_to :placeholder_0
      RUBY

      match_on "type", value: 'belongs_to'

      def replace_0
        query_dst('model').underscore
      end

      def match_0? ast
        update_dst('model', ast.to_s)
      end
    end

    snippet(:has_one) do
      sample_code <<~RUBY
        has_one :placeholder_0
      RUBY

      match_on "type", value: 'has_one'

      def replace_0
        query_dst('model').underscore
      end

      def match_0? ast
        update_dst('model', ast.to_s)
      end
    end

    snippet(:has_many) do
      sample_code <<~RUBY
        has_many :placeholder_0
      RUBY

      match_on "type", value: 'has_many'

      def replace_0
        query_dst('model').underscore.pluralize
      end

      def match_0? ast
        update_dst('model', ast.to_s.singularize)
      end
    end

    snippet(:has_many_through) do
      sample_code <<~RUBY
        has_many :placeholder_0, through: :placeholder_1
      RUBY

      match_on "type", value: 'has_many_through'

      def replace_0
        query_dst('model').underscore.pluralize
      end

      def match_0? ast
        update_dst('model', ast.to_s.singularize)
      end

      def replace_1
        query_dst('through').underscore.pluralize
      end

      def match_1? ast
        update_dst('through', ast.to_s.singularize)
      end
    end

    snippet(:has_and_belongs_to_many) do
      sample_code <<~RUBY
        has_and_belongs_to_many :placeholder_0
      RUBY

      match_on "type", value: 'has_and_belongs_to_many'

      def replace_0
        query_dst('model').underscore.pluralize
      end

      def match_0? ast
        update_dst('model', ast.to_s.singularize)
      end
    end

    snippet(:presence) do
      sample_code <<~RUBY
        validates :placeholder_0, presence: true
      RUBY

      match_on "type", value: 'presence'

      def match_0?(ast)
        update_dst('presence', ast.to_s)
      end
    end
  end
end
