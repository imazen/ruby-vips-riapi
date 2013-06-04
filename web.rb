require 'fileutils'
require 'riapi'
require 'sinatra'

require 'level1/image_resizer.rb'

$log.level = Logger::WARN

IN_DIR  = 'samples/images'
OUT_DIR = 'out'

# list available sample images
get '/samples' do
  images = Dir[File.join(IN_DIR, '*')].map { |path| File.basename(path) }
  images.map { |img| "#{img}\n" } .join
end

# perform an image resize
get '/:img' do |img|
  # get sample images and check if the given image is among them
  images = Dir[File.join(IN_DIR, '*')].map { |path| File.basename(path) }
  unless images.include? img
    raise Sinatra::NotFound
  end

  FileUtils.mkdir_p(OUT_DIR)

  resizer = ImageResizer.new(File.join(IN_DIR, img), RIAPI::parse_params(params))
  resizer.process File.join(OUT_DIR, img)

  "width:  #{resizer.width}\nheight: #{resizer.height}\nmode:   #{resizer.mode}\nscale:  #{resizer.scale}\n"
end
