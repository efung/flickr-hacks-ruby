#!/usr/bin/ruby
# This is a Ruby port of the makeCollage.pl script from Hack #43 in the book
# "Flickr Hacks: Tips & Tools for Sharing Photos Online" by
# Paul Bausch & Jim Bumgardner.
#
# Author:: Eric Fung <efung@acm.org>
# Website:: https://github.com/efung/flickr-hacks-ruby

require 'RMagick'
include Magick
require 'flickraw-cached'
require 'optparse'

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner= <<-eob
makeCollage.rb [--big] <photolist_file> [collagename]
  eob
  opt.summary_indent = ''
  opt.summary_width = 16

  opt.on('--big', 'Look for medium-sized downloaded photos instead of thumbnails') do
    options[:big] = true
  end
end

opt_parser.parse!

if ARGV.length == 0 then
  puts opt_parser
  exit
end

photolist = ARGV.shift
collagename = ARGV.shift

collagename = photolist if !collagename
collagename = collagename.sub(/\.rb$/, '')
photolist += '.rb' if !(photolist =~ /\./)

require "./#{photolist}"

abort "#{photolist} does not define PHOTOS" if !defined?(PHOTOS)

outW, outH = 1024 * (options[:big] ? 2 : 1), 768 * (options[:big] ? 2 : 1)

outImage = Image.new(outW, outH) { self.background_color = 'black' }

dirname = photolist
dirname = dirname.sub(/\.rb/, '') if photolist =~ /\.rb$/;

suffix = options[:big] ? '' : '_t'

n=0
PHOTOS.each do |photo|
  fname = "#{dirname}/#{photo['id']}#{suffix}.jpg"
  img = Image.read(fname).first

  img.background_color = 'none'
  img.resize_to_fit!(200) if options[:big]
  img.opacity = rand(QuantumRange)
  img.rotate!(rand(90)-45)

  w, h = img.columns, img.rows

  x = rand(outW - w)
  y = rand(outH - h)

  outImage.composite!(img, x, y, OverCompositeOp)

  img.destroy!

  puts "#{n}..." if ((n += 1) % 100 == 0)
end

outImage.write "#{collagename}#{suffix}.png"
