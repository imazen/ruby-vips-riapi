#!/usr/bin/ruby

# implement level l of the riapi spec, see:
# https://github.com/riapi/riapi/blob/master/level-1.md

require 'logger'

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG


require 'rubygems'
require 'vips'

require './level1/process'

include VIPS

class RIAPI
    attr_reader :width
    attr_reader :height
    attr_reader :mode
    attr_reader :scale

    MODES = [:max, :pad, :crop, :stretch]
    SCALES = [:down, :both, :canvas]

    def initialize(input, options = {})
        $log.info "RIAPI init"

        @input = input

        @im = Image.open_seq @input

        self.width = options[:width] || @im.x_size
        self.height = options[:height] || @im.y_size
        self.mode = options[:mode] || :pad
        self.scale = options[:scale] || :down
    end

    def mode=(mode_v)
        unless MODES.include?(mode_v)
            raise ArgumentError, "mode must be one of: #{MODES.join ', '}"
        end

        @mode = mode_v
    end

    def scale=(scale_v)
        unless SCALES.include?(scale_v)
            raise ArgumentError, "scale must be one of: #{SCALES.join ', '}"
        end

        @scale = scale_v
    end

    def good_dimension(dim)
        dim > 0 and dim.to_i == dim and dim < 10000
    end

    def width=(width_v)
        unless good_dimension width_v
            raise ArgumentError, "invalid width"
        end

        @width = width_v
    end

    def height=(height_v)
        unless good_dimension height_v
            raise ArgumentError, "invalid height"
        end

        @height = height_v
    end

    def calculate_resize
        w = @width
        h = @height
        u = @im.x_size.to_f / w
        v = @im.y_size.to_f / h

        $log.info "resize mode #{@mode}"

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

        $log.info "shrink of #{u}, #{v}; crop of #{w}, #{h}" 

        return w, h, u, v
    end

    def process(filename)
        w, h, u, v = calculate_resize

        # jpeg images can be shrunk very quickly during load by a factor of 2, 
        # 4 or 8
        #
        # if this is a jpeg, turn on shrink-on-load 
        if Image.jpeg?(@input) and h == v
            if h >= 8
                load_shrink = 8
            elsif h >= 4
                load_shrink = 4
            elsif h >= 2
                load_shrink = 2
            end

            @im = Image.open_seq @input, load_shrink

            # and recalculate the shrink we need, since the dimensions have 
            # changed
            w, h, u, v = calculate_resize
        end

        a = @im.resize(u, v)

        # crop down to w x h ... centre a w x h rectangle over the image, find
        # the intersection 

        final = Rect.new 0, 0, w, h
        im = Rect.new 0, 0, a.x_size, a.y_size
        crop = Rect.new im.xc - final.xc, im.yc - final.yc, w, h
        down = im.intersect crop
        $log.info "crop #{down.inspect}" 
        a = a.extract_area down.left, down.top, down.width, down.height

        # the conv will have to look back a few scanlines
        a = a.tile_cache(a.x_size, 1, 8)

        # the downsize will look a little "soft", apply a gentle sharpen
        a = a.sharp

        # pad up to the final size ... centre within the final output rect

        im = Rect.new 0, 0, a.x_size, a.y_size
        pos = Rect.new final.xc - im.xc, final.yc - im.yc, w, h
 
        if Image.png?(filename)
            fill = :alpha
        else
            fill = :white
        end
        a = a.pad fill, pos

        a.write(filename)
    end
end


