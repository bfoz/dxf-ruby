require_relative 'entity'

module DXF
    class Parser
	ParseError = Class.new(StandardError)

	# @!attribute entities
	#   @return [Array]  the entities that comprise the drawing
	attr_accessor :entities

	# @!attribute header
	#   @return [Hash]  the header variables
	attr_accessor :header

	def initialize(units=:mm)
	    @entities = []
	    @header = {}
	end

	def parse(io)
	    parse_pairs io do |code, value|
		raise ParseError, "DXF files must begin with group code 0, not #{code}" unless '0' == code
		raise ParseError, "Expecting a SECTION, not #{value}" unless 'SECTION' == value
		parse_section(io)
	    end
	    self
	end

	private

	def read_pair(io)
	    code = io.gets.chomp
	    value = io.gets.chomp
	    value = case code.to_i
		when 10..18, 20..28, 30..37, 40..49
		    value.to_f
		when 50..58
		    value.to_f	# degrees
		when 70..78, 90..99, 270..289
		    value.to_i
		else
		    value
	    end

	    [code, value]
	end

	def parse_pairs(io, &block)
	    while not io.eof?
		code, value = read_pair(io)
		case [code, value]
		    when ['0', 'ENDSEC']    then return
		    when ['0', 'EOF']	    then return
		    else
			yield code, value
		end
	    end
	end

	def parse_section(io)
	    code, value = read_pair(io)
	    raise ParseError, 'SECTION must be followed by a section type' unless '2' == code

	    case value
#		when 'BLOCKS'
#		when 'CLASSES'
		when 'ENTITIES'
		    parse_entities(io)
		when 'HEADER'
		    parse_header(io)
#		when 'OBJECTS'
#		when 'TABLES'
#		when 'THUMBNAILIMAGE'
		else
		    raise ParseError, "Unrecognized section type '#{value}'"
	    end
	end

	# Parse the ENTITIES section
	def parse_entities(io)
	    spline_parser = nil
	    parse_pairs io do |code, value|
		if 0 == code.to_i
		    if spline_parser
			entities.push spline_parser.to_entity
			spline_parser = nil
		    end

		    if 'SPLINE' == value
			spline_parser = SplineParser.new
		    else
			entities.push Entity.new(value)
		    end
		elsif spline_parser
		    spline_parser.parse_pair(code.to_i, value)
		else
		    entities.last.parse_pair(code, value)
		end
	    end
	end

	# Parse the HEADER section
	def parse_header(io)
	    variable_name = nil
	    parse_pairs io do |code, value|
		case code
		    when '9'
			variable_name = value
		    else
			header[variable_name] = parse_header_value(code, value)
		end
	    end
	end

	def parse_header_value(code, value)
	    case code
		when '2'    then value	# String
		else
		    raise ParseError, "Unrecognized header value: #{code} '#{value}'"
	    end
	end

# @group Helpers
	def self.code_to_symbol(code)
	    case code
		when 10..13 then :x
		when 20..23 then :y
		when 30..33 then :z
	    end
	end

	def self.update_point(point, x:nil, y:nil, z:nil)
	    a = point ? point.to_a : []
	    a[0] = x if x
	    a[1] = y if y
	    a[2] = z if z
	    Geometry::Point[a]
	end
# @endgroup
    end

    class SplineParser
	# @!attribute points
	#   @return [Array]  points
	attr_accessor :points

	attr_reader :closed, :periodic, :rational, :planar, :linear
	attr_reader :degree
	attr_reader :handle
	attr_reader :knots
	attr_reader :layer

	def initialize
	    @fit_points = []
	    @knots = []
	    @points = Array.new { Point.new }
	    @weights = []

	    @fit_point_index = Hash.new {|h,k| h[k] = 0}
	    @point_index = Hash.new {|h,k| h[k] = 0}
	end

	def parse_pair(code, value)
	    case code
		when 5 then	    @handle = value	    # Fixed
		when 8 then	    @layer = value	    # Fixed
		when 62 then    @color_number = value   # Fixed
		when 10, 20, 30
		    k = Parser.code_to_symbol(code)
		    i = @point_index[k]
		    @points[i] = Parser.update_point(@points[i], k => value)
		    @point_index[k] += 1
		when 11, 21, 31
		    k = Parser.code_to_symbol(code)
		    i = @fit_point_index[k]
		    @fit_points[i] = Parser.update_point(@fit_points[i], k => value)
		    @fit_point_index[k] += 1
		when 12, 22, 32 then    @start_tangent = update_point(@start_tangent, Parser.code_to_symbol(code) => value)
		when 13, 23, 33 then    @end_tangent = update_point(@end_tangent, Parser.code_to_symbol(code) => value)
		when 40 then    knots.push value.to_f
		when 41 then    @weights.push value
		when 42 then    @knot_tolerance = value
		when 43 then    @control_tolerance = value
		when 44 then    @fit_tolerance = value
		when 70
		    value = value.to_i
		    @closed = value[0].zero? ? nil : true
		    @periodic = value[1].zero? ? nil : true
		    @rational = value[2].zero? ? nil : true
		    @planar = value[3].zero? ? nil : true
		    @linear = value[4].zero? ? nil : true
		when 71 then    @degree = value
		when 72 then    @num_knots = value
		when 73 then    @num_control_points = value
		when 74 then    @num_fit_points = value
	    end
	end

	def to_entity
	    raise ParseError, "Wrong number of control points" unless points.size == @num_control_points

	    # If all of the points lie in the XY plane, remove the Z component from each point
	    if planar && points.all? {|a| a.z.zero?}
		@points.map! {|a| Geometry::Point[a[0, 2]]}
	    end

	    if knots.size == 2*points.size
		# Bezier?
		if knots[0,points.size].all?(&:zero?) && (knots[-points.size,points.size].uniq.size==1)
		    Bezier.new *points
		end
	    else
		Spline.new degree:degree, knots:knots, points:points
	    end
	end
    end
end