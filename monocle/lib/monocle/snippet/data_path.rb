module Monocle
  class Snippet
    class DataPath < Array
      def initialize(*paths)
        path = paths.map {|p| p.is_a?(Enumerable) ? p : p.to_s.split('.')}.flatten
        super(path)
      end

      def +(other)
        super(DataPath.new(other))
      end

      def concat(*others)
        super(DataPath.new(*others))
      end

      def to_selector
        join('.')
      end
    end
  end
end