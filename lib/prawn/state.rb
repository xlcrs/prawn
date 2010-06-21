require "prawn/state/drawing"

module Prawn
  class State

    def initialize
      @drawing = ::Prawn::State::Drawing.new
    end

    attr_reader :drawing
  end
end
