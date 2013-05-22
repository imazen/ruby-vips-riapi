require 'benchmark'
require 'fileutils'
require 'sinatra'

require 'level1/level1'

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
		riapi = RIAPI.new input_path
		riapi.width  = size
		riapi.height = size
		riapi.mode   = :max
		riapi.process output_path
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
	def parse_mode(mode)
		case text
		when 'max'     then :max
		when 'pad'     then :pad
		when 'crop'    then :crop
		when 'stretch' then :stretch
		else raise ArgumentException, "invalid mode: #{mode}"
		end
	end

	def parse_scale(scale)
		case scale
		when 'down'   then :down
		when 'both'   then :both
		when 'canvas' then :canvas
		else raise ArgumentException, "invalid scale: #{scale}"
		end
	end

	# get sample images and check if the given image is among them
	images = Dir[File.join(IN_DIR, '*')].map { |path| File.basename(path) }
	unless images.include? img
		raise Sinatra::NotFound
	end

	FileUtils.mkdir_p(OUT_DIR)

	riapi = RIAPI.new File.join(IN_DIR, img)

	# parse query fragments
	# TODO: make sure comparisons are performed in an ordinal,
	#       culture-invariant, case-insensitive manner

	riapi.width = Integer(params['w'])     if params.include? 'w'
	riapi.width = Integer(params['width']) if params.include? 'width'

	riapi.height = Integer(params['h'])      if params.include? 'h'
	riapi.height = Integer(params['height']) if params.include? 'height'

	riapi.mode = parse_mode(params['mode']) if params.include? 'mode'

	riapi.scale = parse_scale(params['scale']) if params.include? 'scale'

	riapi.process File.join(OUT_DIR, img)

	"width:  #{riapi.width}\nheight: #{riapi.height}\nmode:   #{riapi.mode}\nscale:  #{riapi.scale}\n"
end
