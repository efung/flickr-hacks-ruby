#!/usr/bin/ruby
# This is a Ruby port of the getSnaps.pl script from Hack #34 in the book
# "Flickr Hacks: Tips & Tools for Sharing Photos Online" by
# Paul Bausch & Jim Bumgardner.
#
# Requirements:
#
# Author:: Eric Fung <efung@acm.org>
# Website:: https://github.com/efung/flickr-hacks-ruby

require 'fileutils'
require 'flickraw-cached'
require 'open-uri'
require 'optparse'
require 'timeout'

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner= <<-eob
getSnaps.pl [--big] [--partition] <photolist_file> [dirname]
  eob
  opt.summary_indent = ''
  opt.summary_width = 16

  opt.on('--big', 'Return medium-sized photos instead of thumbnails') do
    options[:big] = true
  end

  opt.on('--partition', 'Save photos in folders grouped by server number') do
    options[:partition] = true
  end

  opt.on('--verbose', 'Dump verbose information') do
    options[:verbose] = true
  end
end

opt_parser.parse!

if ARGV.length == 0 then
  puts opt_parser
  exit
end

photolist = ARGV.shift
dirname = ARGV.shift

dirname = photolist if !dirname
dirname = dirname.sub(/\.rb$/, '')
photolist += '.rb' if !(photolist =~ /\./)

require "./#{photolist}"

abort "#{photolist} does not define PHOTOS" if !defined?(PHOTOS)

nbrAdded = 0

if !File.directory?(dirname)
  puts "Making directory #{dirname}"
  Dir.mkdir(dirname)
end

suffix = options[:big] ? '' : '_t'

PHOTOS.each do |photo|
  # The FlickRaw URL helper methods expect accessor methods
  def photo.method_missing(*args)
    self[args[0].to_s]
  end
  purlt = options[:big] ? FlickRaw::url(photo) : FlickRaw::url_t(photo)
  if !options[:partition]
    fname = "#{dirname}/#{photo['id']}#{suffix}.jpg"
  else
    subdirname = "#{dirname}/server#{photo['server']}/#{photo['id'].to_i / 1000}"
    FileUtils::mkdir_p subdirname
    fname = "#{subdirname}/#{photo['id']}#{suffix}.jpg"
  end
  puts "Checking #{fname}..." if options[:verbose]

  next if File.exists?(fname)

  puts "Adding #{fname}"

  retries = 5
  begin
    Timeout::timeout(5) {
      open(purlt) do |url|
        File.open(fname, 'wb') do |f|
          f.puts url.read
        end
      end
      puts "#{nbrAdded}..." if ((nbrAdded += 1) % 50 == 0)
    }
  rescue Timeout::Error
    if (retries -= 1) > 0
      sleep 1 and retry
    else
      raise "Couldn't get image #{purlt}"
    end
  end
end

puts "#{nbrAdded} added"
