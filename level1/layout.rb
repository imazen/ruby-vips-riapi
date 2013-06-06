require 'level1/options'

module Layout
  ImageInfo = Struct.new(:width, :height, :shrink_on_load, :has_alpha)

  def self.process(path, options)
    image = Image.new path
    info = ImageInfo.new
    info.width          = image.x_size
    info.height         = image.y_size
    info.shrink_on_load = path.end_with? '.jpg' # ugly
    info.alpha          = path.end_with? '.png' # ugly
    process_info(info, options)
  end

  def self.process_info(info, options)
    if !options.include?(:width) && !options.include?(:height)
      # when neither width or height are given, do nothing
      {}
    else
      options = options.dup

      if !options.include?(:width)
        # keep aspect ratio
        options[:width] = options[:height] * info.width / info.height
      end

      if !options.include?(:height)
        # keep aspect ratio
        options[:height] = options[:width] * info.height / info.width
      end

      w = options[:width]
      h = options[:height]
      u = info.width.to_f / w
      v = info.height.to_f / h

      case @mode
      when :max
        u = [u, v].min
        v = u
      when :pad
        u = [u, v].max
        v = u
      when :crop
        u = [u, v].max
        v = u
        w = u * w
        h = v * h
      when :stretch
        nil
      end

      layout = {}

      if u != 1 || v != 1
        layout[:resize] = Options::Resize.new(1.0 / u, 1.0 / v)
      end

      layout
    end
  end
end
