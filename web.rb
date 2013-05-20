require 'sinatra'

get '/' do
	images = Dir['samples/images/*'].map { File.basename }
	'sample images:\n' + images
end

get '/:path' do |path|
	"#{path}\n#{params}"
end
