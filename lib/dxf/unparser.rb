require 'geometry'
require 'sketch'
require 'units'
require 'stringio'

module DXF
    class Unparser
	attr_accessor :container

	# Initialize with a Sketch
	# @param [String,Symbol] units	The units to convert length values to (:inches or :millimeters)
	def initialize(units=:mm)
	    @units = units
	end

	def to_s
	    io = StringIO.new
	    unparse(io, container)
	    io.string
	end

# @group Element Formatters
	# Convert a {Geometry::Line} into group codes
	def line(first, last, layer=0, transformation=nil)
	    first, last = Geometry::Point[first], Geometry::Point[last]
	    first, last = [first, last].map {|point| transformation.transform(point) } if transformation

	    [ 0, 'LINE',
	    8, layer,
	    10, format_value(first.x),
	    20, format_value(first.y),
	    11, format_value(last.x),
	    21, format_value(last.y)]
	end

	def lwpolyline(points, closed, layer=0, transformation=nil)
	    [0, 'LWPOLYLINE',
	     8, layer,
	     90, points.length,
	     70, closed ? 1 : 0,
	     ] + points.map do |point|
		 vertex = transformation ? transformation.transform(point) : point
		 [10, 20].zip(vertex.first(2).map {|v| format_value(v)})
	    end
	end
# @endgroup

# @group Property Converters
	# Convert the given value to the correct units and return it as a formatted string
	# @return [String]
	def format_value(value)
	    ("%g" % value.to(@units)) rescue ("%g" % value)
	end

	# Emit the group codes for the center property of an element
	# @param [Point] point	The center point to format
	def center(point, transformation)
	    point = transformation.transform(point) if transformation
	    [10, format_value(point.x), 20, format_value(point.y)]
	end

	# Emit the group codes for the radius property of an element
	def radius(element, transformation=nil)
	    [40, format_value(transformation ? transformation.transform(element.radius) : element.radius)]
	end

	def section_end
	    [0, 'ENDSEC']
	end

	def section_start(name)
	    [0, 'SECTION', 2, name]
	end
# @endgroup

	# Convert an element to an Array
	# @param [Transformation] transformation    The transformation to apply to each geometry element
	# @return [Array]
	def to_array(element, transformation=nil)
	    layer = 0;
	    case element
		when Geometry::Arc
		    [ 0, 'ARC', center(element.center, transformation), radius(element),
		    50, format_value(element.start_angle),
		    51, format_value(element.end_angle)]
		when Geometry::Circle
		    [0, 'CIRCLE', 8, layer, center(element.center, transformation), radius(element)]
		when Geometry::Edge, Geometry::Line
		    line(element.first, element.last, layer, transformation)
		when Geometry::Polyline
		    lwpolyline(element.points, element.closed?, layer, transformation)
		when Geometry::Rectangle, Geometry::Square, Geometry::Triangle
		    lwpolyline(element.points, true, layer, transformation)
		when Sketch
		    transformation = transformation ? (transformation + element.transformation) : element.transformation
		    element.geometry.map {|e| to_array(e, transformation)}
	    end
	end

	# Convert a {Sketch} to a DXF file and write it to the given output
	# @param [IO] output    A writable IO-like object
	# @param [Sketch] sketch	The {Sketch} to unparse
	def unparse(output, sketch)
	    output << (section_start('HEADER') + section_end +
		       section_start('ENTITIES') + to_array(sketch) + section_end +
		       [0, 'EOF']).join("\n")
	end
    end
end
