module RailsMonocles
  class IndexView
    include Monocle::BaseMutator
    include ViewSnippets
    include ViewFormSnippets

    attr_reader :model_name

    def initialize model_name: ''
      @model_name = model_name
    end

    def code2dst_preprocess(code)
      "nop do \n #{code}\n end"
    end

    def dst2code_postprocess(code)
      Unparser.unparse(Monocle::RubyParser.parse(code).children.last)
    end

    snippet(:root) do
      sample_code <<-RUBY
      nop do
        placeholder_0
      end
      RUBY

      match_on "result"
      placeholder 0, type: :child_snippets, only: [:table, :form, :title, :action_link, :custom_code], linked_array: 'result.components'
    end

    snippet(:table) do
      sample_code_erb <<-ERB
        <table class="table is-bordered is-striped is-narrow is-hoverable is-fullwidth">
          <thead>
            <tr>
              <% placeholder_3 %>
            </tr>
          </thead>
          <tbody>
            <% @placeholder_0.each do |placeholder_1| %>
              <tr>
                <% placeholder_2 %>
              </tr>
            <% end %>
          </tbody>
        </table>
      ERB

      def can_generate_code?
        query_dst("table.columns")&.present?
      end

      placeholder 1, type: :block_arg, match: -> { mutator.model_name.underscore }
      placeholder 2, type: :child_snippets, only: [:column], linked_array: 'table.columns'
      placeholder 3, type: :child_snippets, only: [:table_header], linked_array: 'table.columns'

      def match_0?(ast)
        context[:model] = ast.children.first.to_s.sub(/^@/,'').singularize.camelize

        context[:model] == mutator.model_name
      end

      def replace_0
        "@#{mutator.model_name.pluralize.underscore}"
      end
    end

    snippet(:table) do
      sample_code <<-RUBY
        xml.table("class" => "table is-bordered is-striped is-narrow is-hoverable is-fullwidth") do
          xml.thead do
            xml.tr
          end
          xml.tbody do
            @placeholder_0.each do |placeholder_1|
              xml.tr
            end
          end
        end
      RUBY

      match_on "table", default_value: {columns: []}
      placeholder 1, type: :block_arg, match: -> { mutator.model_name.underscore }

      def match_0?(ast)
        context[:model] = ast.children.first.to_s.sub(/^@/,'').singularize.camelize

        context[:model] == mutator.model_name
      end

      def replace_0
        "@#{mutator.model_name.pluralize.underscore}"
      end
    end


    snippet(:column) do
      sample_code <<-RUBY
              xml.td do
                xml << link_to(placeholder_0.placeholder_1, placeholder_2)
              end
      RUBY

      match_on 'content.link_to'

      placeholder 0, type: :send, match: -> { mutator.model_name.underscore }
      placeholder 1, type: :send, data_path: 'content.link_to.title_attribute'
      placeholder 3, type: :child_snippets, only: [:whitespace]

      def replace_2
        name = mutator.model_name.underscore
        "edit_#{name}_path(#{name})"
      end

      def match_2?(ast)
        name = mutator.model_name.underscore
        last = ast.children.last
        ast.send_type? && ast.children[1].to_s == "edit_#{name}_path" && (last.send_type? || last.lvar_type?) && last.children.last.to_s == name
      end
    end

    snippet(:column) do
      sample_code <<-RUBY
        xml.td("class" => "has-text-centered") do
          xml << button_to("Delete", { action: "destroy", id: placeholder_0.id }, method: :delete, data: { confirm: "Are you sure?" }, class: 'button is-danger' )
        end
      RUBY

      match_on 'content.actions', value: ["destroy"]

      placeholder 0, type: :send, match: -> { mutator.model_name.underscore }
    end

    snippet(:column) do
      sample_code <<-RUBY
              xml.td do
                xml << placeholder_0.placeholder_1
              end
      RUBY

      match_on 'content.text'

      placeholder 0, type: :send, match: -> { mutator.model_name.underscore }
      placeholder 1, type: :send, data_path: 'content.text.attribute'
    end

    snippet(:table_header) do
      sample_code <<-RUBY
              xml.th do
                xml << placeholder_0
              end
      RUBY

      match_on "header"

      placeholder 0, type: :string, data_path: "header", strip: true
    end

    snippet(:table_header) do
      sample_code <<-RUBY
              xml.th
      RUBY

      match_on "header", value: ""
    end
  end
end
