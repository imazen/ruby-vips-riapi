require 'level1/options'

module Layout
  # helper class for holding image information
  ImageInfo = Struct.new(:width, :height, :shrink_on_load, :has_alpha)

  # helper class for working with sizes
  class Size < Struct.new(:width, :height)
    def initialize(width, height)
      self.width  = width.to_f
      self.height = height.to_f
    end

    def scale_inside(other)
      wratio = other.width  / width
      hratio = other.height / height
      ratio = [wratio, hratio].min
      Size.new(width * ratio, height * ratio)
    end

    def fits_inside?(other)
      width <= other.width && height <= other.height
    end
  end

  def self.process(path, options)
    image = Image.new path
    info = ImageInfo.new
    info.width          = image.x_size
    info.height         = image.y_size
    info.shrink_on_load = path.end_with? '.jpg' # ugly
    info.alpha          = path.end_with? '.png' # ugly
    process_info(info, options)
  end

  # options are expected to conform to RIAPI
  def self.process_info(info, options)
    if !options.include?(:width) && !options.include?(:height)
      # when neither width nor height are given, do nothing
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

      wanted_size = Size.new(options[:width], options[:height]) # requested image size
      source_size = Size.new(info.width, info.height)           # original image size
      target_size = Size.new(-1, -1)                            # eventual image size
      canvas_size = Size.new(-1, -1)                            # canvas size

      case options[:mode]
      when :max
        target_size = canvas_size = source_size.scale_inside(wanted_size)
      when :pad
        canvas_size = wanted_size
        target_size = source_size.scale_inside canvas_size
      when :crop
        target_size = canvas_size = wanted_size
        # TODO: compute crop rectangle
      when :stretch
        target_size = canvas_size = wanted_size
      else
        raise ArgumentError, "missing or invalid mode option"
      end

      case options[:scale]
      when :down
        if source_size.fits_inside? target_size
          target_size = canvas_size = source_size
          #adjust crop rectangle
        end
      when :both
        nil
      when :canvas
        if source_size.fits_inside? target_size
          target_size = source_size
          #adjust crop rectangle
        end
      else
        raise ArgumentError, "missing or invalid scale option"
      end

      layout = {}

      if canvas_size != target_size
        x = 0.5 * (target_size.width  - canvas_size.width)
        y = 0.5 * (target_size.height - canvas_size.height)
        w = canvas_size.width
        h = canvas_size.height
        layout[:bg] = Options::Background.new(x, y, w, h, :white)
      end

      wfactor = target_size.width  / source_size.width
      hfactor = target_size.height / source_size.height

      if wfactor != 1 || hfactor != 1
        if info.shrink_on_load
          f = compute_shrink_factor(wfactor, hfactor)
          if f > 1
            wfactor *= f
            hfactor *= f
            layout[:load] = Options::Load.new(f)
          end
        end
        layout[:resize] = Options::Resize.new(wfactor, hfactor)
      end

      layout
    end
  end

  # find the largest factor of 2 by which the shrink ratio could be reduced
  def self.compute_shrink_factor(wfactor, hfactor)
    raise ArgumentError, "non-positive wfactor: #{wfactor}" if wfactor <= 0
    raise ArgumentError, "non-positive hfactor: #{hfactor}" if hfactor <= 0

    f = 2
    while wfactor * f <= 1 && hfactor * f <= 1
      f *= 2
    end
    f / 2
  end
end
