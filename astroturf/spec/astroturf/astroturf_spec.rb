require_relative '../spec_helper'
require_relative '../../lib/astroturf'

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

describe Astroturf do
  it "replace node by xpath" do
    path = fixture_path('tmp.rb')
    File.delete(path) if File.exist?(path)
    File.write(path, "# test \n def a b=1 ; puts b ; end")
    turf = Astroturf.parse_file(path)

    Astroturf.replace_by_xpaths(turf, ["//int-node"]) do |n| 
      Astroturf.parse((n.children.last + 2).to_s)
    end

    assert_equal "# test \n def a b=3 ; puts b ; end", File.read(path)
    File.delete(path)
    # compare against fixture
  end
end
