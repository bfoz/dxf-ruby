require 'geometry'

require_relative 'cluster_factory'

module DXF
    # {Entity} is the base class for everything that can live in the ENTITIES block
    class Entity
	TypeError = Class.new(StandardError)

	include ClusterFactory

	attr_accessor :handle
	attr_accessor :layer

	def self.new(type)
	    case type
		when 'CIRCLE'	then Circle.new
		when 'LINE'	then Line.new
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

    class Line < Entity
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

	# @!attribute [r] first
	#   @return [Point]  the starting point of the {Line}
	def first
	    point_from_values x1, y1, z1
	end

	# @!attribute [r] last
	#   @return [Point]  the end point of the {Line}
	def last
	    point_from_values x2, y2, z2
	end
    end
end
