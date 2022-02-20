module Monocle
  $trace_indent = 0
  $trace_point = TracePoint.new(:call) do |t| # event type specification is optional

    cl = "#{t.defined_class}.#{t.method_id}"
    if $extensive_mutator_logging && t.path.include?('lib/monocle') && !cl.include?("BaseMutator::ClassMethods.snippets") && !cl.include?("BaseMutator.snippets") && !cl.include?("sample_code") && !cl.include?("DSTExtractor.initialize") && !cl.include?("MultiNodeBuilder")
      puts "#{'  ' * $trace_indent}calling #{cl}"
      $trace_indent += 1
    end
  end
  $trace_point2 = TracePoint.new(:return) do |t| # event type specification is optional

    cl = "#{t.defined_class}.#{t.method_id}"
    if $extensive_mutator_logging && t.path.include?('lib/monocle') && !cl.include?("BaseMutator::ClassMethods.snippets") && !cl.include?("BaseMutator.snippets") && !cl.include?("sample_code") && !cl.include?("DSTExtractor.initialize") && !cl.include?("MultiNodeBuilder")
      $trace_indent -= 1
      puts "#{'  ' * $trace_indent}returning #{t.return_value} from #{cl}"
    end
  end
end