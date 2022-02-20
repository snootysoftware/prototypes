module RailsMonocles
  module ViewFormSnippets
    def self.included(klass)
      klass.instance_eval do
        snippet(:form) do
          sample_code <<-RUBY
            xml.div("class" => "columns") do
              xml.div("class" => "column is-half") do
                xml << simple_form_for(@placeholder_0 || Placeholder_1.new, defaults: { wrapper: false }) do |form|
                  placeholder_2
                  xml.div("class" => "field") do
                      xml.div("class" => "control") do
                        xml << form.submit(class: "button is-link")
                      end
                  end
                end
              end
            end
          RUBY

          match_on "form"
          placeholder 0, type: :ivar, match: -> { mutator.model_name.underscore.singularize }
          placeholder 1, type: :const, match: -> { mutator.model_name.camelize }
          placeholder 2, type: :child_snippets, only: [:text, :number, :checkbox, :association], linked_array: 'form.fields'
        end

        snippet(:text) do
          sample_code_erb <<-ERB
            <%= form.input :placeholder_1, label: placeholder_2  %>
          ERB

          match_on 'type', value: 'text'

          def match_1?(ast)
            update_dst('attribute', ast.to_s)
            true
          end

          def replace_1
            query_dst('attribute').to_sym
          end

          placeholder 2, type: :string, data_path: 'label'
        end

        snippet(:number) do
          sample_code_erb <<-ERB
            <%= form.input :placeholder_1, as: :numeric, label: placeholder_2  %>
          ERB

          match_on 'type', value: 'number'

          def match_1?(ast)
            update_dst('attribute', ast.to_s)
            true
          end

          def replace_1
            query_dst('attribute').to_sym
          end

          placeholder 2, type: :string, data_path: 'label'
        end

        snippet(:checkbox) do
          sample_code_erb <<-ERB
            <%= form.input :placeholder_1, wrapper: :boolean, label: placeholder_2  %>
          ERB

          match_on 'type', value: 'checkbox'

          def match_1?(ast)
            update_dst('attribute', ast.to_s)
            true
          end

          def replace_1
            query_dst('attribute').to_sym
          end

          placeholder 2, type: :string, data_path: 'label'
        end

        snippet(:association) do
          sample_code_erb <<-ERB
            <%= form.association(:placeholder_1, label: placeholder_2) %>
          ERB

          match_on 'type', value: 'association'

          def match_1?(ast)
            update_dst('attribute', ast.to_s)
            true
          end

          def replace_1
            query_dst('attribute').to_sym
          end

          placeholder 2, type: :string, data_path: 'label'
        end
      end
    end
  end
end
