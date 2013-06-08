require 'level1/layout'

require 'rubygems'
require 'riapi'

# implement level l of the riapi spec, see:
# https://github.com/riapi/riapi/blob/master/level-1.md

# parse parameter string of the form: a=b;c=d;e=...
def make_opts(s)
  opts = {}
  s.split(';').each do |part|
    args = part.split('=')
    opts[args[0]] = args[1]
  end
  RIAPI::parse_params(opts)
end

describe Layout do
  let(:info) { Layout::ImageInfo.new(640, 480, false, false) }

  context 'basic resizing' do
    it 'handles empty input' do
      Layout.process(info, {}).should eq({})
    end

    it 'handles simple scaling' do
      options = make_opts("w=320;h=240")
      layout  = { :resize => Options::Resize.new(0.5, 0.5) }
      Layout.process(info, options).should eq layout
    end

    # If width is omited, it will be chosen to match the original aspect ratio.
    it 'handles missing width' do
      options = make_opts("w=160")
      layout  = { :resize => Options::Resize.new(0.25, 0.25) }
      Layout.process(info, options).should eq layout
    end

    # If height is omited, it will be chosen to match the original aspect ratio.
    it 'handles missing height' do
      options = make_opts("h=120")
      layout  = { :resize => Options::Resize.new(0.25, 0.25) }
      Layout.process(info, options).should eq layout
    end
  end

  context 'constraint mode' do
    # The image will be scaled to fit within the width/height constraint box
    # while maintaining aspect ratio.
    context 'max' do
      let(:options) { make_opts("mode=max;scale=both") }

      it 'handles width-limited downscaling' do
        options.merge! :width => 320, :height => 480
        layout = { :resize => Options::Resize.new(0.5, 0.5) }
        Layout.process(info, options).should eq layout
      end

      it 'handles height-limited downscaling' do
        options.merge! :width => 640, :height => 240
        layout = { :resize => Options::Resize.new(0.5, 0.5) }
        Layout.process(info, options).should eq layout
      end

      it 'handles width-limited upscaling' do
        options.merge! :width => 1280, :height => 1280
        layout = { :resize => Options::Resize.new(2, 2) }
        Layout.process(info, options).should eq layout
      end

      it 'handles height-limited upscaling' do
        options.merge! :width => 2000, :height => 960
        layout = { :resize => Options::Resize.new(2, 2) }
        Layout.process(info, options).should eq layout
      end
    end

    # The image will be evenly padded with whitespace or transparency to become
    # exactly the specified size while maintaining aspect ratio.
    context 'pad' do
      let(:options) { make_opts("mode=pad;scale=both") }

      it 'handles proportioned downscaling' do
        options.merge! :width => 320, :height => 240
        layout = { :resize => Options::Resize.new(0.5, 0.5) }
        Layout.process(info, options).should eq layout
      end

      it 'handles width-limited downscaling' do
        options.merge! :width => 320, :height => 320
        layout = {
          :bg     => Options::Background.new(0, 40, 320, 320, :white),
          :resize => Options::Resize.new(0.5, 0.5)
        }
        Layout.process(info, options).should eq layout
      end

      it 'handles height-limited downscaling' do
        options.merge! :width => 400, :height => 240
        layout = {
          :bg     => Options::Background.new(40, 0, 400, 240, :white),
          :resize => Options::Resize.new(0.5, 0.5)
        }
        Layout.process(info, options).should eq layout
      end
    end
  end

  # The image will be minimally cropped evenly to match the required aspect ratio.
  context 'crop' do
    let(:options) { make_opts("mode=crop;scale=both") }

    it 'handles width-limited downscaling' do
      options.merge! :width => 320, :height => 120
      layout = {
        :crop   => Options::Crop.new(0, -120, 640, 240),
        :resize => Options::Resize.new(0.5, 0.5)
      }
      Layout.process(info, options).should eq layout
    end

    it 'handles height-limited downscaling' do
      options.merge! :width => 160, :height => 240
      layout = {
        :crop   => Options::Crop.new(-160, 0, 320, 480),
        :resize => Options::Resize.new(0.5, 0.5)
      }
      Layout.process(info, options).should eq layout
    end
  end

  # The image will be stretched to fit the given dimensions.
  context 'stretch' do
    let(:options) { make_opts("mode=stretch;scale=both") }

    it 'handles non-uniform downscaling' do
      options.merge! :width => 160, :height => 240
      layout = { :resize => Options::Resize.new(0.25, 0.5) }
      Layout.process(info, options).should eq layout
    end

    it 'handles non-uniform upscaling' do
      options.merge! :width => 960, :height => 960
      layout = { :resize => Options::Resize.new(1.5, 2) }
      Layout.process(info, options).should eq layout
    end
  end

  context 'scale mode' do
    # If the constraints are larger than the source image, the resulting
    # image will use the source dimensions instead, foregoing any cropping,
    # padding, or stretching.
    context 'down' do
      let(:options) { make_opts("mode=max;scale=down") }

      it 'handles upscaling' do
        options.merge! :width => 960, :height => 960
        layout = { }
        Layout.process(info, options).should eq layout
      end

      it 'handles mixed scaling' do
        options.merge! :width => 320, :height => 960
        layout = { :resize => Options::Resize.new(0.5, 0.5) }
        Layout.process(info, options).should eq layout
      end
    end

    # Enables upscaling. Images will be upscaled to match constrains and may
    # be cropped, padded, or stretched in order to modify the aspect ratio.
    context 'both' do
      let(:options) { make_opts("mode=max;scale=both") }

      it 'handles upscaling' do
        options.merge! :width => 960, :height => 960
        layout = { :resize => Options::Resize.new(1.5, 1.5) }
        Layout.process(info, options).should eq layout
      end

      it 'handles mixed scaling' do
        options.merge! :width => 320, :height => 960
        layout = { :resize => Options::Resize.new(0.5, 0.5) }
        Layout.process(info, options).should eq layout
      end
    end

    # Enables upscaling of the canvas, but not the image. Above the original
    # image size, padding will be used to reach the requested dimensions.
    context 'canvas' do
      let(:options) { make_opts("mode=pad;scale=canvas") }

      it 'handles upscaling' do
        options.merge! :width => 960, :height => 960
        layout = { :bg => Options::Background.new(160, 240, 960, 960, :white) }
        Layout.process(info, options).should eq layout
      end

      it 'handles mixed scaling' do
        options.merge! :width => 320, :height => 960
        layout = {
          :bg     => Options::Background.new(0, 360, 320, 960, :white),
          :resize => Options::Resize.new(0.5, 0.5)
        }
        Layout.process(info, options).should eq layout
      end
    end
  end

  # Shrink on load by the largest power of 2 possible, before resizing.
  it 'supports shrink-on-load' do
    info = Layout::ImageInfo.new(160, 160, true, false)
    options = make_opts("w=30;h=30")
    layout = {
      :load   => Options::Load.new(4),
      :resize => Options::Resize.new(0.75, 0.75)
    }
    Layout.process(info, options).should eq layout
  end

  # Pad with alpha, if alpha is supported.
  it 'supports alpha' do
    info = Layout::ImageInfo.new(100, 100, false, true)
    options = make_opts("w=200;h=200;scale=canvas")
    layout = { :bg => Options::Background.new(50, 50, 200, 200, :alpha) }
    Layout.process(info, options).should eq layout
  end
end
