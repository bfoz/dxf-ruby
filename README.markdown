# DXF

[![Build Status](https://travis-ci.org/bfoz/dxf-ruby.png)](https://travis-ci.org/bfoz/dxf-ruby)
[![Gem Version](https://badge.fury.io/rb/dxf.svg)](http://badge.fury.io/rb/dxf)

Tools for working with the popular DXF file format

## Installation

Add this line to your application's Gemfile:

    gem 'DXF'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dxf

## Usage

```ruby
require 'dxf'

# To export the my_sketch object in inches
DXF.write('filename.dxf', my_sketch, :inches)
```

License
-------

Copyright 2012-2015 Brandon Fosdick <bfoz@bfoz.net> and released under the BSD license.
