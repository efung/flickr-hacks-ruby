# Hack 44 - Find the Dominant Color of an Image

## Description
Generates a collage of Flickr images

## Requirements
* Ruby 1.9
* ImageMagick. On Mac OS X, I suggest you use [Homebrew](http://mxcl.github.com/homebrew/) to install it.
* rmagick gem: http://rmagick.rubyforge.org/

## Differences from book
* In addition to specifying a local file, you can also specify a URL to an image

## Example Usage: samplePhoto.rb
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

