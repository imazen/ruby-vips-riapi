#!/usr/bin/ruby

# quick performance benchmark

require 'level1'
require 'benchmark'
require 'fileutils'

$log.level = Logger::WARN

in_dir  = '../samples/images'
out_dir = '../out'

images = Dir[File.join(in_dir, '*')].sort

def process(input_path, output_path, size)
	riapi = RIAPI.new input_path
	riapi.width  = size
	riapi.height = size
	riapi.mode   = :max
	riapi.process output_path
end

# create output directory
FileUtils.mkdir_p(out_dir)

# benchmark riapi::process over a number of images and output sizes
Benchmark.bm(14) do |x|
	(100..700).step(200).each do |size|
		images.each do |path|
			img = File.basename(path, '.*')
			out = File.join(out_dir, "#{img}-#{size}.jpg")
			x.report("#{size} #{img}") { process(path, out, size) }
		end
	end
end
