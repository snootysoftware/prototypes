require_relative '../spec_helper'
require_relative '../../lib/rails_monocles'

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

describe RailsMonocles::Routes do
  let(:mutator) { RailsMonocles::Routes.new }

  it "should convert routes dst into ast" do
    result = mutator.dst2code(json_fixture("routes.json"))
    assert_equal_ast(read_fixture('routes.rb'), result)
  end

  it "should convert routes ast into dst" do
    dst = mutator.code2dst(read_fixture('routes.rb'))
    assert_equal(json_fixture("routes.json"), dst)
  end

  it "add devise routes" do
    result = mutator.dst2code(json_fixture("routes_with_devise.json"))
    assert_equal_ast(read_fixture('routes_with_devise.rb'), result)
  end

  it "toggle authentication based on devise routes" do
    dst = mutator.code2dst(read_fixture('routes_with_devise.rb'))
    assert_equal(json_fixture("routes_with_devise.json"), dst)
  end
end