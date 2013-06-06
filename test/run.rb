require 'rubygems'
require 'fileutils'

require 'level1/render'

include VIPS

IN_DIR  = 'samples/images'
OUT_DIR = 'out'

$source = 'jasper.jpg'

def run(method, name, options)
  image = Image.new File.join(IN_DIR, $source)
  image = Render.send(method, image, options)
  image.write File.join(OUT_DIR, name)
end

# create output directory
FileUtils.mkdir_p(OUT_DIR)

# test shrinking
# expected output: a 320x240 version of $source
run(:render_resize, 'small.jpg', { :resize => Options::Resize.new(0.5, 0.5) })

# test expansion
# expected output: 960x720 version of $source
run(:render_resize, 'large.jpg', { :resize => Options::Resize.new(1.5, 1.5) })

# test cropping
# expected output: $source centered on a 480x640 white canvas
run(:render_crop, 'cropped.jpg', { :crop => Options::Crop.new(-80, 80, 480, 640) })

# test complete render
# expected output: 320x240 version of $source centered on a 240x320 white canvas
input_path  = File.join(IN_DIR, $source)
output_path = File.join(OUT_DIR, 'full.jpg')
options = {
  :resize => Options::Resize.new(0.5, 0.5),
  :crop   => Options::Crop.new(-80, 80, 480, 640)
}
Render::process(input_path, output_path, options)

# test complete render without scaling
# expected output: a copy of $source
input_path  = File.join(IN_DIR, $source)
output_path = File.join(OUT_DIR, 'nop.jpg')
Render::process(input_path, output_path, {})
