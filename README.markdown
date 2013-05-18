# DXF

[![Build Status](https://travis-ci.org/bfoz/ruby-dxf.png)](https://travis-ci.org/bfoz/ruby-dxf)

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

Copyright 2012-2013 Brandon Fosdick <bfoz@bfoz.net> and released under the BSD license.
