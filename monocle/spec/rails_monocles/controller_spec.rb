require_relative '../spec_helper'
require_relative '../../lib/rails_monocles'

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

describe RailsMonocles::Controller do
  let(:mutator) { RailsMonocles::Controller.new }

  it "should convert dst into ast" do
    result = mutator.dst2code(json_fixture("dst.json"))
    assert_equal_ast(read_fixture('posts_controller.rb'), result)
  end

  it "should produce proper indentation" do
    ruby_code = mutator.dst2code(json_fixture("dst.json"))
    assert_equal(read_fixture('posts_controller.rb'), ruby_code)
  end

  it "should convert ast into dst" do
    dst = mutator.code2dst(read_fixture('posts_controller.rb'))
    assert_equal(json_fixture("dst.json"), dst)
  end

  it "should support a list of objects redirect" do
    dst = mutator.code2dst(read_fixture('list_of_objects_controller.rb'))
    assert_equal(json_fixture("list_of_objects.json"), dst)
  end

  it "should convert ast into dst" do
    dst = mutator.code2dst(read_fixture("authors_controller.rb"))
    assert_equal({ "model" => "Author", "default_allowed_fields" => [] }, dst)
  end
end
