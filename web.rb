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

	riapi.width = Integer(params['width']) if params.include? 'width'
	riapi.width = Integer(params['w'])     if params.include? 'w'

	riapi.height = Integer(params['height']) if params.include? 'height'
	riapi.height = Integer(params['h'])      if params.include? 'h'

	riapi.mode = parse_mode(params['mode']) if params.include? 'mode'

	riapi.scale = parse_scale(params['scale']) if params.include? 'scale'

	riapi.process File.join(OUT_DIR, img)

	"width:  #{riapi.width}\nheight: #{riapi.height}\nmode:   #{riapi.mode}\nscale:  #{riapi.scale}"
end
