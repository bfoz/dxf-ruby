require_relative 'dxf/parser'
require_relative 'dxf/unparser'

module DXF
=begin
Reading and writing of files using AutoCAD's {http://en.wikipedia.org/wiki/AutoCAD_DXF Drawing Interchange File} format.

    {http://usa.autodesk.com/adsk/servlet/item?siteID=123112&id=12272454&linkID=10809853 DXF Specifications}
=end

    # Export a {Sketch} to a DXF file
    # @param [String] filename	The path to write to
    # @param [Sketch] sketch	The {Sketch} to export
    # @param [Symbol] units	Convert all values to the specified units (:inches or :mm)
    def self.write(filename, sketch, units=:mm)
	File.open(filename, 'w') {|f| Unparser.new(units).unparse(f, sketch)}
    end

    # Read a DXF file
    # @param [String] filename	The path to the file to read
    # @return [DXF] the resulting {DXF} object
    def self.read(filename)
	File.open(filename, 'r') {|f| DXF::Parser.new.parse(f) }
    end
end
