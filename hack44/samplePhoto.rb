#!/usr/bin/ruby
# This is a Ruby port of the samplePhoto.pl script from Hack #44 in the book
# "Flickr Hacks: Tips & Tools for Sharing Photos Online" by
# Paul Bausch & Jim Bumgardner.
#
# Requirements:
#
# Author:: Eric Fung <efung@acm.org>
# Website:: https://github.com/efung/flickr-hacks-ruby

require 'RMagick'
include Magick

class SamplePhoto
  def initialize(args)
    @ARGV = args
  end

  def parse_opts
    if @ARGV.length != 1 then
      puts "samplePhoto.rb <photoname>"
      exit
    end
  end

  def run
    photoname = @ARGV.shift

    img = Image.read(photoname).first
    img.resize!(1, 1)
    pixel = img.pixel_color(0, 0)
    img.destroy!

    colorspec = pixel.to_color(compliance=AllCompliance, matte=false, depth=8, hex=true)

    print <<EOT
<html><body>
<table><tr>
<td><img src="#{photoname}" /></td>
</tr><tr>
<td bgcolor="#{colorspec}">
<font color="#{pixel.green < QuantumRange/2 ? 'white' : 'black'}">
R: #{pixel.red * 255 / QuantumRange}<br>
G: #{pixel.green * 255 / QuantumRange}<br>
B: #{pixel.blue * 255 / QuantumRange}<br>
</font>
</td></tr></table>
</body></html>
EOT
  end
end

# main
if __FILE__ == $PROGRAM_NAME
  c = SamplePhoto.new(ARGV)
  c.parse_opts
  c.run
end

