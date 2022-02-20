require_relative '../spec_helper'
require_relative '../../lib/rails_monocles'

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

describe RailsMonocles do
  describe "views" do
    it "should convert ast into dst" do
      {
        index: RailsMonocles::IndexView,
        form: RailsMonocles::FormView
      }.each do |action, mutator_class|
        mutator = mutator_class.new(model_name: 'Post')
        dst = mutator.code2dst(read_fixture("posts_#{action}.builder"))
        assert_equal(json_fixture("posts_#{action}_dst.json"), dst)
      end
    end

    it "should support dst without columns" do
      dst_fixture  = { "components" => [ { "table" => { "columns" => [ ] } } ] }
      erb = <<-EOL
        <table>
          <thead>
          <tr></tr>
          </thead>
          <tbody>
          <% @posts.each do |post| %>
          <tr></tr>
          <% end %>
          </tbody>
        </table>
      EOL
      builder = ERB2Builder::Erb2Builder.parse_without_whitespace erb
      source = Unparser.unparse builder
      mutator = RailsMonocles::IndexView.new(model_name: 'Post')

      dst = mutator.code2dst(source)
      assert_equal dst_fixture, dst
    end

    it "should handle custom code" do
      source = <<~RUBY
        xml.h1 do
         xml << 'foo'
        end
        xml.p do
          xml << 'bar'
        end
      RUBY

      mutator = RailsMonocles::IndexView.new(model_name: 'Post')
      dst = mutator.code2dst(source)
      fixture = {"components"=>[{"title"=>"foo"}, {"custom_code"=>"<p>bar</p>"}]}
      assert_equal fixture, dst
    end

    it "should handle newlines in a title" do
      source = <<~'RUBY'
        xml.h1 do
         xml << "\n  foo\n"
        end
      RUBY
      mutator = RailsMonocles::IndexView.new(model_name: 'Post')

      dst = mutator.code2dst(source)
      assert_equal({"components"=>[{"title"=>"foo"}]}, dst)
    end

    it "should convert dst into ast" do
      {
        index: RailsMonocles::IndexView,
        form: RailsMonocles::FormView
      }.each do |action, mutator_class|
        mutator = mutator_class.new model_name: 'Post'
        result = mutator.dst2code(json_fixture("posts_#{action}_dst.json"))
        assert_equal_ast(read_fixture("posts_#{action}_no_whitespace.builder"), result)
      end
    end

    it "should convert dst with custom code into ast" do
      dst = {"components"=>[{"title"=>"foo"}, {"custom_code"=>"<p>bar</p>"}]}
      builder = <<~RUBY
        xml.h1("class" => "title") do
          xml << "foo"
        end
        xml.p do
          xml << "bar"
        end
      RUBY
      mutator = RailsMonocles::IndexView.new model_name: 'Post'
      result = mutator.dst2code(dst)
      assert_equal(builder.strip, result)
    end
  end
end
