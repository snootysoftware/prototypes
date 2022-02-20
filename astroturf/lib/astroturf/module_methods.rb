
module Astroturf

  def self.parse(str, with_comments=false)
    buffer = Parser::Source::Buffer.new('(string)')
    buffer.source = str
    builder = Builder.new
    parser = Parser::CurrentRuby.new(builder)

    res = with_comments ? parser.parse_with_comments(buffer) : parser.parse(buffer)

    res ? Turf.new(res, buffer) : false
  end

  def self.parse_with_comments(str)
    parse str, true
  end

  def self.parse_file path
    result = parse(File.read(path))
    result.path = path
    result
  end

  def self.parse_file_with_comments path
    result = parse_with_comments(File.read(path))
    result.path = path
    result
  end

  def self.insert_line turf, index, line
    path = turf.path
    arr = File.read(path).split("\n")
    arr.insert(index, line)
    File.open(path,'w') {|f| f.write(arr.join("\n"))}
    turf.reload!
  end

  # Obviously messing around with regex to remove unnecessary parentheses
  # (unparser seems to sprinkle parentheses a lot to be safe) is dangerous.
  # Which doesn't matter at all, because in #replace_node we verify that
  # the prettified source still parses to the same AST as the original src.

  def self.seattle_style str
    # convert "format.html do\n  bla\nend" to "format.html { bla }":
    # .gsub(/ do$\s+(.*?)$\s*end$/m,' { \1 }')
    str.sub('(', ' ').sub(')', '')
  end

  def self.replace_by_xpaths(turf, xpaths)
    result = turf
    xpaths.each do |xpath|
      if result.xpath(xpath).count > 1
        raise 'TODO: Fix multiple xpath matches in a snippet' 
      end
      node = result.xpath(xpath).first
      if node
        result = Astroturf.replace_node(result, node, yield(node) )
        result = result.is_a?(String) ? Astroturf.parse(result) : result
      end
    end
    result
  end

  def self.replace_node turf, old_node, new_node
    content = Unparser.unparse(new_node)
    seattle_content = seattle_style(content)

    src = SendNodeReplacer.new(old_node, content)
      .rewrite(turf.buffer, turf)
    pretty_src = SendNodeReplacer.new(old_node, seattle_content)
      .rewrite(turf.buffer, turf)
      
    result = parse(src) == parse(pretty_src) ? pretty_src : src

    if turf.path
      File.open(turf.path, 'w') do |f|
        f.write result
      end

      turf.reload!
    else
      result
    end

  end

  def self.replace_lines turf, node, new_content
    src = File.read(turf.path).split("\n")
    start, finish = node.loc.line - 2, node.loc.last_line
    File.open(turf.path, 'w') do |f|
      f.write (src[0..start] + [new_content] + src[finish..-1]).join("\n")
    end
  end

  def self.remove_node turf, node
    source = SendNodeReplacer.new(node, '').rewrite(turf.buffer, turf)
    File.open(turf.path, 'w') { |f| f.write source }
    turf.reload!
  end

end
