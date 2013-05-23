require 'benchmark'
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

# benchmark process
get '/benchmark' do
	images = Dir[File.join(IN_DIR, '*')].sort

	def process(input_path, output_path, size)
		resizer = ImageResizer.new input_path
		resizer.width  = size
		resizer.height = size
		resizer.mode   = :max
		resizer.process output_path
	end


	# create output directory
	FileUtils.mkdir_p(OUT_DIR)

	# redirect stdout to a string
	str_stream = ''
	def str_stream.write(data)
		self << data.to_s
	end
	old_stdout, $stdout = $stdout, str_stream

	begin
		# benchmark riapi::process over a number of images and output sizes
		Benchmark.bm(14) do |x|
			images.each do |path|
				(100..700).step(200).each do |size|
					img = File.basename(path, '.*')
					out = File.join(OUT_DIR, "#{img}-#{size}.jpg")
					x.report("#{size} #{img}") { process(path, out, size) }
				end
			end .to_s
		end
	ensure
		# restore stdout
		$stdout = old_stdout
	end

	str_stream
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
