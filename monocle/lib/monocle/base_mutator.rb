require "hashie"
require 'active_support/core_ext/hash'

module Monocle
  module BaseMutator

    Registry = {}

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    def snippets()
      self.class.snippets
    end

    def code2dst(code)
      raise "No root snippet found" if (snippets[:root] || []).empty?

      code = code2dst_preprocess(code) if respond_to?(:code2dst_preprocess)
      ast = RubyParser.parse(code)
      raise 'invalid ruby in string' unless ast

      snippets[:root].each do |klass|
        dst = {result: {}, context: {}}.with_indifferent_access
        success, result = *klass.new(self).ast2dst(ast, dst)
        return result[:result] if success
      end
      raise "No matching root snippets found"
    end

    def dst2code(dst)
      dst = {result: dst, context: {}}.with_indifferent_access
      raise "No root snippet found" if (snippets[:root] || []).empty?
      snippets[:root].each do |klass|
        success, result = *klass.new(self).dst2code(dst)
        if success
          result = dst2code_postprocess(result) if respond_to?(:dst2code_postprocess)
          return result
        end
      end
      raise "No matching root snippets found"
    end

    module ClassMethods
      def snippet(n, &block)
        klass = Class.new(Snippet, &block)
        klass.instance_variable_set(:@name, n)
        klass.instance_variable_set(:@source_location, block.source_location)

        Registry[self.to_s] ||= {}
        Registry[self.to_s][n] ||= []
        Registry[self.to_s][n] << klass
      end

      def snippets()
        Registry[self.to_s]
      end
    end
  end
end