require 'fileutils'
require 'riapi'
require 'sinatra'

require 'level1/image_resizer.rb'

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

  input_path  = File.join(IN_DIR, img)
  output_path = File.join(OUT_DIR, img)
  ImageResizer.resize_image(input_path, output_path, RIAPI::parse_params(params))

  "#{output_path}\n"
end
