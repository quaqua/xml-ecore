require 'nokogiri'

module Ecore
  
  module AssetXMLActions    
    
    module InstanceMethods
    
      include Nokogiri
      
      def save_to_xml
        @xml_doc = create_xml_node(@xml_doc, :node_name => "asset", :xml_path => @xml_path) if new_record?
        @xml_doc.search(@xml_path) << update_xml_node(@xml_doc.search(@xml_path+"/asset[@id='#{@id}']").first)
        Ecore::Auditing::log((@new_record ? "created" : "saved"), self)
        @new_record, @persisted = false, true
      end
      
    end
    
  end

end
