require 'level1/options'

# Converts RIAPI parameters into rendering instructions, so that the rendering
# module can be left with minimal logic.
module Layout

  # Helper class for holding image information.
  ImageInfo = Struct.new(:width, :height, :shrink_on_load, :has_alpha)

  # Helper class for working with floating-point sizes.
  class Size < Struct.new(:width, :height)

    # Initialize the class with given dimensions. Width and height have to
    # respond to *to_f*.
    def initialize(width, height)
      self.width  = width.to_f
      self.height = height.to_f
    end

    # Create the largest size that has the same proportions as the current one
    # and fits inside the size given.
    # @param other [Size]
    # @return [Size]
    def scale_inside(other)
      wratio = other.width  / width
      hratio = other.height / height
      if wratio < hratio
        Size.new(other.width, height * wratio)
      else
        Size.new(width * hratio, other.height)
      end
    end

    # Check that current dimensions not exceed the given size.
    # @param other [Size]
    def fits_inside?(other)
      width <= other.width && height <= other.height
    end
  end

  # Take the given image and RIAPI parameters and compute a layout for
  # rendering. Neither the image nor the parameters are modified.
  #
  # @param path [String] Relative path to the image file to resize.
  # @param params [Hash<Symbol, Symbol>] Resizing parameters.
  #
  # @return [Hash<Symbol, Object>]
  def self.lay_out_image(path, params)
    image = Image.new path
    info = ImageInfo.new
    info.width          = image.x_size
    info.height         = image.y_size
    info.shrink_on_load = path.end_with? '.jpg' # ugly
    info.has_alpha      = path.end_with? '.png' # ugly
    process(info, params)
  end

  # Performs the computations for *lay_out_image*, given the input image information.
  #
  # @param info [ImageInfo] Image information
  # @param params [Hash<Symbol, Symbol>] Resizing parameters.
  def self.process(info, params)
    if !params.include?(:width) && !params.include?(:height)
      {} # when neither width nor height are given, do nothing
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
      source_size = Size.new(info.width, info.height)         # original image size
      target_size = Size.new(-1, -1)                          # eventual image size
      canvas_size = Size.new(-1, -1)                          # canvas size
      crop_size   = source_size                               # size of the cropped image

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

  # Find the largest factor by which the shrink ratio could be reduced.
  #
  # From VIPS documentation:
  #  Shrink by this integer factor during load. Allowed values are 1, 2, 4 and
  #  8. Shrinking during read is very much faster than decompressing the whole
  #  image and then shrinking. 
  #
  # factor > 0; factor < 1 shinks, factor > 1 enlarges
  #
  # @param wfactor [Float] width resize factor
  # @param hfactor [Float] height resize factor
  #
  # @return [Fixnum]
  def self.compute_shrink_factor(wfactor, hfactor)
    raise ArgumentError, "non-positive wfactor: #{wfactor}" if wfactor <= 0
    raise ArgumentError, "non-positive hfactor: #{hfactor}" if hfactor <= 0

    case
    when wfactor > 0.5   || hfactor > 0.5   then 1
    when wfactor > 0.25  || hfactor > 0.25  then 2
    when wfactor > 0.125 || hfactor > 0.125 then 4
    else 8
    end
  end
end
