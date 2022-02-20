require_relative '../spec_helper'
require_relative '../../lib/monocle'

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

$trace_point.enable
$trace_point2.enable

describe Monocle do
  describe 'extract_placeholder_id' do
    it 'should return nil given a non-matching string' do
      assert_nil(Monocle.extract_placeholder_id('henk'))
      assert_nil(Monocle.extract_placeholder_id('placeholder_'))
    end

    it 'should return the identifier given a matching string' do
      assert_equal(Monocle.extract_placeholder_id('placeholder_0'), '0')
      assert_equal(Monocle.extract_placeholder_id('placeholder_henk'), 'henk')
      assert_equal(Monocle.extract_placeholder_id('@placeholder_henk_en_annie'), 'henk_en_annie')
    end
  end

  describe 'dst2code' do
    it 'should throw a helpful error when a placeholder method is missing' do
      monocle_class = Class.new do
        include Monocle::BaseMutator

        snippet(:root) do
          sample_code "class Placeholder_henk ; end"
          match_on "result"
        end
      end

      monocle = monocle_class.new
      error = assert_raises(NoMethodError) do
        monocle.dst2code({})
      end
      assert_match(/undefined method `replace_henk' for #<Monocle::Snippet \(.*\)>/, error.message)
    end
  end
end

describe "my example app" do
  describe "controller" do

    it "should handle dst2code with nested module names with placeholders" do
      mutator_class = Class.new do
        include Monocle::BaseMutator

        snippet(:root) do
          sample_code "class Placeholder_0::Something::Placeholder_1 < ApplicationController ; end"
          match_on "result"

          def replace_0 ; "NumberZero" ; end
          def replace_1 ; "NumberOne" ; end
        end
      end

      mutator = mutator_class.new
      ast_fixture = "class NumberZero::Something::NumberOne < ApplicationController ; end"
      ast = mutator.dst2code({})
      assert_equal(ast_fixture, ast)
    end

    it "should handle dst2code with constants in defs" do
      mutator_class = Class.new do
        include Monocle::BaseMutator

        snippet(:root) do
          sample_code "class Cake ; placeholder_0 ; end"
          match_on "result"
          placeholder 0, type: :child_snippets, only: [:index]
        end

        snippet(:index) do
          sample_code "def cake ; @test = Placeholder_0.all ; end"
          match_on "result"
          def replace_0 ; "NumberZero" ; end
        end
      end

      mutator = mutator_class.new
      ast_fixture = "class Cake ; def cake ; @test = NumberZero.all ; end ; end"
      ast = mutator.dst2code({})
      assert_equal(ast_fixture, ast)
    end

    it "should handle dst2code with multiple root snippets with child snippets" do
      mutator_class = Class.new do
        include Monocle::BaseMutator

        snippet(:root) do
          sample_code "class Cake ; placeholder_0 ; end"
          match_on "result"
          placeholder 0, type: :child_snippets, required: :all, only: [:show]
        end

        snippet(:root) do
          sample_code "class Cake ; placeholder_0 ; end"
          match_on "result"
          placeholder 0, type: :child_snippets, required: :all, only: [:index]
        end

        snippet(:index) do
          sample_code "def cake ; @test = Placeholder_0.all ; end"
          match_on "result"
          def replace_0 ; "NumberZero" ; end
        end

        snippet(:show) do
          sample_code "def cake ; asdf ; end"
          match_on "result.something.else"
        end
      end

      mutator = mutator_class.new
      ast_fixture = "class Cake ; def cake ; @test = NumberZero.all ; end ; end"
      ast = mutator.dst2code({})
      assert_equal(ast_fixture, ast)
    end

    it "should handle dst2code with variable amount of methods" do
      mutator_class = Class.new do
        include Monocle::BaseMutator

        snippet(:root) do
          sample_code "class Cake ; placeholder_0 ; end"
          match_on "result"
          placeholder 0, type: :child_snippets, only: [:index, :show]
        end

        snippet(:index) do
          sample_code "def index ; end"
          match_on "result.index", default_value: {}
        end

        snippet(:show) do
          sample_code "def show ; end"
          match_on "result.show", default_value: {}
        end
      end
      dst_fixture = {"index" => {}, "show" => {}}
      source = "class Cake ; def index ; end ; def show ; end ; end"
      mutator = mutator_class.new
      dst = mutator.code2dst(source)
      assert_equal(dst_fixture, dst)
    end

    it "should handle dst2code with variable amount of block content" do
      mutator_class = Class.new do
        include Monocle::BaseMutator

        snippet(:root) do
          sample_code "cake do ; placeholder_0 ; end"
          match_on "result"
          placeholder 0, type: :child_snippets, only: [:index, :show]
        end

        snippet(:index) do
          sample_code "index"
          match_on "result.index", default_value: {}
        end

        snippet(:show) do
          sample_code "show"
          match_on "result.show", default_value: {}
        end
      end
      dst_fixture = {"index" => {}, "show" => {}}
      source = "cake do ; index ; show ; end"
      mutator = mutator_class.new
      dst = mutator.code2dst(source)
      assert_equal(dst_fixture, dst)
    end
  end
end
