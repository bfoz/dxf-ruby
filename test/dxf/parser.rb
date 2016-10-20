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
  circle.layer.must_equal '0'
	circle.radius.must_equal 1
    end

    it 'must parse a file with an arc' do
	parser = File.open('test/fixtures/arc.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 1
	arc = parser.entities.last
	arc.must_be_instance_of DXF::Arc

	arc.center.must_equal Geometry::Point[1,1]
	arc.radius.must_equal 1
	arc.start_angle.must_equal 180.0
	arc.end_angle.must_equal 270.0
  arc.layer.must_equal '0'
    end

    it 'must parse a file with a translated circle' do
	parser = File.open('test/fixtures/circle_translate.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 1
	circle = parser.entities.last
	circle.must_be_instance_of(DXF::Circle)
	circle.center.must_equal Geometry::Point[1,1]
	circle.radius.must_equal 1
  circle.layer.must_equal '0'
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
  parser.entities.first.layer.must_equal 'testing'
  parser.entities.first.color_number.must_equal 254
    end

    it 'must parse a file with a spline' do
	parser = File.open('test/fixtures/spline.dxf', 'r') {|f| DXF::Parser.new.parse(f) }
	parser.entities.length.must_equal 82
	parser.entities.all? {|a| a.kind_of? DXF::Spline }.must_equal true
    end
end
