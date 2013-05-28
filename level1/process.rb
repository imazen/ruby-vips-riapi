#!/usr/bin/ruby

# helper class over ruby-vips for the operations we need for riapi

require 'logger'

$log = Logger.new(STDOUT)
$log.level = Logger::DEBUG

require 'rubygems'
require 'vips'

include VIPS

class Image
  # we apply a slight sharpen on downsize, since bicubic tends to soften 
  # images slghtly
  @@mask = [
    [-1, -1,  -1],
    [-1,  32, -1],
    [-1, -1,  -1]
  ]
  @@m = Mask.new @@mask, 24, 0 

  def sharp
    $log.info "sharpening"
    conv(@@m)
  end

  # yuk! this should get much better in vips8

  def self.jpeg?(filename)
    filename.end_with?('.jpg')
  end

  def self.png?(filename)
    filename.end_with?('.png')
  end

  # we want to open tiff, png and jpg images in sequential mode -- see
  #
  # http://libvips.blogspot.co.uk/2012/02/sequential-mode-read.html
  #
  # for more background, see also
  #
  # http://libvips.blogspot.co.uk/2012/06/how-libvips-opens-file.html
  #
  # this is very ugly! vips8 has a better way to give options to generic 
  # loaders, this chunk of ruby-vips should get better in the next version
  #
  # formats other than tif/png/jpg will be opened with the default loader -- 
  # this will decompress small images to memory, large images via a temporary 
  # disc file

  def self.open_seq(filename, shrink = 1)
    $log.info "opening #{filename}, shrink #{shrink}"

    case
    when filename.end_with?('.jpg')
      Image.jpeg filename, :shrink_factor => shrink, :sequential => true
    when filename.end_with?('.tif')
      Image.tiff filename, :sequential => true
    when filename.end_with?('.png')
      Image.png filename, :sequential => true
    else
      Image.new filename 
    end
  end

  # downsize, maintaining aspect ratio
  #
  # we shrink in two stages: we use a box filter (each pixel in output 
  # is the average of a m x n box of pixels in the input) to shrink by 
  # the largest integer factor we can, then an affine transform to get 
  # down to the exact size we need
  #
  # if you just shrink with the affine, you'll get bad aliasing for large
  # shrink factors (more than x2)

  def downsize_fixed(shrink)
    $log.info "downsize, fixed aspect ratio" 

    # width we are aiming for
    target_size = (x_size / shrink).to_i

    ishrink = shrink.to_i

    # size after int shrink
    iw = (x_size / ishrink).to_i

    # therefore residual float scale (note! not shrink)
    rscale = target_size.to_f / iw

    $log.info "block shrink by #{ishrink}" 
    $log.info "residual scale by #{rscale}" 

    a = shrink(ishrink)


    # bicubic might need to look back a few scanlines
    # vips has other interpolators, eg. :nohalo ... see the output of 
    # "vips list classes" at the command-line
    #
    # :bicubic is well-known and mostly good enough

    a = a.tile_cache(a.x_size, 1, 10)
    a = a.affinei_resize(:bicubic, rscale)

    return a
  end

  # upsizing is always just nearest-neighbor

  def upsize_fixed(scale)
    $log.info "upsize, fixed aspect ratio" 

    return affinei_resize(:nearest, scale)
  end

  # resize with changing aspect ratio is hard to do well. What if an image is
  # being downsized by a large amount in one axis, and upsized in the other?

  def resize_both(u, v)
    $log.info "resize, flexible aspect ratio" 

    target_width = (x_size / u).to_i
    target_height = (x_size / v).to_i

    # we might be expanding, ie. have a u/v of less than 1
    iu = [1, u.to_i].max
    iv = [1, v.to_i].max

    # size after int shrink
    iw = (x_size / iu).to_i
    ih = (y_size / iv).to_i

    # therefore residual horizontal and vertical scale (note! not shrink)
    rhs = target_width.to_f / iw
    rvs = target_height.to_f / ih

    $log.info "block shrink by #{iu}, #{iv}" 
    $log.info "residual scale by #{rhs}, #{rvs}" 

    # vips has other interpolators, eg. :nohalo ... see the output of 
    # "vips list classes" at the command-line
    #
    # :bicubic is well-known and mostly good enough

    return shrink(iu, iv).affinei_resize(:bicubic, rhs, rvs)
  end

  def resize(u, v = nil)
    if (v == nil or u == v) and u > 1
      return downsize_fixed u
    elsif (v == nil or u == v) and u <= 1
      return upsize_fixed u
    else
      return resize_both u, v
    end
  end

  def add_alpha(v)
    if bands == 1 or bands == 3
      $log.info "adding alpha"

      alpha1 = Image.black(1, 1, 1).lin(1, v).clip2fmt(a.band_fmt)
      alpha = alpha1.embed :extend, 0, 0, x_size, y_size
      bandjoin(alpha)
    else
      self
    end
  end

  def pad(fill, rect)
    case fill 
    when :alpha
      $log.info "padding with transparent alpha #{rect.inspect}"

      add_alpha(0).embed :black, rect.left, rect.top, rect.width, rect.height
    when :white
      $log.info "padding with white #{rect.inspect}"

      embed :white, rect.left, rect.top, rect.width, rect.height
    else
      self
    end
  end
end
