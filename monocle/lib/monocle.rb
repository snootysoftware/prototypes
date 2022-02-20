require 'astrolabe'
require 'unparser'
require 'active_support/core_ext/object/deep_dup'

require_relative '../../erb2builder/lib/erb2builder'

module Monocle
  require_relative 'monocle/ruby_parser'
  require_relative 'monocle/code_generator'
  require_relative 'monocle/dst_extractor'
  require_relative 'monocle/base_mutator'
  require_relative 'monocle/snippet/data_path'
  require_relative 'monocle/snippet'
  require_relative 'monocle/source_updater'
  require_relative 'monocle/tracing'

  def self.extract_placeholder_id(node_id)
    id = node_id.to_s
    # remove '@' from the front of the id if necessary
    id = id[1..-1] if id[0] == '@'
    # return match or nil if there is no match
    $1 if id =~ /^[Pp]laceholder_(\w+)$/
  end
end