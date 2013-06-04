require 'benchmark/multi-benchmark'
require 'level1/image_resizer.rb'

require 'fileutils'

$log.level = Logger::WARN

IN_DIR  = 'samples/images'
OUT_DIR = 'out'

images = Dir[File.join(IN_DIR, '*')].sort

def process(input_path, output_path, size)
  resizer = ImageResizer.new input_path
  resizer.width  = size
  resizer.height = size
  resizer.mode   = :max
  resizer.process(output_path, false)
end

# create output directory
FileUtils.mkdir_p(OUT_DIR) unless images.empty?

# benchmark riapi::process over a number of images and output sizes
MultiBenchmark.repeat(20) do |x|
  images.each do |path|
    (100..700).step(200).each do |size|
      img = File.basename(path, '.*')
      out = File.join(OUT_DIR, "#{img}-#{size}.jpg")
      x.report("#{size} #{img}") { process(path, out, size) }
    end
  end
end
