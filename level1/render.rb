require 'level1/options'

require 'vips'
include VIPS

# Performs the actual image resizing.
module Render

  # Resizes an image, given a layout.
  #
  # @param input_path  [String] Relative path to the image file to resize.
  # @param output_path [String] Relative path to store the resized image.
  # @param options [Hash<String, Object>] Layout instructions.
  #
  # @return [void]
  def self.resize_image(input_path, output_path, options)
    image = open       input_path, options
    image = crop       image, options
    image = resize     image, options
    image = background image, options
    image.write(output_path)
  end

  # Opens an image, considering Options.Load instructions.
  # @return [Image]
  def self.open(path, options)
    case
    when path.end_with?('.jpg') && options.include?(:load)
        Image.jpeg(path, :shrink_factor => options[:load].shrink_factor, :sequential => true)
    when path.end_with?('.jpg')
        Image.jpeg(path, :shrink_factor => 1, :sequential => true)
    when path.end_with?('.tif')
      Image.tiff(path, :sequential => true)
    when path.end_with?('.png')
      Image.png(path, :sequential => true)
    else
      Image.new(path)
    end
  end

  # Crops an image, considering Options.Crop instructions.
  # @param image [Image]
  # @return [Image]
  def self.crop(image, options)
    if options.include? :crop
      opts = options[:crop]
      image.embed(:white, opts.x, opts.y, opts.w, opts.h)
    else
      image
    end
  end

  # Resizes an image, considering Options.Resize instructions.
  # @param image [Image]
  # @return [Image]
  def self.resize(image, options)
    if options.include? :resize
      opts = options[:resize]
      image.affinei_resize(:bicubic, opts.wfactor, opts.hfactor)
    else
      image
    end
  end

  # Adds a background to an image, considering Options.Background instructions.
  # @param image [Image]
  # @return [Image]
  def self.background(image, options)
    # aw, shucks, ruby-vips does not support draw_rectangle
    if options.include? :bg
      opts = options[:bg]
      image.embed(opts.color, opts.x, opts.y, opts.w, opts.h)
    else
      image
    end
  end
end
