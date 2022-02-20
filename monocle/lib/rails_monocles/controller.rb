module RailsMonocles
  class Controller
    include Monocle::BaseMutator

    # Each snippet has a name, in this case "root". There can be multiple snippets
    # with the same name, we just keep trying until the first one that matches.
    # Root is a special case, those are the snippets that the AST is initially matched
    # against. Other snippet types are then matched from within the placeholders, using
    # the "child_snippets" type.

    snippet(:root) do

      # Each snippet contains sample code. This is just a string containing Ruby code.
      # For longer snippets we use the <<-RUBY HEREDOC syntax, since most editors will
      # then highlight the sample code as well.

      # The sample code contains placeholder identifiers for all dynamic aspects.
      # The placeholder identifier can be anything that matches /^\w+$/.
      # When parsing or templating, whenever a placeholder is encountered, we call the
      # "match_x?" or "replace_x" method, where x is the placeholder identifier.

      # Since defining these methods gets very tedious very quickly, in most cases we can
      # just use the "placeholder" method, which takes a description of the data type and
      # required action. It then generates "match_" and "replace_" methods under the hood.

      sample_code <<~RUBY
        class Placeholder_classname < ApplicationController
          before_action :placeholder_set_method_name, only: [:show, :edit, :update, :destroy]

          placeholder_public_methods

          private

            placeholder_private_methods
        end
      RUBY

      # There is only one root snippet, so it should always match.

      match_on "result"

      # Placeholder 0 is a special case, let's handle the standard things first.

      # Placeholder 1 is a symbol that matches "set_post", and it grabs the "post"
      # part from the class name (which has already been parsed by the
      # "placeholder 0" methods when this code is run).

      placeholder :set_method_name, type: :symbol, match: -> { "set_#{result[:model].underscore}" }

      # Placeholder 2 can consist of any of the snippets listed. You'll find those
      # snippets further below in this file. Since these methods do not all have to
      # be defined, they are optional.

      placeholder :public_methods, type: :list_of_methods,
                    child_snippets: [:index, :show, :new, :edit, :create, :update, :destroy]

      # Placeholder 3 are the private methods, which *are* all required.

      placeholder :private_methods, type: :list_of_methods,
                    required: :all,
                    child_snippets: [:set_model, :model_params]

      # We need to extract the model name from the controller name and put
      # it in the context for parsing child_snippets. This is the one case
      # that gets too complicated to express cleanly in the DSL, so we break
      # out to a custom converter method.

      def match_classname?(ast)
        result[:model] = ast.to_s.sub(/Controller$/, '').singularize

        # Throughout the controller, we need to match on various permutations of
        # the model, so we store it in the context for later use.
        context[:model] = result[:model]
        true
      end

      # When we convert back to AST, it's the same problem, again, we break
      # out to a custom converter method.

      def replace_classname
        context[:model] = result[:model]
        result[:model].pluralize + "Controller"
      end
    end

    snippet(:index) do
      sample_code <<~RUBY
        def index
          @placeholder_0 = Placeholder_1.all
        end
      RUBY

      match_on "result.actions.index", default_value: {}
      placeholder 0, type: :ivar,  match: -> { context[:model].underscore.pluralize }
      placeholder 1, type: :const, match: -> { context[:model] }
    end

    snippet(:show) do
      sample_code <<~RUBY
        def show
        end
      RUBY

      match_on "result.actions.show", default_value: {}
    end

    snippet(:new) do
      sample_code <<~RUBY
        def new
          @placeholder_0 = Placeholder_1.new
        end
      RUBY

      match_on "result.actions.new", default_value: {}
      placeholder 0, type: :ivar,  match: -> { context[:model].underscore }
      placeholder 1, type: :const, match: -> { context[:model] }
    end

    snippet(:edit) do
      sample_code <<~RUBY
        def edit
        end
      RUBY

      match_on "result.actions.edit", default_value: {}
    end

    snippet(:create) do
      sample_code <<~RUBY
        def create
          @placeholder_0 = Placeholder_1.new(placeholder_2)

          respond_to do |format|
            if @placeholder_0.save
              format.html { redirect_to placeholder_3, notice: placeholder_4 }
              format.json { render :show, status: :created, location: placeholder_3 }
            else
              format.html { render :new }
              format.json { render json: @placeholder_0.errors, status: :unprocessable_entity }
            end
          end
        end
      RUBY

      match_on "result.actions.create", default_value: {}
      placeholder 0, type: :ivar,  match: -> { context[:model].underscore }
      placeholder 1, type: :const, match: -> { context[:model] }
      placeholder 2, type: :send, match: -> { "#{context[:model].underscore}_params" }
      placeholder 3, type: :child_snippets,
                    only: [:url],
                    data_path_prefix: "result.actions.create.on_success.url",
                    required: :all
      placeholder 4, type: :string, data_path: "result.actions.create.on_success.set_notice"
    end

    snippet(:update) do
      sample_code <<~RUBY
        def update
          respond_to do |format|
            if @placeholder_0.update(placeholder_1)
              format.html { redirect_to @placeholder_2, notice: placeholder_3 }
              format.json { render :show, status: :ok, location: @placeholder_2 }
            else
              format.html { render :edit }
              format.json { render json: @placeholder_0.errors, status: :unprocessable_entity }
            end
          end
        end
      RUBY

      match_on "result.actions.update", default_value: {}
      placeholder 0, type: :ivar,  match: -> { context[:model].underscore }
      placeholder 1, type: :send, match: -> { "#{context[:model].underscore}_params" }
      placeholder 2, type: :child_snippets,
                    only: [:url],
                    data_path_prefix: "result.actions.update.on_success.url",
                    required: :all
      placeholder 3, type: :string, data_path: "result.actions.update.on_success.set_notice"
    end

    snippet(:destroy) do
      sample_code <<~RUBY
        def destroy
          @placeholder_0.destroy
          respond_to do |format|
            format.html { redirect_to placeholder_1, notice: placeholder_2 }
            format.json { head :no_content }
          end
        end
      RUBY

      match_on "result.actions.destroy", default_value: {}
      placeholder 0, type: :ivar,  match: -> { context[:model].underscore }
      placeholder 1, type: :child_snippets,
                    only: [:url],
                    data_path_prefix: "result.actions.destroy.on_success.url",
                    required: :all
      placeholder 2, type: :string, data_path: "result.actions.destroy.on_success.set_notice"
    end

    snippet(:set_model) do
      sample_code <<~RUBY
        def placeholder_0
          @placeholder_1 = Placeholder_2.find(params[:id])
        end
      RUBY

      placeholder 0, type: :method_name,  match: -> { "set_#{context[:model].underscore}" }
      placeholder 1, type: :ivar,  match: -> { context[:model].underscore }
      placeholder 2, type: :const, match: -> { context[:model] }
    end

    snippet(:model_params) do
      sample_code <<~RUBY
        def placeholder_0
          params.require(:placeholder_1).permit(placeholder_2)
        end
      RUBY

      placeholder 0, type: :method_name,  match: -> { "#{context[:model].underscore}_params" }
      placeholder 1, type: :symbol, match: -> { context[:model].underscore }
      placeholder 2, type: :list_of_symbols, data_path: "result.default_allowed_fields"
    end

    snippet(:url) do
      sample_code "@placeholder_0"
      match_on "helper", value: "processed_object"
      placeholder 0, type: :ivar, match: -> { context[:model].underscore }
    end

    snippet(:url) do
      sample_code "placeholder_0"
      match_on "helper", value: "list_of_objects"
      placeholder 0, type: :send, match: -> { "#{context[:model].underscore.pluralize}_url" }
    end
  end
end