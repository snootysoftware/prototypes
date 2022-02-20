module RailsMonocles
  class Schema
    include Monocle::BaseMutator

    snippet(:root) do
      sample_code <<~RUBY
        ActiveRecord::Schema.define(version: placeholder_0) do
          placeholder_1

        end
      RUBY

      def match_0?(ast)
        true
      end

      match_on "result"
      placeholder 1, type: :child_snippets, only: [:create_table, :add_foreign_key], linked_array: 'result.models'
    end

    snippet(:create_table) do
      sample_code <<~RUBY
        create_table placeholder_0, force: :cascade do |t|
          placeholder_1
        end
      RUBY

      def match_0?(ast)
        return unless ast.type == :str
        update_dst('name',ast.children.first.singularize.camelize)
        true
      end

      placeholder 1, type: :child_snippets, only: [:integer, :string, :datetime, :boolean, :decimal, :index], linked_array: 'fields'
    end

    snippet(:integer) do
      sample_code <<~RUBY
        t.integer placeholder_0
      RUBY

      match_on "type", default_value: 'integer'

      placeholder 0, type: :string, data_path: 'name'
    end

    snippet(:string) do
      sample_code <<~RUBY
        t.string placeholder_0
      RUBY

      match_on "type", default_value: 'string'

      placeholder 0, type: :string, data_path: 'name'
    end

    snippet(:string) do
      sample_code <<~RUBY
        t.string placeholder_0, default: "", null: false
      RUBY

      match_on "type", default_value: 'string'

      placeholder 0, type: :string, data_path: 'name'
    end

    snippet(:datetime) do
      sample_code <<~RUBY
        t.datetime placeholder_0
      RUBY

      match_on "type", default_value: 'datetime'

      placeholder 0, type: :string, data_path: 'name'
    end

    snippet(:datetime) do
      sample_code <<~RUBY
        t.datetime placeholder_0, null: false
      RUBY

      match_on "type", default_value: 'datetime'

      placeholder 0, type: :string, data_path: 'name'
    end

    snippet(:datetime) do
      sample_code <<~RUBY
        t.datetime placeholder_0, precision: 6, null: false
      RUBY

      match_on "type", default_value: 'datetime'

      placeholder 0, type: :string, data_path: 'name'
    end

    snippet(:boolean) do
      sample_code <<~RUBY
        t.boolean placeholder_0
      RUBY

      match_on "type", default_value: 'boolean'

      placeholder 0, type: :string, data_path: 'name'
    end

    snippet(:decimal) do
      sample_code <<~RUBY
        t.decimal placeholder_0
      RUBY

      match_on "type", default_value: 'decimal'

      placeholder 0, type: :string, data_path: 'name'
    end

    snippet(:index) do
      sample_code <<~RUBY
        t.index [placeholder_0], name: placeholder_1, unique: true
      RUBY

      match_on "type"

      placeholder 0, type: :string, data_path: 'name'

      def match_0? ast
        true
      end

      def match_1? ast
        true
      end
    end

    snippet(:add_foreign_key) do
      sample_code <<~RUBY
        add_foreign_key placeholder_0, placeholder_1
      RUBY

      match_on "type"

      placeholder 0, type: :string, data_path: 'from_table'
      placeholder 1, type: :string, data_path: 'to_table'

      def match_0? ast
        true
      end

      def match_1? ast
        true
      end
    end
  end
end
