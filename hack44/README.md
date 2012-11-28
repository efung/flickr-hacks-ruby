# Hack 44 - Find the Dominant Color of an Image

## Description
Finds the dominant color of an image, and outputs the image metadata and color information as a Ruby array.

## Requirements
* Ruby 1.9
* ImageMagick. On Mac OS X, I suggest you use [Homebrew](http://mxcl.github.com/homebrew/) to install it.
* rmagick gem: http://rmagick.rubyforge.org/

## Differences from book
* samplePhoto.rb: In addition to specifying a local file, you can also specify a URL to an image

## Usage: samplePhoto.rb
    $ ruby samplePhoto.rb http://www.example.com/persimmon.png
    $ ruby samplePhoto.rb persimmon.jpg 

Example output:
```html
<html><body>
<table><tr>
<td><img src="persimmon.jpg" /></td>
</tr><tr>
<td bgcolor="#B3AC60">
<font color="black">
R: 179<br>
G: 172<br>
B: 96<br>
</font>
</td></tr></table>
</body></html>
```
![samplePhoto persimmon output](http://efung.github.com/flickr-hacks-ruby/img/samplePhoto_persimmon.png)

## Usage: sampleSnaps.rb
The original Perl script produces a file containing an array named
`@photos`. In Ruby, local variables cannot be read via `require` or  
`load`, so this script produces a file with a constant array named
`PHOTOS`.

    $ ruby sampleSnaps.rb persimmon
