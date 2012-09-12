#!/usr/bin/ruby
# This is a Ruby port of the getPhotoList.pl script from Hack #33 in the book
# "Flickr Hacks: Tips & Tools for Sharing Photos Online" by
# Paul Bausch & Jim Bumgardner.
#
# Requirements:
# * A file ./apikey.rb defining two constants API_KEY and SHAREDSECRET containing a
#   Flickr API key and secret, respectively
#
# Author:: Eric Fung <efung@acm.org>
# Website:: https://github.com/efung/flickr-hacks-ruby

require 'flickraw-cached'
require 'optparse'

options = {}

opt_parser = OptionParser.new do |opt|
  opt.banner =<<-eob
  getPhotoList.rb [options] <tags> [<tags...>]
  getPhotoList.rb [options] -g group_id [<tag>]
  getPhotoList.rb [options] -u username [<tags>]
  eob

  opt.summary_indent = ''
  opt.summary_width = 16

  opt.on('-g group_id') do |g|
    options[:group_id] = g
  end

  opt.on('-u username') do |u|
    options[:username] = u
  end

  opt.separator ''
  opt.separator 'Options:'

  opt.on('--all', 'Photos must match all tags (tag search only)') do
    options[:all] = true
  end

  opt.on('--recent X', 'Only provide photos posted within the last X days (tag searches only)') do |recent|
    options[:recent] = recent
  end

  opt.on('--limit X', 'Provide no more than X photos') do |limit|
    options[:limit] = limit
  end

  opt.on('--license X', 'Provide photos with license X (a license ID returned by flickr.photos.licenses.getInfo)') do |license|
    options[:license] = license
  end

  opt.on('--verbose', 'Dump verbose information including raw API responses') do
    options[:verbose] = true
  end
end

if ARGV.length == 0 then
  # Some ugly hackery to avoid printing option summary for -u and -g
  opt_summary = opt_parser.summarize
  puts opt_parser.banner
  puts opt_summary[2..-1]
  exit
end

opt_parser.parse!

require './apikey.rb'

abort './apikey.rb does not defined API_KEY and SHAREDSECRET' if !defined?(API_KEY) || !defined?(SHAREDSECRET)

FlickRaw.api_key = API_KEY
FlickRaw.shared_secret = SHAREDSECRET

method = 'flickr.photos.search'
if options[:group_id] then
  group_id = options[:group_id]
  tags = ARGV[0]
  method = 'flickr.groups.pools.getPhotos'
  puts "Searching for photos in group #{options[:group_id]}"
  ofname = group_id  + '.rb'
elsif options[:username] then
  username = options[:username]
  tags = ARGV.join ','
  method = 'flickr.people.getPublicPhotos' if tags.empty?
  puts "Searching for photos by user #{username} using #{method}"
  ofname = username
  ofname += "_#{tags}" if !tags.empty?
  ofname.gsub! /,\s*/, '_'
  ofname += '.rb'
else
  tags = ARGV.join ','
  puts "Searching for photos with tags=#{tags} ..."
  ofname = tags + '.rb'
  ofname.gsub! /,\s*/, '_'
end

nbrPages = 0
photoIdx = 0

limit = options[:limit] ? options[:limit].to_i : 2000

user_id = ''
min_taken_date = ''
max_taken_date = ''

FLICKR_DATE_FORMAT = '%Y-%m-%d %H:%M:%S'
if options[:recent]
  abort '--recent option only valid for tag search' if method != 'flickr.photos.search'
  now = Time.now
  max_taken_date = Time.new(now.year, now.mon, now.day, 0, 0, 0).strftime(FLICKR_DATE_FORMAT)
  ago = now - options[:recent].to_i*24*60*60
  min_taken_date = Time.new(ago.year, ago.mon, ago.day, 0, 0, 0).strftime(FLICKR_DATE_FORMAT)
end

if username
  begin
    response = flickr.people.findByUsername :username => username
  rescue FlickRaw::FailedResponse => e
    abort "Problem determining user_id: #{e.msg}"
  end
  puts response.inspect if options[:verbose]
  user_id = response.id
  puts "Userid: #{user_id}"
end

params = { :per_page => 500 }

params[:tags] = tags if tags
params[:user_id] = user_id if !user_id.empty?
params[:group_id] = group_id if group_id
params[:min_taken_date] = min_taken_date if !min_taken_date.empty?
params[:max_taken_date] = max_taken_date if !max_taken_date.empty?
params[:license] = options[:license] if !options[:license]
params[:tag_mode] = 'all' if options[:all]

ofile = File.new(ofname, 'w')
ofile.puts 'PHOTOS = ['

photoIdx = 0
loop do
  params[:page] = nbrPages + 1
  begin
    response = flickr.call method, params
  rescue FlickRaw::FailedResponse => e
    abort "Problem: #{e.msg}"
  end

  puts response.inspect if options[:verbose]

  puts "Page #{response.page} of #{response.pages}"
  response.photo.each {|photo|
    ofile.print( (photoIdx != 0 ? ",\n  " : '  ') + photo.inspect )
    photoIdx += 1
    break unless photoIdx < limit
  }
  nbrPages += 1
  break unless (response.page < response.pages ) && photoIdx < limit
end

ofile.puts "\n]"
ofile.close

puts "#{photoIdx} photos found matching tags #{tags} written to #{ofname}"

