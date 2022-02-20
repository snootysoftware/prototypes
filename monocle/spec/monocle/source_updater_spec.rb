require_relative '../spec_helper'
require_relative '../../lib/monocle'

describe Monocle::SourceUpdater do
  make_my_diffs_pretty!

  it 'should update an empty AST correctly' do
    target = 'puts 1'
    updated = Monocle::SourceUpdater.update('', target)
    assert_equal(updated, target)
  end

  it 'should update an empty AST with comment correctly' do
    source = '# TODO'
    target = 'puts 1'
    updated = Monocle::SourceUpdater.update(source, target)
    assert_equal(updated, [source,target].join("\n"))
  end

  it 'should correctly update to an empty AST' do
    assert_equal(Monocle::SourceUpdater.update('any_code', ''), '')
  end

  Dir[fixture_path('source_updater/*')].map {|n| File.basename(n) }.each do |fixture_name|
    it "should correctly update #{fixture_name}" do
      f = {}
      %w(pre target post).each do |name|
        f[name.to_sym] = read_fixture("source_updater/#{fixture_name}/#{name}.rb")
      end
      result = Monocle::SourceUpdater.update(f[:pre], f[:target])
      assert_equal(f[:post], result)

      # test if all comments are preserved
      pre, pre_comments = Monocle::RubyParser.parse_with_comments(f[:pre])
      post, post_comments = Monocle::RubyParser.parse_with_comments(f[:post])
      assert_equal(pre_comments.map(&:text), post_comments.map(&:text) - Monocle::SourceUpdater::ExplanationComments.values)
    end
  end
end