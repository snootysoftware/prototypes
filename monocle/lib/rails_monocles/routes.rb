module RailsMonocles
  class Routes
    include Monocle::BaseMutator

    snippet(:root) do
      sample_code <<-RUBY
        Rails.application.routes.draw do
          placeholder_0
          placeholder_1
          placeholder_2
        end
      RUBY

      match_on "result"

      def match_0? ast
        if ast.children[1].to_s == 'devise_for'
          update_dst('result.authentication', true)
        end
      end

      def replace_0
        query_dst('result.authentication') ? 'devise_for :users' : ''
      end

      placeholder 1, type: :child_snippets, only: [:resources], linked_array: 'result.entities'

      def match_2? ast
        true
      end

      def replace_2
        if first = query_dst('result.entities').first
          "root \"#{first['name'].pluralize.underscore}#index\""
        else
          ''
        end
      end
    end

    snippet(:resources) do
      sample_code <<-RUBY
        resources placeholder_0
      RUBY

      match_on "name"

      def match_0? ast
        return false unless ast.type == :sym
        update_dst("name", ast.children.first.to_s.singularize.camelize)
      end

      def replace_0
        ":" + query_dst("name").pluralize.underscore
      end
    end

  end
end