require_relative '../spec_helper'
require 'active_support/core_ext/hash'
require_relative '../../lib/monocle'

describe Monocle::Snippet do
  Snippet = Monocle::Snippet

  describe 'query_dst' do
    it "should traverse nested hashes" do
      snippet = Snippet.new nil
      snippet.instance_variable_set('@data_path_prefix', [])
      snippet.dst = { 'result': { model: 'Post' } }.with_indifferent_access
      assert_equal 'Post', snippet.query_dst('result.model')
    end

    it "should traverse nested arrays" do
      snippet = Snippet.new nil
      snippet.instance_variable_set('@data_path_prefix', [])
      snippet.dst = { 'result' => { 'columns' => [ { 'attribute' => 'title' } ] } }.with_indifferent_access
      assert_equal 'title', snippet.query_dst('result.columns.0.attribute')
    end
  end

  describe 'update_dst' do
    it "should update nested hashes" do
      snippet = Snippet.new nil
      snippet.instance_variable_set('@data_path_prefix', [])
      snippet.dst = { 'result': { model: 'Post' } }.with_indifferent_access
      snippet.update_dst('result.model', 'Author')
      assert_equal 'Author', snippet.query_dst('result.model')
    end

    it "should update nested arrays" do
      snippet = Snippet.new nil
      snippet.instance_variable_set('@data_path_prefix', [])
      snippet.dst = { 'result': { columns: [ { attribute: 'title' } ] } }.with_indifferent_access
      snippet.update_dst('result.columns.0.attribute', 'name')
      assert_equal 'name', snippet.query_dst('result.columns.0.attribute')
    end

    it "should update hashes within arrays" do
      snippet = Snippet.new nil
      snippet.instance_variable_set('@data_path_prefix', [])
      snippet.dst = { 'result': {} }.with_indifferent_access
      snippet.update_dst('result.columns.0.attribute', 'name')
      assert_equal({"result"=>{"columns"=>[{"attribute"=>"name"}]}}, snippet.dst)
      assert_equal 'name', snippet.query_dst('result.columns.0.attribute')
    end
  end

  describe 'placeholder' do
    it 'should raise an error when given an unsupported type option' do
      error = assert_raises ArgumentError do
        Class.new(Snippet) do
          placeholder 'foo', :type => :this_is_unsupported
        end
      end
      assert_equal("Unsupported placeholder type 'this_is_unsupported'", error.message)
    end
  end
end
