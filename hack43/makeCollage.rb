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

# Extend Math module with polar-coordinate and degree-radian conversion methods
module Math
  def self.polar(x,y)
    [hypot(x,y), atan2(y,x)]
  end

  # theta in radians
  def self.cartesian(r, theta)
    [r*cos(theta), r*sin(theta)]
  end

  def self.radians(deg)
    deg/180*PI
  end

  def self.degrees(rads)
    rads/PI*180
  end
end

module RandomLayout
  def self.extended(klass)
    if !klass.instance_variable_defined?(:@owidth) ||
       !klass.instance_variable_defined?(:@oheight) ||
       !klass.instance_variable_defined?(:@num)
      raise "#{klass.class.name} must define @owidth, @oheight and @num"
    end
  end

  def layout_resize(img, n)
    [img.width, img.height]
  end

  def layout_position(img, n)
    # Origin is top-left, so return a position such that entire image is visible
    [rand(@owidth-img.width), rand(@oheight-img.height)]
  end

  def layout_rotate(img, n)
    rand(90)-45
  end

  def layout_opacity(img, q)
    rand(q)
  end
end

# Follows the Fermat Spiral formula proposed by H. Vogel (http://en.wikipedia.org/wiki/Fermat%27s_spiral)
#   r     = c*sqrt(n)
#   theta = n * 137.508 deg
module SunflowerSpiralLayout
  def self.extended(klass)
    if !klass.instance_variable_defined?(:@owidth) ||
       !klass.instance_variable_defined?(:@oheight) ||
       !klass.instance_variable_defined?(:@num)
      raise "#{klass.class.name} must define @owidth, @oheight and @num"
    end
  end

  def layout_resize(img, n)
    # Heuristic that produces a pleasing result
    [@resize_width ||= @owidth / Math.sqrt(@num) / 2, @resize_height ||= @oheight / Math.sqrt(@num) / 2]
  end

  def layout_position(img, n)
    @c ||= [@owidth/2, @oheight/2].min / Math.sqrt(@num)
    x, y = Math::cartesian( @c * Math.sqrt(n), n * Math::radians(137.508))
    [x+(@owidth-img.width)/2, y+(@oheight-img.height)/2]
  end

  def layout_rotate(img, n)
    0
  end

  def layout_opacity(img, q)
    return 0
  end
end

class Image
  alias_method :width, :columns
  alias_method :height, :rows
end

class MakeCollage
  def initialize(args)
    @ARGV = args
  end

  def run
    @collagename = @photolist if !@collagename
    @collagename = @collagename.sub(/\.rb$/, '')
    @photolist += '.rb' if !(@photolist =~ /\./)

    require "./#{@photolist}"

    abort "#{@photolist} does not define PHOTOS" if !defined?(PHOTOS)

    @owidth, @oheight = 1024 * (@options[:big] ? 2 : 1), 768 * (@options[:big] ? 2 : 1)

    outImage = Image.new(@owidth, @oheight) { self.background_color = 'black' }

    dirname = @photolist
    dirname = dirname.sub(/\.rb/, '') if @photolist =~ /\.rb$/;

    suffix = @options[:big] ? '' : '_t'

    @num = PHOTOS.size

    extend @options[:layout]

    PHOTOS.each_with_index do |photo, n|
      fname = "#{dirname}/#{photo['id']}#{suffix}.jpg"
      img = Image.read(fname).first

      img.background_color = 'none'
      img.opacity = layout_opacity(img, QuantumRange)

      w, h = layout_resize(img, n)
      img.resize!(w, h)

      img.rotate!(layout_rotate(img, n))

      x, y = layout_position(img, n)

      outImage.composite!(img, x, y, OverCompositeOp)

      img.destroy!

      puts "#{n}..." if n % 100 == 0
    end

    outImage.write "#{@collagename}#{suffix}.png"
  end

  def parse_opts
    @options = {}

    opt_parser = OptionParser.new do |opt|
      opt.banner= <<-eob
makeCollage.rb [options] <photolist_file> [collagename]
eob
      opt.summary_indent = ''
      opt.summary_width = 16

      opt.on('--big', 'Look for medium-sized downloaded photos instead of thumbnails') do
        @options[:big] = true
      end

      @options[:layout] = RandomLayout
      opt.on('--layout L', 'Use layout L to arrange images, where L is {random, sunflower}') do |layout|
        case layout
        when 'random'
          @options[:layout] = RandomLayout
        when 'sunflower'
          @options[:layout] = SunflowerSpiralLayout
        else
          puts opt_parser
          exit
        end
      end
    end

    opt_parser.parse!

    if @ARGV.length == 0 then
      puts opt_parser
      exit
    end

    @photolist = @ARGV.shift
    @collagename = @ARGV.shift
  end
end

# main
if __FILE__ == $PROGRAM_NAME
  c = MakeCollage.new(ARGV)
  c.parse_opts
  c.run
end
