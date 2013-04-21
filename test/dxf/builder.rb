require 'minitest/autorun'
require 'dxf'

describe DXF::Builder do
    let(:builder)   { DXF::Builder.new }
    let(:eof)	    { ['0', 'EOF'] }
    let(:empty_header) {['0', 'SECTION',
			 '2', 'HEADER',
			 '0', 'ENDSEC']}
    let(:end_section)	    { ['0', 'ENDSEC'] }
    let(:entities_header)   { ['0', 'SECTION',
			       '2', 'ENTITIES'] }

    describe "when give an empty Sketch object" do
	it "must export a minimal file" do
	    skip
	    builder.container = Sketch.new
	    builder.to_s.must_equal (empty_header + entities_header + end_section + eof).join("\n")
	end
    end

    describe "when exporting a Sketch" do
	let(:sketch) { Sketch.new }
	let(:square_lines) {
	    ['0', 'LINE',
	     '8', '0',
	     '10', '0',
	     '20', '0',
	     '11', '1',
	     '21', '0',
	     '0', 'LINE',
	     '8', '0',
	     '10', '1',
	     '20', '0',
	     '11', '1',
	     '21', '1',
	     '0', 'LINE',
	     '8', '0',
	     '10', '1',
	     '20', '1',
	     '11', '0',
	     '21', '1',
	     '0', 'LINE',
	     '8', '0',
	     '10', '0',
	     '20', '1',
	     '11', '0',
	     '21', '0']
	}

	before do
	    builder.container = sketch
	end

	it "with a single Arc" do
	    sketch.push Geometry::Arc.new [0,0], 1, 0, 45
	    builder.to_s.must_equal (empty_header + entities_header + ['0', 'ARC',
				     '10', '0',
				     '20', '0',
				     '40', '1',
				     '50', '0',
				     '51', '45'] + end_section + eof).join("\n")
	end

	it "with a single Circle" do
	    sketch.push Geometry::Circle.new [0,0], 1
	    builder.to_s.must_equal (empty_header + entities_header + ['0', 'CIRCLE',
								       '10', '0',
								       '20', '0',
								       '40', '1'] + end_section + eof).join("\n")
	end

	it "with a single Line" do
	    sketch.push Geometry::Line[[0,0], [1,1]]
	    builder.to_s.must_equal (empty_header + entities_header +
				     ['0', 'LINE',
				      '8', '0',
				      '10', '0',
				      '20', '0',
				      '11', '1',
				      '21', '1'] +
				     end_section + eof).join("\n")
	end

	it "with a single Polygon" do
	    sketch.push Geometry::Polygon.new [0,0], [1,0], [1,1], [0,1]
	    builder.to_s.must_equal (empty_header + entities_header +
				     square_lines +
				     end_section + eof).join("\n")
	end

	it "with a single Polyline" do
	    sketch.push Geometry::Polyline.new [0,0], [1,0], [1,1], [0,1]
	    builder.to_s.must_equal (empty_header + entities_header +
				     square_lines[0, 36] +
				     end_section + eof).join("\n")
	end

	it "with a single Rectangle" do
	    sketch.push Geometry::Rectangle.new [0,0], [1,1]
	    builder.to_s.must_equal (empty_header + entities_header + square_lines +
				     end_section + eof).join "\n"
	end

	it "with a single Square" do
	    sketch.push Geometry::Rectangle.new [0,0], [1,1]
	    builder.to_s.must_equal (empty_header + entities_header + square_lines +
				     end_section + eof).join "\n"
	end
    end
end
