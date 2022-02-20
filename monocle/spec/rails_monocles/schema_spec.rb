require_relative '../spec_helper'
require_relative '../../lib/rails_monocles'

Parser::Builders::Default.emit_lambda = true # opt-in to most recent AST format

$trace_point.enable
$trace_point2.enable

describe RailsMonocles::Schema do
  it "should convert ast into dst" do
    expected = {
      "models" => [ {
        "name" => "Dog",
        "fields" => [
          { "name" => "name", "type" => "string" },
          { "name" => "created_at", "type" => "datetime" },
          { "name" => "updated_at", "type" => "datetime" },
          { "name" => "owner_id", "type" => "integer" }
        ]
      } ]
    }
    mutator = RailsMonocles::Schema.new
    dst = mutator.code2dst(read_fixture('schema.rb'))
    assert_equal(expected, dst)
  end
end
