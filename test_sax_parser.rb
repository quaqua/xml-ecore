require 'rubygems'
require 'nokogiri'

include Nokogiri

class PostCallbacks < XML::SAX::Document
  def start_element(element, attributes)
    if element == "owiee"
      puts "found"
    end
  end
end

def find_name(attrs)
  attrs.each{ |a| return true if (a[0] == 'name' and a[1] == 'test999aa9') }
  false
end

init_time = Time.now
parser = XML::SAX::Parser.new(PostCallbacks.new)
parser.parse_file("repos/nodes.xml")
puts "done in #{Time.now - init_time} seconds"

init_time = Time.now

doc = nil
::File::open("repos/nodes.xml", File::RDONLY, 0644) do |f| 
  doc = XML::parse f
end

nodes = doc.search("//nodes/node[@name='test999aa9']")

puts "done in #{Time.now - init_time} seconds"
