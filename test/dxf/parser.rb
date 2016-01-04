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

    it 'must parse a file with some arcs' do
      parser = File.open('test/fixtures/filleted-box.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
    	parser.entities.length.must_equal 8
    	circle = parser.entities.last
    	circle.must_be_instance_of(DXF::Arc)
    	circle.center.must_equal Geometry::Point[11,11]
    	circle.radius.must_equal 1
      circle.a1.must_equal 180.0
      circle.a2.must_equal 270.0
    end

    it 'must parse a file with a translated circle' do
	parser = File.open('test/fixtures/circle_translate.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 1
	circle = parser.entities.last
	circle.must_be_instance_of(DXF::Circle)
	circle.center.must_equal Geometry::Point[1,1]
	circle.radius.must_equal 1
    end

    it 'must parse a file with a lightweight polyline' do
	parser = File.open('test/fixtures/square_lwpolyline_inches.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 1
	parser.entities.all? {|a| a.kind_of? DXF::LWPolyline }.must_equal true
	parser.entities.first.points.length.must_equal 4
    end

    it 'must parse a file with a square' do
	parser = File.open('test/fixtures/square_inches.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 4
	line = parser.entities.last
	line.must_be_instance_of(DXF::Line)
	line.first.must_equal Geometry::Point[0, 1]
	line.last.must_equal Geometry::Point[0, 0]
    end

    it 'must parse a file with a spline' do
	parser = File.open('test/fixtures/spline.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 82
	parser.entities.all? {|a| a.kind_of? DXF::Spline }.must_equal true
    end
end
