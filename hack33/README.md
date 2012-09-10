# Hack 33 - Download a List of Photos

## Description
Queries Flickr for photos from a user or group, or that match tags.
The list can be filtered by recentness or license. The result is
output as a file containing the photos' metadata in the form of a 
Ruby array.

## Requirements
* Ruby 1.9
* flickraw gem: https://github.com/hanklords/flickraw

## Usage
The original Perl script produces a file containing an array named
`@photos`. In Ruby, local variables cannot be read via `require` or 
`load`, so this script produces a file with a constant array named `PHOTOS`.

This script expects a file named `apikey.rb` in the current directory
defining two constants `API_KEY` and `SHAREDSECRET` containing a
Flickr API key and secret, respectively.

## Differences from book
* Single-word command-line options (X Toolkit style) have been changed 
  to GNU style double-dash options.
* Bugs with the `--limit` option have been fixed

