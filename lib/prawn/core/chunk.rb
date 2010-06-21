module Prawn
  module Core

    class RawChunk
      def initialize(content)
        @content = content
        @command = :raw_pdf_text
        @params  = {}
      end

      attr_accessor :content, :command, :params
      alias_method  :to_pdf, :content
    end

    class Chunk
      def initialize(command, params={}, &action)
        @command      = command 
        @params       = params
        @action       = action
      end

      attr_reader :command, :params, :action

      def content
        action.call(self)
      end

      def to_pdf
        case results = content
        when Array
          results.map { |sub_chunk| sub_chunk.to_pdf }.join("\n")
        when Prawn::Core::Chunk, Prawn::Core::RawChunk
          results.to_pdf
        else
          raise "Bad Chunk: #{results.class} not supported"
        end
      end

      def [](attr)
        @params[attr]
      end

      def []=(attr, value)
        @params[attr] = value
      end
    end
  end
end
