#!/usr/bin/ruby

# implement level l of the riapi spec, see:
# https://github.com/riapi/riapi/blob/master/level-1.md

require 'level1/layout'
require 'level1/render'

module ImageResizer
  def self.resize_image(input_path, output_path, params)
    layout = Layout.lay_out_image(input_path, params)
    Render.resize_image(input_path, output_path, layout)
  end
end


