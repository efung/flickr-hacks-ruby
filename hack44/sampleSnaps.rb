#!/usr/bin/ruby
# This is a Ruby port of the sampleSnaps.pl script from Hack #44 in the book
# "Flickr Hacks: Tips & Tools for Sharing Photos Online" by
# Paul Bausch & Jim Bumgardner.
#
# Requirements:
#
# Author:: Eric Fung <efung@acm.org>
# Website:: https://github.com/efung/flickr-hacks-ruby

require 'fileutils'
require 'optparse'
require 'RMagick'
include Magick

class SampleSnaps
  def initialize(args)
    @ARGV = args
  end

  def parse_opts
    @options = {}

    opt_parser = OptionParser.new do |opt|
      opt.banner= <<-eob
sampleSnaps.rb <photolist_file> [dirname]
      eob
      opt.summary_indent = ''
      opt.summary_width = 16

      opt.on('--big', 'Read medium-sized photos instead of thumbnails') do
        @options[:big] = true
      end
    end

    opt_parser.parse!

    # photolist_file is required
    if ARGV.length < 1 then
      puts opt_parser
      exit
    end
  end

  def run
    photolist = @ARGV.shift
    dirname = @ARGV.shift

    dirname = photolist if !dirname
    dirname = dirname.sub(/\.rb$/, '')
    photolist += '.rb' if !(photolist =~ /\./)

    require "./#{photolist}"

    abort "#{photolist} does not define PHOTOS" if !defined?(PHOTOS)

    n = PHOTOS.length
    puts "#{n} photos in file"

    nbrSampled = 0

    suffix = @options[:big] ? '' : '_t'

    ofname = "#{dirname}/samples.rb"
    ofile = File.new(ofname, 'w')
    ofile.puts <<EOH
# encoding: utf-8
PHOTOS = [
EOH

    PHOTOS.each_with_index do |photo, n|
      fname = "#{dirname}/#{photo['id']}#{suffix}.jpg"
      next if !File.exists?(fname)

      img = Image.read(fname).first
      img.resize!(1, 1)
      pixel = img.pixel_color(0, 0)
      img.destroy!

      photo['r'], photo['g'], photo['b'] = [pixel.red, pixel.green, pixel.blue].map {|c| c.to_f / QuantumRange}
#      photo['l'] = pixel.to_hsla[2]
      photo['l'] = 0.3086*photo['r'] + 0.6094*photo['g'] + 0.0820*photo['b'] # http://www.graficaobscura.com/matrix/index.html

      nbrSampled += 1
      puts "#{nbrSampled}... " if (nbrSampled % 50 == 0)

      ofile.print( (n != 0 ? ",\n  " : '  ') + photo.inspect)
    end

    ofile.puts "\n]"
    ofile.close

    puts "#{nbrSampled} sampled to #{ofname}"
  end
end

# main
if __FILE__ == $PROGRAM_NAME
  c = SampleSnaps.new(ARGV)
  c.parse_opts
  c.run
end

