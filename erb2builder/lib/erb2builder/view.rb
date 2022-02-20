require 'slim/erb_converter'
require 'rexml/document'

require_relative '../../../astroturf/lib/astroturf'

module ERB2Builder
  class MultilineErbTagsError < Exception; end
  class HTML5ParseError < Exception; end
  class MissingTBodyTagError < Exception; end
  class UnexpectedERBError < Exception; end

  class View
    include REXML

    attr_reader :path

    def self.from_file path
      new(path, File.read(path))
    end

    def initialize(path, src)
      @path = path
      @src = src
      if path.split('.').last == 'slim'
        @src = Slim::ERBConverter.new({disable_escape: true}).call(@src)
      end
      @xml = Erb2xml.new(@src)
      @snippets = ErbDeconstruct.new(@src).snippets

      @index2line = []
      counter = 0
      xml_snippets.map(&:strip).each do |snippet|
        @index2line << []
        @index2line.last << (counter += 1)
        snippet.scan(/\n/m).flatten.size.times do
          @index2line.last << (counter += 1)
        end
      end
      # ap xml_snippets.map(&:strip)#@index2line
      # puts @xml.xml
      # puts @src
      # puts parse_html5(@xml.xml).to_s

      @tree = Astroturf.parse(@snippets.map(&:strip).join("\n"))
      #ap @tree
      xml_snippets.each do |code|
        if code =~ /\A\s*#/
          # TODO rewrite error message to something that doesn't refer to defunct products this library came from 
          raise UnexpectedERBError, "Sorry, we currently don't support ERB comments. We're on it, but in the meantime please remove ERB comments if you want to convert using textractor."
        end
      end
      raise unless xml_snippets.map(&:strip) == @snippets.map(&:strip)
  # TODO also ensure that there is only one ERB tag per line, since we can't handle more
      @doc = parse_html5(@xml.xml)
      if !@xml.xml.include?("<tbody>") && @doc.to_s.include?("<tbody>")
        raise UnexpectedERBError, "Sorry, we currently don't support <table> tags that do not use the <tbody> tag. We're on it, but in the meantime please add a <tbody> tag if you want to convert this template."
      end
  #    require 'pry'; binding.pry
    end

    def intermediate_view
      IntermediateView.new(@doc, @tree, @snippets, @index2line).result
    end

    def parse_html5(str)
      res = Nokogiri::HTML5(str)
      if res.errors.first&.to_s&.include?(": The doctype must be the first token in the document.")
        res = Nokogiri::HTML5("<!doctype html><html><head></head><body>#{str}</body></html>")
        if res.errors.empty?
          res.children.last.children.last
        else
          # TODO rewrite error message to something that doesn't refer to defunct products that this library came from 
          raise UnexpectedERBError, "Oops, unable to infer a valid HTML5 structure. If your template looks like a valid HTML5 partial, contact us at "
        end
      else
        res
      end
    end

    def xml_snippets
      @xml.snippets.map do |s|
        s.sub(/^<%(=|-)?/,'').sub(/-?%>$/,'')
      end
    end
  end
end