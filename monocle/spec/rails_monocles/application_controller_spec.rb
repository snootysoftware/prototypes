require_relative '../spec_helper'
require_relative '../../lib/rails_monocles'
require_relative '../../lib/monocle/source_updater'

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

describe RailsMonocles::ApplicationController do
  let(:mutator) { RailsMonocles::ApplicationController.new }

  it "should convert dst into ast" do
    result = mutator.dst2code({})
    assert_equal_ast(read_fixture('application_controller.rb'), result)
  end

  it "should convert dst into ast using updater" do
    code_target = mutator.dst2code({ "authentication" => true })
    code_output = Monocle::SourceUpdater.update(read_fixture('application_controller.rb'), code_target)
    assert_equal_ast(read_fixture('application_controller_with_devise.rb'), code_output)
  end

  it "enable authentication" do
    result = mutator.dst2code({ "authentication" => true })
    assert_equal_ast(read_fixture('application_controller_with_devise.rb'), result)
  end

  it "should convert ast into dst" do
    dst = mutator.code2dst(read_fixture('application_controller.rb'))
    assert_equal({}, dst)
  end

  it "should toggle authentication based on before_action" do
    dst = mutator.code2dst(read_fixture('application_controller_with_devise.rb'))
    assert_equal({ "authentication" => true }, dst)
  end
end