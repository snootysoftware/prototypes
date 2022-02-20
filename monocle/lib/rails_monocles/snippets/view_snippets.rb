module RailsMonocles
  module ViewSnippets
    def self.included(klass)
      klass.instance_eval do

        snippet(:custom_code) do
          sample_code <<-RUBY
            placeholder_0
          RUBY

          def match_0? ast
            return false if ast.children[0..1] == [s(:send, nil, :xml), :<<] &&
                            ast.children.last.type == :str &&
                            ast.children.last.children.last.strip == ""
            iv = ERB2Builder::Builder2Erb.parse(Unparser.unparse(ast))
            erb = ERB2Builder::IntermediateView.reconstruct_erb(iv)
            update_dst('custom_code', erb)
          end

          def replace_0
            Unparser.unparse ERB2Builder::Erb2Builder.parse_without_whitespace(query_dst('custom_code'))
          end
        end

        snippet(:title) do
          #sample_code <<-RUBY
          #  xml.h1 do
          #    xml << placeholder_0
          #  end
          #RUBY

          sample_code_erb <<-ERB
            <h1 class="title"><%= placeholder_0 %></h1>
          ERB

          match_on "title"
          placeholder 0, type: :string, data_path: "title", strip: true
        end

        snippet(:action_link) do
          sample_code <<-RUBY
            xml << link_to(placeholder_0, placeholder_1)
          RUBY

          match_on "link_to.action"

          def replace_0
            return unless action = query_dst('link_to.action')
            case action
            when 'index'
              "'#{mutator.model_name.pluralize}'"
            when 'new'
              "'New #{mutator.model_name}'"
            end
          end

          def match_0? ast
            ast.type == :str
          end

          def replace_1
            return unless action = query_dst('link_to.action')
            case action
            when 'index'
              "#{mutator.model_name.pluralize.underscore}_path"
            when 'new'
              "new_#{mutator.model_name.underscore}_path"
            end
          end

          def match_1? ast
            action = case (ast.children.first||ast.children[1]).to_s
            when "#{mutator.model_name.pluralize.underscore}_path"
              'index'
            when "new_#{mutator.model_name.underscore}_path"
              'new'
            end
            update_dst('link_to.action', action) unless action.nil?
            return !action.nil?
          end
        end
      end
    end
  end
end
