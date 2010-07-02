module Prawn

  def Color(*a, &b)
    Prawn::Color.new(*a, &b)
  end

  class Color
    def self.hex2rgb(hex)
      r,g,b = hex[0..1], hex[2..3], hex[4..5]
      [r,g,b].map { |e| e.to_i(16) }
    end

    def self.rgb2hex(rgb)
      rgb.map { |e| "%02x" % e }.join
    end

    def initialize(color)
      @color = color
    end

    attr_reader :color

    def to_a
      rgb_array || cmyk_array
    end

    def to_pdf
      to_a.map { |c| '%.3f' % c }.join(' ')
    end

    def rgb_array
      return unless rgb?
      r,g,b = self.class.hex2rgb(color)
      [r/255.0, g/255.0, b/255.0]
    end

    def cmyk_array
      return unless cmyk_array?
    end

    def rgb?
      true
    end
    
    def cmyk?
      false
    end
  end
end
