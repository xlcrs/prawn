module Prawn
  class State
    class Drawing
      PARAMETERS = [ :fill_color, :stroke_color, :color_space,
                     :line_width, :cap_style, :join_style, :dash ]

      def initialize(params={})
        Prawn.verify_options(PARAMETERS, params)
        params = { :line_width => 1 }.merge(params)

        params.each { |k,v| instance_variable_set("@#{k}", v) }
      end

      PARAMETERS.each { |k| attr_accessor(k) }
    end
  end
end


