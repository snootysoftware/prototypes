module RailsMonocles
  class ApplicationController
    include Monocle::BaseMutator

    snippet(:root) do
      sample_code <<~RUBY
        class ApplicationController < ActionController::Base
          placeholder_0
        end
      RUBY

      match_on "result"

      def match_0? ast
        if ast.children.last&.children&.last == :authenticate_user!
          update_dst('result.authentication', true)
        end
      end

      def replace_0
        query_dst('result.authentication') ? 'before_action :authenticate_user!' : ''
      end
    end
  end
end