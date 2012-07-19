#!/usr/bin/ruby

# driver program for level1.rb

require 'level1'

input = ARGV[0]
output = ARGV[1]

riapi = RIAPI.new input

riapi.width = 100
riapi.height = 100

riapi.process output
