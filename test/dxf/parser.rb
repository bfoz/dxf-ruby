require 'minitest/autorun'
require 'dxf/parser'

describe DXF::Parser do
    it 'must read from an IO stream' do
	File.open('test/fixtures/circle.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
    end

    it 'must parse a file with a circle' do
	parser = File.open('test/fixtures/circle.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 1
	circle = parser.entities.last
	circle.must_be_instance_of(DXF::Circle)
	circle.center.must_equal Geometry::Point[0,0]
	circle.radius.must_equal 1
    end

    it 'must parse a file with a translated circle' do
	parser = File.open('test/fixtures/circle_translate.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 1
	circle = parser.entities.last
	circle.must_be_instance_of(DXF::Circle)
	circle.center.must_equal Geometry::Point[1,1]
	circle.radius.must_equal 1
    end

    it 'must parse a file with a square' do
	parser = File.open('test/fixtures/square_inches.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 4
	line = parser.entities.last
	line.must_be_instance_of(DXF::Line)
	line.first.must_equal Geometry::Point[0, 1]
	line.last.must_equal Geometry::Point[0, 0]
    end
end
