require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/reporters'
require 'pry'
require 'ap'
require 'json'

Minitest::Reporters.use!

AwesomePrint.defaults = {
  indent: 2,
  index: false
}

$extensive_mutator_logging = ENV['DEBUG']

def caller_path(stack_frame_jump_count=0)
  caller_locations(stack_frame_jump_count+1)[0].path
end

def fixture_path(path, frame_skip_count=0)
  File.join(File.dirname(caller_path(frame_skip_count+1)), 'fixtures', path)
end

def read_fixture(path)
  File.read(fixture_path(path, 1))
end

def json_fixture(path)
  JSON.parse(File.read(fixture_path(path, 1)))
end

def ast_fixture(path)
  Monocle::RubyParser.parse_file(fixture_path(path, 1))
end

module Minitest::Assertions
  # Fails unless parse(exp) == parse(act)
  #
  # @param exp [String] Expected source
  # @param act [String] Actual source
  def assert_equal_ast(exp, act, msg = nil)
    exp_ast = Monocle::RubyParser.parse(exp)
    act_ast = Monocle::RubyParser.parse(act)
    assert_equal(exp_ast, act_ast, msg)
  end

  def assert_equal_json(exp, act, msg = nil)
    assert_equal(JSON.parse(exp), JSON.parse(act), msg)
  end
end