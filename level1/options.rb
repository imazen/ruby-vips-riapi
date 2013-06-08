# Layout instructions for rendering.
module Options
  Background = Struct.new(:x, :y, :w, :h, :color)
  Crop       = Struct.new(:x, :y, :w, :h)
  Load       = Struct.new(:shrink_factor)
  Resize     = Struct.new(:wfactor, :hfactor)
end
