require 'level1/options'

require 'vips'
include VIPS

module Render
  def self.process(input_path, output_path, options)
    image = render_open       input_path, options
    image = render_crop       image, options
    image = render_resize     image, options
    image = render_background image, options
    image.write(output_path)
  end

  def self.render_open(path, options)
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

  def self.render_crop(image, options)
    if options.include? :crop
      opts = options[:crop]
      image.embed(:white, opts.x, opts.y, opts.w, opts.h)
    else
      image
    end
  end

  def self.render_resize(image, options)
    if options.include? :resize
      opts = options[:resize]
      image.affinei_resize(:bicubic, opts.wfactor, opts.hfactor)
    else
      image
    end
  end

  def self.render_background(image, options)
    # aw, shucks, ruby-vips does not support draw_rectangle
    if options.include? :bg
      opts = options[:crop]
      image.embed(opts.color, opts.x, opts.y, opts.w, opts.h)
    else
      image
    end
  end
end
