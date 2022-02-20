module RailsMonocles
  class FormView
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
      placeholder 0, type: :child_snippets, only: [:form, :title, :custom_code], linked_array: 'result.components'
    end
  end
end
