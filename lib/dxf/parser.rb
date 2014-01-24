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
	    [io.gets.chomp, io.gets.chomp]
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
	    parse_pairs io do |code, value|
		if '0' == code
		    entities.push Entity.new(value)
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
    end
end