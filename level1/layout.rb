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

  def self.lay_out_image(path, params)
    image = Image.new path
    info = ImageInfo.new
    info.width          = image.x_size
    info.height         = image.y_size
    info.shrink_on_load = path.end_with? '.jpg' # ugly
    info.has_alpha      = path.end_with? '.png' # ugly
    process(info, params)
  end

  # params are expected to conform to RIAPI
  def self.process(info, params)
    if !params.include?(:width) && !params.include?(:height)
      # when neither width nor height are given, do nothing
      {}
    else
      params = params.dup

      # keep aspect ratio, if width is omited
      if !params.include?(:width)
        params[:width] = params[:height] * info.width / info.height
      end

      # keep aspect ratio, if height is omited
      if !params.include?(:height)
        params[:height] = params[:width] * info.height / info.width
      end

      # initialize sizes
      wanted_size = Size.new(params[:width], params[:height]) # requested image size
      source_size = Size.new(info.width, info.height)           # original image size
      target_size = Size.new(-1, -1)                            # eventual image size
      canvas_size = Size.new(-1, -1)                            # canvas size
      crop_size   = source_size                                 # size of the cropped image

      # process mode
      case params[:mode]
      when :max
        target_size = canvas_size = source_size.scale_inside(wanted_size)
      when :pad
        canvas_size = wanted_size
        target_size = source_size.scale_inside canvas_size
      when :crop
        target_size = canvas_size = wanted_size
        crop_size = canvas_size.scale_inside source_size
      when :stretch
        target_size = canvas_size = wanted_size
      else
        raise ArgumentError, "missing or invalid mode option"
      end

      # process scale
      case params[:scale]
      when :down
        if crop_size.fits_inside? target_size
          target_size = canvas_size = crop_size = source_size
        end
      when :both
        nil
      when :canvas
        if crop_size.fits_inside? target_size
          target_size = crop_size = source_size
        end
      else
        raise ArgumentError, "missing or invalid scale option"
      end

      layout = {}

      # process cropping
      if crop_size != source_size
        x = 0.5 * (crop_size.width  - source_size.width)
        y = 0.5 * (crop_size.height - source_size.height)
        w = crop_size.width
        h = crop_size.height
        layout[:crop] = Options::Crop.new(x, y, w, h)
      end

      # process padding
      if canvas_size != target_size
        x = 0.5 * (canvas_size.width  - target_size.width)
        y = 0.5 * (canvas_size.height - target_size.height)
        w = canvas_size.width
        h = canvas_size.height
        color = info.has_alpha ? :alpha : :white
        layout[:bg] = Options::Background.new(x, y, w, h, color)
      end

      #process resizing
      wfactor = target_size.width  / crop_size.width
      hfactor = target_size.height / crop_size.height

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
