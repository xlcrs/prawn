module Prawn
  class Canvas
    include Prawn::Chunkable

    def initialize(state)
      @chunks = []
      @state  = state
      synchronize_state
    end

    def synchronize_state
      self.set_line_width(state.drawing.line_width)
    end

    attr_accessor :chunks, :state

    chunk_methods :move_to, :line_to, :line, :stroke, :fill,
                  :curve_to, :curve, :rectangle, :ellipse, :circle, 
                  :polygon, :rounded_vertex, :rounded_polygon, :rounded_rectangle,
                  :set_line_width

    alias_method :line_width=, :set_line_width

    def move_to!(params)
      chunk(:move_to, params) do |c|
        raw_chunk("%.3f %.3f m" % c[:point])
      end
    end

    def line_to!(params)
      chunk(:line_to, params) do |c|
        raw_chunk("%.3f %.3f l" % c[:point])
      end
    end

    def curve_to!(params)
      unless params[:bound1] && params[:bound2]
        raise Prawn::Errors::InvalidGraphicsPath
      end

      chunk(:curve_to, params) do |c|
        raw_chunk("%.3f %.3f %.3f %.3f %.3f %.3f c" % (c[:bound1] + c[:bound2] + c[:point]))
      end
    end

    def curve!(params)
      chunk(:curve, params) do |c|
        [ move_to!(:point   => c[:point1]),
          curve_to!(:point  => c[:point2],
                    :bound1 => c[:bound1],
                    :bound2 => c[:bound2]) ]

      end
    end
    
    KAPPA = 4.0 * ((Math.sqrt(2) - 1.0) / 3.0)

    def ellipse!(params)
      chunk(:ellipse, params) do |c|
        x, y = c[:point]
        r1   = c[:x_radius]
        r2   = c[:y_radius]

        l1 = r1 * KAPPA
        l2 = r2 * KAPPA

        start          =  move_to!(:point => [x + r1, y])

        to_upper_right = curve_to!(:point  => [x,  y + r2],
                                   :bound1 => [x + r1, y + l1], 
                                   :bound2 => [x + l2, y + r2])
        to_upper_left = curve_to!(:point => [x - r1, y],
                                  :bound1 => [x - l2, y + r2],
                                  :bound2 => [x - r1, y + l1])
        
        to_lower_left = curve_to!(:point => [x, y - r2],
                                  :bound1 => [x - r1, y - l1], 
                                  :bound2 => [x - l2, y - r2])

        to_lower_right = curve_to!(:point  => [x + r1, y],
                                   :bound1 => [x + l2, y - r2], 
                                   :bound2 => [x + r1, y - l1])

        back_to_start = move_to!(:point => [x,y])

        [start, to_upper_right, to_upper_left,
                to_lower_left,  to_lower_right, back_to_start]
      end
    end

    def circle!(params)
      chunk(:circle, params) do |c|
        ellipse!(:point    => c[:point],
                 :x_radius => c[:radius],
                 :y_radius => c[:radius]) 
                    
      end
    end

    def line!(params)
      chunk(:line, params) do |c|
        [ move_to!(:point => c[:point1]), 
          line_to!(:point => c[:point2]) ]
      end
    end

    def stroke!
      chunk(:stroke) { raw_chunk("S") }
    end

    def fill!
      chunk(:fill) { raw_chunk("F") }
    end

    def fill_and_stroke!
      chunk(:fill_and_stroke) { raw_chunk("b") }
    end

    def line_width
      find_chunks(:command => :set_line_width).last[:width]
    end

    def set_line_width!(width)
      chunk(:set_line_width, :width => width) do |c|
        state.drawing.line_width = c[:width]
        raw_chunk("#{c[:width]} w")
      end
    end
     
    def rectangle!(params)
      chunk(:rectangle, params) do |c|
        x,y = c[:point]
        y  -= c[:height]

        raw_chunk(
          "%.3f %.3f %.3f %.3f re" % [ x, y, c[:width], c[:height] ])
      end
    end

    def polygon!(params)
      chunk(:polygon, params) do |c|
        out = [move_to!(:point =>  c[:points].first)]
        (c[:points][1..-1] << c[:points].first).each do |point|
          out << line_to!(:point => point)
        end
        out + [raw_chunk("h")]
      end
    end

    def rounded_polygon!(params)
      chunk(:rounded_polygon, params) do |c|
         out    = [move_to!(:point => point_on_line(c[:radius], c[:points][1], c[:points][0]))]
         sides  = c[:points].size
         points = c[:points] + [c[:points][0], c[:points][1]]
         
         sides.times do |i|
           out << rounded_vertex!(:radius => c[:radius], 
                                  :point1 => points[i],
                                  :point2 => points[i+1],
                                  :point3 => points[i + 2])
         end

         out + [raw_chunk("h")]
      end
    end
    
    def rounded_vertex!(params)
      chunk(:rounded_vertex, params) do |c|
        x0,y0  = [:point1]
        x1,y1  = c[:point2]
        x1,y2  = c[:point3]
        radius = c[:radius]

        radial_point_1 = point_on_line(radius, c[:point1], c[:point2])
        bezier_point_1 = point_on_line((radius - radius*KAPPA), c[:point1], c[:point2])
        radial_point_2 = point_on_line(radius, c[:point3], c[:point2])
        bezier_point_2 = point_on_line((radius - radius*KAPPA), c[:point3], c[:point2])

        [ line_to!(:point => radial_point_1),
          curve_to!(:point  => radial_point_2, 
                    :bound1 => bezier_point_1,
                    :bound2 => bezier_point_2) ]

      end
    end

    def rounded_rectangle!(params)
      chunk(:rounded_rectangle, params) do |c|
        x,y = c[:point]
        width, height, radius = c[:width], c[:height], c[:radius]
        rounded_polygon!(:radius => radius,
                         :points => [[x,y],[x + width, y],[x + width, y-height],[x, y - height]])
      end
    end

    private

    def degree_to_rad(angle)
       angle * Math::PI / 180
    end
    
    def point_on_line(distance_from_end, *points)
      x0,y0,x1,y1 = points.flatten
      length = Math.sqrt((x1 - x0)**2 + (y1 - y0)**2)
      p = (length - distance_from_end) / length
      xr = x0 + p*(x1 - x0)
      yr = y0 + p*(y1 - y0)
      [xr, yr]
    end
   
  end
end
