require 'unparser'
require 'parser/current'
require 'hashie'
require 'nokogiri'
require 'nokogumbo'
require 'htmlcompressor'

module ERB2Builder
  require_relative 'erb2builder/erb2xml'
  require_relative 'erb2builder/erb_deconstruct'
  require_relative 'erb2builder/intermediate_view'
  require_relative 'erb2builder/view'
  require_relative 'erb2builder/builder2erb'
  require_relative 'erb2builder/erb2builder'
end
