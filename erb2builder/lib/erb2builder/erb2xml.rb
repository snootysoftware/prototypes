require 'treetop'

# TODO put this in the right name space so we don't pollute the global one
Treetop.load(File.join(File.dirname(__FILE__), 'simple_erb.treetop'))

module ERB2Builder
  class Erb2xml
    RandomToken = 'GXWPeq29fONtpJrjAMKQA'
    ErbMatcher  = /(#{Erb2xml::RandomToken}-erb-(?:print|eval)-snippet_index-\d+-strip_whitespace-(?:false|true)|.+?)/m
    attr_reader :snippets, :xml
    def initialize(str)
      parser = SimpleERBParser.new

      @snippets = []
      @xml = ''
      parser.parse(str).content.each do |n|
        if n.first == :text
          @xml += n.last
        elsif n.first == :erb
          snippets << n.last
          @xml += "<!-- #{RandomToken}-erb-#{n.last[2] == '=' ? 'print' : 'eval'}-snippet_index-#{snippets.size - 1}-strip_whitespace-#{n.last[-3] == '-' ? 'false' : 'true'} -->"
        elsif :element
          n.last.scan(/(<%.*?%>|.)/m).flatten.each do |m|
            if m.size == 1
              @xml += m
            else
              snippets << m
              @xml += "#{RandomToken}-erb-#{m[2] == '=' ? 'print' : 'eval'}-snippet_index-#{snippets.size - 1}-strip_whitespace-#{m[-3] == '-' ? 'false' : 'true'}"
            end
          end
        else
          raise '???'
        end

      end
    end
  end
end