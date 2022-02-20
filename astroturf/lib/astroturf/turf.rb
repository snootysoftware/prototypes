module Astroturf
  class Turf < SimpleDelegator
    attr_accessor :buffer, :path

    def initialize tree, buffer, path=nil
      @buffer, @path = buffer, path
      super tree
    end

    def reload!
      if __getobj__.is_a?(Node)
        result = Astroturf.parse_file(path)
      else
        result = Astroturf.parse_file_with_comments(path)
      end

      __setobj__(result.__getobj__)
      self.buffer = result.buffer
    end
  end
end