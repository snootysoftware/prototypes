require_relative '../spec_helper'
require_relative '../../lib/monocle'

describe Monocle::Snippet::DataPath do
  DataPath = Monocle::Snippet::DataPath

  it 'should be constructable with no arguments' do
    assert_equal(0, DataPath.new().length)
  end

  it 'should be constructable with a nil argument' do
    assert_equal(0, DataPath.new(nil).length)
  end

  it 'should be constructable from an array' do
    assert_equal(0, DataPath.new([]).length)
    assert_equal(1, DataPath.new(['a']).length)
    assert_equal(2, DataPath.new(['a','b']).length)
  end

  it 'should be constructable from a string' do
    assert_equal(0, DataPath.new('').length)
    assert_equal(1, DataPath.new('foo').length)
    assert_equal(2, DataPath.new('foo.bar').length)
  end

  it 'should be constructable from multiple arguments' do
    assert_equal(0, DataPath.new(nil, nil).length)
    assert_equal(1, DataPath.new(nil, ['a'], nil, []).length)
    assert_equal(2, DataPath.new('foo.bar', nil, []).length)
  end

  it 'should concatenate with all compatible types' do
    assert_equal(['a'], DataPath.new('a') + nil)
    assert_equal(['a'], DataPath.new('a') + [])
    assert_equal(['a'], DataPath.new + ['a'])
    assert_equal(['a'], DataPath.new + 'a')
    assert_equal(['a','b'], DataPath.new + DataPath.new(['a','b']))
  end

  it 'should concat with all compatible types' do
    path = DataPath.new
    path.concat(nil)
    assert_equal([], path)
    path.concat('a')
    assert_equal(['a'], path)
    path.concat('b.c')
    assert_equal(['a','b','c'], path)
    path.concat(['d'])
    assert_equal(['a','b','c','d'], path)
  end

end