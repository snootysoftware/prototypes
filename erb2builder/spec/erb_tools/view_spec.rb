require_relative '../spec_helper'
require_relative '../../../astroturf/lib/astroturf' # TODO remove once astroturf is published as a gem that we can depend on instead
require_relative '../../lib/erb2builder'
#require_relative '../../../builder/lib/monocle/ruby_parser'

# FIXME: this breaks encapsulation (RailsMonocles::IndexView shouldn't be used here)
#require_relative '../../../builder/lib/rails_monocles'

include ERB2Builder

describe "conversion" do
  it "playground for testing" do 
    puts "===\n\n==="
    input = <<-EOL
      <h1>
        <% if @user %>
          Hello, <%= @user.name %>
        <% else %>
          Not logged in
        <% end %>
      </h1>
    EOL
     Erb2Builder.parse(input)
    output = Unparser.unparse(Erb2Builder.parse(input))
    puts Unparser.unparse(Erb2Builder.parse(input))
    # intermediate = Builder2Erb.parse(output)
    # puts IntermediateView.reconstruct_erb(intermediate, true)
  end

  it "should convert erb to builder" do
    input = read_fixture("application.html.erb")
    tmp = Erb2Builder.parse(input)
    output = Unparser.unparse(tmp)

    fixture = read_fixture("application.xml.builder")
    assert_equal(fixture, output)
  end

  it "should not crash on empty html tag" do
    input = <<-EOL
      <table>
      <tbody>
      <tr></tr>
      </tbody>
      </table>
    EOL
    builder = Erb2Builder.parse_without_whitespace(input)
    source = Unparser.unparse(builder)

    #mutator = RailsMonocles::IndexView.new(model_name: 'Post')
    #mutator.code2dst(source)
  end

  it "should convert builder to erb" do
    input = read_fixture("application.xml.builder")
    intermediate = Builder2Erb.parse(input)
    output = IntermediateView.reconstruct_erb(intermediate, true)

    fixture = read_fixture("fixture.html.erb")
    assert_equal(fixture, output)
  end

  it "should convert builder to erb and insert whitespace" do
    input = read_fixture("unindented_fixture.xml.builder")
    intermediate = Builder2Erb.parse(input)
    output = IntermediateView.reconstruct_erb(intermediate, true, indent: 0)
    fixture = read_fixture("indented_fixture.html.erb")
    assert_equal(fixture, output)
  end

  it "should convert erb with custom code to builder" do
    input = "<h1>hallo</h1><p>world</p>"
    tmp = Erb2Builder.parse(input)
    fixture = Parser::CurrentRuby.parse("xml.h1 { xml << 'hallo'}; xml.p { xml << 'world'}")
    output = Unparser.unparse(tmp)
    assert_equal Unparser.unparse(fixture), output
  end

  it "should support local variable assigns" do
    input = "xml.p do foo = bar end"
    intermediate = Builder2Erb.parse(input)
    output = IntermediateView.reconstruct_erb(intermediate, true)
    fixture = "<p><% foo = bar %></p>"
    assert_equal fixture, output
  end

  it "should convert builder with custom code to erb" do
    input = "xml.h1 { xml << 'hallo'}; xml.p { xml << 'world'}"
    intermediate = Builder2Erb.parse(input)
    output = IntermediateView.reconstruct_erb(intermediate, true)

    fixture = "<h1>hallo</h1><p>world</p>"
    assert_equal(fixture, output)
  end

  it "should support local variable assigns" do
    input = <<-EOF
    xml << form_with do |form|
      xml.div("class" => "field")
    end
    EOF
    intermediate = Builder2Erb.parse(input)
    output = IntermediateView.reconstruct_erb(intermediate, true)
    fixture = "<%= form_with do |form| %><div class=\"field\"></div><% end %>"
    assert_equal fixture, output
  end

  it "should convert erb with custom code to builder" do
    input = "<%= a do |b| %><%= b.c %><% end %>"
    tmp = Erb2Builder.parse(input)
    fixture = Parser::CurrentRuby.parse("xml << \"\"; xml << a do |b| ; xml << \"\"; xml << b.c ; xml << \"\" ; end")
    output = Unparser.unparse(tmp)
    assert_equal Unparser.unparse(fixture), output
  end

  it "should convert erb to builder" do
    input = read_fixture("application2.html.erb")
    compressor = HtmlCompressor::Compressor.new(
      preserve_patterns: [HtmlCompressor::Compressor::SERVER_SCRIPT_TAG_PATTERN],
      remove_intertag_spaces: true
    )
    input = compressor.compress(input)
    tmp = Erb2Builder.parse_without_whitespace(input)
    output = Unparser.unparse(tmp)

    puts output
    puts "\n\n\n========\n\n\n"

    input = output
    intermediate = Builder2Erb.parse(input)
    output = IntermediateView.reconstruct_erb(intermediate, true)

    #fixture = File.read(File.join(File.dirname(__FILE__),"fixture.html.erb"))
    #assert_equal(fixture, output)
    puts output
  end
end
