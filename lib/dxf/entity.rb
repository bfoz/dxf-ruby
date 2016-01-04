require 'geometry'

require_relative 'cluster_factory'

module DXF
    Point = Geometry::Point

    # {Entity} is the base class for everything that can live in the ENTITIES block
    class Entity
	TypeError = Class.new(StandardError)

	include ClusterFactory

	attr_accessor :handle
	attr_accessor :layer

	def self.new(type)
	    case type
		when 'ARC'	then Arc.new
		when 'CIRCLE'	then Circle.new
		when 'LINE'	then Line.new
		when 'SPLINE'	then Spline.new
		else
		    raise TypeError, "Unrecognized entity type '#{type}'"
	    end
	end

	def parse_pair(code, value)
	    # Handle group codes that are common to all entities
	    #  These are from the table that starts on page 70 of specification
	    case code
		when '5'
		    handle = value
		when '8'
		    layer = value
		else
		    p "Unrecognized entity group code: #{code} #{value}"
	    end
	end

	private

	def point_from_values(*args)
	    Geometry::Point[args.flatten.reverse.drop_while {|a| not a }.reverse]
	end
    end

    class Circle < Entity
	attr_accessor :x, :y, :z
	attr_accessor :radius

	def parse_pair(code, value)
	    case code
		when '10'   then self.x = value.to_f
		when '20'   then self.y = value.to_f
		when '30'   then self.z = value.to_f
		when '40'   then self.radius = value.to_f
		else
		    super   # Handle common and unrecognized codes
	    end
	end

	# @!attribute [r] center
	#   @return [Point]  the composed center of the {Circle}
	def center
	    a = [x, y, z]
	    a.pop until a.last
	    Geometry::Point[*a]
	end
    end

    class Arc < Circle
      attr_accessor :start_angle, :end_angle

      def parse_pair(code, value)
    	    case code
    		when '50'   then self.start_angle = value.to_f
    		when '51'   then self.end_angle = value.to_f
    		else
    		    super   # Handle common and unrecognized codes
    	    end
    	end

    end

    class Line < Entity
	attr_reader :first, :last
	attr_accessor :x1, :y1, :z1
	attr_accessor :x2, :y2, :z2

	def parse_pair(code, value)
	    case code
		when '10'   then self.x1 = value.to_f
		when '20'   then self.y1 = value.to_f
		when '30'   then self.z1 = value.to_f
		when '11'   then self.x2 = value.to_f
		when '21'   then self.y2 = value.to_f
		when '31'   then self.z2 = value.to_f
		else
		    super   # Handle common and unrecognized codes
	    end
	end

	def initialize(*args)
	    @first, @last = *args
	end

	# @!attribute [r] first
	#   @return [Point]  the starting point of the {Line}
	def first
	    @first ||= point_from_values(x1, y1, z1)
	end

	# @!attribute [r] last
	#   @return [Point]  the end point of the {Line}
	def last
	    @last ||= point_from_values(x2, y2, z2)
	end
    end

    class LWPolyline < Entity
	# @!attribute points
	#   @return [Array<Point>]  The points that make up the polyline
	attr_reader :points

	def initialize(*points)
	    @points = points.map {|a| Point[a]}
	end

	# Return the individual line segments
	def lines
	    points.each_cons(2).map {|a,b| Line.new a, b}
	end
    end

    class Spline < Entity
	attr_reader :degree
	attr_reader :knots
	attr_reader :points

	def initialize(degree:nil, knots:[], points:nil)
	    @degree = degree
	    @knots = knots || []
	    @points = points || []
	end
    end

    class Bezier < Spline
	# @!attribute degree
	#   @return [Number]  The degree of the curve
	def degree
	    points.length - 1
	end

	# @!attribute points
	#   @return [Array<Point>]  The control points for the Bézier curve
	attr_reader :points

	def initialize(*points)
	    @points = points.map {|v| Geometry::Point[v]}
	end

	# http://en.wikipedia.org/wiki/Binomial_coefficient
	# http://rosettacode.org/wiki/Evaluate_binomial_coefficients#Ruby
	def binomial_coefficient(k)
	    (0...k).inject(1) {|m,i| (m * (degree - i)) / (i + 1) }
	end

	# @param t [Float]  the input parameter
	def [](t)
	    return nil unless (0..1).include?(t)
	    result = Geometry::Point.zero(points.first.size)
	    points.each_with_index do |v, i|
		result += v * binomial_coefficient(i) * ((1 - t) ** (degree - i)) * (t ** i)
	    end
	    result
	end

	# Convert the {Bezier} into the given number of line segments
	def lines(count=20)
	    (0..1).step(1.0/count).map {|t| self[t]}.each_cons(2).map {|a,b| Line.new a, b}
	end
    end
end
