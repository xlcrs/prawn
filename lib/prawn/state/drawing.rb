module Prawn
  class State
    class Drawing
      PARAMETERS = [ :fill_color, :stroke_color, :color_space,
                     :line_width, :cap_style, :join_style, :dash,
                     :stroke_color]

      def initialize(params={})
        Prawn.verify_options(PARAMETERS, params)
        params = { :line_width   => 1,
                   :stroke_color => "000000" }.merge(params)

        params.each { |k,v| instance_variable_set("@#{k}", v) }
      end

      PARAMETERS.each { |k| attr_accessor(k) }
    end
  end
end


