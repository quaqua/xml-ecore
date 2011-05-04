require 'nokogiri'

module Ecore
  
  module NodeXMLActions    
    
    module InstanceMethods
    
      include Nokogiri
      
      # saves current node to xml file by hashing the node's public attributes
      # and attaches acl.
      def save_to_xml
        Ecore::Mutex::request_lock(self.id) unless new_record?
        doc = read_xml_doc
        doc = create_xml_node(doc) if new_record?
        Ecore::Mutex::request_lock(self.id) if new_record?
        doc.root << update_xml_node(doc.search("//nodes/node[@id='#{@id}']").first)
        doc = assets.save_all(doc, :node_id => @id)
        write_xml_doc(doc)
        Ecore::Mutex::release(self.id)
        Ecore::Auditing::log((@new_record ? "created" : "saved"), self)
        @new_record, @persisted = false, true
      end
      
      def delete_from_xml(permanently)
        Ecore::Mutex::request_lock(self.id)
        doc = read_xml_doc
        trashed_node = doc.search("//nodes/node[@id='#{@id}']").remove.first
        write_xml_doc(doc)
        return true if permanently
        trashed_doc = read_xml_doc(self.class.trash_file)
        trashed_doc.xpath("//nodes").first << trashed_node
        write_xml_doc(trashed_doc,self.class.trash_file)
        Ecore::Mutex::release(self.id)
        Ecore::Auditing::log("deleted", self)
        @trashed = true
        true
      end
      
      def restore_from_xml
        Ecore::Mutex::request_lock(self.id)
        trashed_doc = read_xml_doc(self.class.trash_file)
        trashed_node = trashed_doc.search("//nodes/node[@id='#{@id}']").remove.first
        write_xml_doc(trashed_doc,self.class.trash_file)
        doc = read_xml_doc
        doc.root << trashed_node
        write_xml_doc(doc)
        Ecore::Mutex::release(self.id)
        Ecore::Auditing::log("restored", self)
        @trashed = false
        true
      end
      
      private
         
      def restore_xml_acl(acl_str)
        if acl_str
          acl_str.split(',').inject(Acl.new) do |tmp_acl, ace_str|
            tmp_acl[ace_str.split(':')[0].to_s] = Ace.new(:user_id => ace_str.split(':')[0], 
                                                     :privileges => ace_str.split(':')[1])
            tmp_acl
          end
        end
      end
    
    end
  
  end
  
end
