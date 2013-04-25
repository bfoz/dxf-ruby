require 'geometry'
require 'sketch'
require 'units'

module DXF
=begin
Reading and writing of files using AutoCAD's {http://en.wikipedia.org/wiki/AutoCAD_DXF Drawing Interchange File} format.

    {http://usa.autodesk.com/adsk/servlet/item?siteID=123112&id=12272454&linkID=10809853 DXF Specifications}
=end

    class Builder
	attr_accessor :container

	# Initialize with a Sketch
	# @param [String,Symbol] units	The units to convert length values to (:inches or :millimeters)
	def initialize(units=:mm)
	    @units = units
	end

	# Convert the given value to the correct units and return it as a formatted string
	# @return [String]
	def format_value(value)
	    if value.is_a? Units::Literal
		"%g" % value.send("to_#{@units}".to_sym)
	    else
		"%g" % value
	    end
	end

	def to_s
	    from_sketch(container)
	end

	# Convert a {Geometry::Line} into an entity array
	# @overload line(Line, layer=0)
	# @overload line(Point, Point, layer=0)
	def line(*args)
	    if args[0].is_a?(Geometry::Line)
		first, last = args[0].first, args[0].last
		layer = args[1] ||= 0
	    else
		first = args[0]
		last = args[1]
		layer = args[2] ||= 0
	    end
	    first = Point[first] unless first.is_a?(Geometry::Point)
	    last = Point[last] unless last.is_a?(Geometry::Point)
	    [ 0, 'LINE',
	      8, layer,
	     10, format_value(first.x),
	     20, format_value(first.y),
	     11, format_value(last.x),
	     21, format_value(last.y)]
	end

	def section(name)
	    [0, 'SECTION', 2, name]
	end

	# Build a DXF from a Sketch
	# @return   [Array]	Array of bytes to be written to a file
	def from_sketch(sketch)
	    bytes = []
	    bytes.push section('HEADER')
	    bytes.push 0, 'ENDSEC'
	    bytes.push section('ENTITIES')

	    sketch.geometry.map do |element|
		case element
		    when Geometry::Arc
			bytes.push 0, 'ARC'
			bytes.push 10, format_value(element.center.x)
			bytes.push 20, format_value(element.center.y)
			bytes.push 40, format_value(element.radius)
			bytes.push 50, format_value(element.start_angle)
			bytes.push 51, format_value(element.end_angle)
		    when Geometry::Circle
			bytes.push 0, 'CIRCLE'
			bytes.push 10, format_value(element.center.x)
			bytes.push 20, format_value(element.center.y)
			bytes.push 40, format_value(element.radius)
		    when Geometry::Line
			bytes.push line(element.first, element.last)
		    when Geometry::Polyline
			element.edges.map {|edge| bytes.push line(edge.first, edge.last) }
		    when Geometry::Rectangle
			element.edges.map {|edge| bytes.push line(edge.first, edge.last) }
		    when Geometry::Square
			points = element.points
			points.each_cons(2) {|p1,p2| bytes.push line(p1,p2) }
			bytes.push line(points.last, point.first)
		end
	    end

	    bytes.push 0, 'ENDSEC'
	    bytes.push 0, 'EOF'
	    bytes.join "\n"
	end
    end

    # Export a {Sketch} to a DXF file
    # @param [String] filename	The path to write to
    # @param [Sketch] sketch	The {Sketch} to export
    # @param [Symbol] units	Convert all values to the specified units (:inches or :mm)
    def self.write(filename, sketch, units=:mm)
	File.write(filename, Builder.new(units).from_sketch(sketch))
    end
end
