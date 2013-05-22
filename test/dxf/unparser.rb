require 'minitest/autorun'
require 'dxf'

describe DXF::Unparser do
    subject { DXF::Unparser.new }
    let(:builder)   { DXF::Unparser.new }
    let(:eof)	    { ['0', 'EOF'] }
    let(:empty_header) {['0', 'SECTION',
			 '2', 'HEADER',
			 '0', 'ENDSEC']}
    let(:end_section)	    { ['0', 'ENDSEC'] }
    let(:entities_header)   { ['0', 'SECTION',
			       '2', 'ENTITIES'] }

    describe "when give an empty Sketch object" do
	it "must export a minimal file" do
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
	    subject.container = sketch
	    builder.container = sketch
	end

	it "with a single Arc" do
	    sketch.push Geometry::Arc.new center:[0,0], radius:1, start:0, end:45
	    builder.to_s.must_equal (empty_header + entities_header + ['0', 'ARC',
				     '10', '0',
				     '20', '0',
				     '40', '1',
				     '50', '0',
				     '51', '45'] + end_section + eof).join("\n")
	end

	it "with a single Circle" do
	    sketch.push Geometry::Circle.new [0,0], 1
	    builder.to_s.must_equal File.read('test/fixtures/circle.dxf')
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

	it "with a group" do
	    Sketch::Builder.new(sketch).evaluate do
		group origin:[1,1] do
		    circle center:[0,0], radius:1
		end
	    end
	    subject.to_s.must_equal File.read('test/fixtures/circle_translate.dxf')
	end

	describe "when the sketch has a transformation" do
	    before do
		sketch.transformation = Geometry::Transformation.new(origin:[2,2])
	    end

	    it "and a group" do
		Sketch::Builder.new(sketch).evaluate do
		    group origin:[-1,-1] do
			circle center:[0,0], radius:1
		    end
		end
		subject.to_s.must_equal File.read('test/fixtures/circle_translate.dxf')
	    end
	end

	describe "with a Sketch" do
	    let(:circle_sketch) { Sketch.new { push Geometry::Circle.new(center:[0,0], radius:1) } }

	    describe "without a transformation" do
		it "must unparse correctly" do
		    sketch.push circle_sketch
		    builder.to_s.must_equal File.read('test/fixtures/circle.dxf')
		end
	    end

	    describe "with a transformation" do
		it "must unparse correctly" do
		    sketch.push circle_sketch, origin:[1,1]
		    builder.to_s.must_equal File.read('test/fixtures/circle_translate.dxf')
		end
	    end
	end

	describe "when the sketch has units" do
	    let(:sketch) { Sketch.new }

	    describe "when exporting to inches" do
		subject { DXF::Unparser.new :inches }
		let(:square_inches) { File.read('test/fixtures/square_inches.dxf') }

		before do
		    subject.container = sketch
		end

		describe "when the units are all inches" do
		    before do
			sketch.push Geometry::Polygon.new [0.inches, 0.inches], [1.inches, 0.inches], [1.inches, 1.inches], [0.inches, 1.inches]
		    end

		    it "must not convert the values" do
			subject.to_s.must_equal square_inches
		    end
		end

		describe "when the units are all metric" do
		    before do
			sketch.push Geometry::Polygon.new [0.mm, 0.mm], [25.4.mm, 0.mm], [25.4.mm, 25.4.mm], [0.mm, 25.4.mm]
		    end

		    it "must convert the values" do
			subject.to_s.must_equal square_inches
		    end
		end
	    end

	    describe "when exporting to millimeters" do
		subject { DXF::Unparser.new :mm }
		let(:square_millimeters) { File.read('test/fixtures/square_millimeters.dxf') }

		before do
		    subject.container = sketch
		end

		describe "when the units are all inches" do
		    before do
			sketch.push Geometry::Polygon.new [0.inches, 0.inches], [1.inches, 0.inches], [1.inches, 1.inches], [0.inches, 1.inches]
		    end

		    it "must convert the values" do
			subject.to_s.must_equal square_millimeters
		    end
		end

		describe "when the units are all metric" do
		    before do
			sketch.push Geometry::Polygon.new [0.mm, 0.mm], [25.4.mm, 0.mm], [25.4.mm, 25.4.mm], [0.mm, 25.4.mm]
		    end

		    it "must not convert the values" do
			subject.to_s.must_equal square_millimeters
		    end
		end
	    end
	end
    end
end
