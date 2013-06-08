require 'level1/layout'
require 'level1/render'

# Main interface to image resizing.
module ImageResizer

  # Resizes an image using the level 1 RIAPI specification.
  #
  # @param input_path  [String] Relative path to the image file to resize.
  # @param output_path [String] Relative path to store the resized image.
  # @param params [Hash<Symbol, Symbol>] Resizing parameters. It is recommended
  #   to use ruby-riapi to generate these. The following keys are supported:
  #   * :width  - The desired image width (optional).
  #   * :height - The desired image height (optional).
  #   * :mode   - The constraint mode. Must be one of: :max, :pad, :crop, or :stretch.
  #   * :scale  - The scaling mode. Must be one of: :down, :both, or :canvas.
  #
  # @return [void]
  def self.resize_image(input_path, output_path, params)
    layout = Layout.lay_out_image(input_path, params)
    Render.resize_image(input_path, output_path, layout)
  end

end
