require File::expand_path('../../xml_actions/atom_xml_actions',__FILE__)
require File::expand_path('../../array',__FILE__)

module Ecore
  class NodeAssetArray < NodeArray
  
    # Common XML Actions
    extend Ecore::AtomXMLActions::ClassMethods
  
    class << self
      
      def find(attrs,trashed=false)
        raise AttributeError.new(':xml_path missing') unless attrs.has_key?(:xml_path)
        xml_path = attrs[:xml_path]
        attrs[:class_name] = attrs.delete(:type).name if attrs.is_a?(Hash) and attrs.has_key?(:type)
        node_id = attrs.delete(:node_id) if attrs.is_a?(Hash) and attrs.has_key?(:node_id)
        assets = find_xml(nil, attrs.merge(:xml_path => xml_path+'/asset'),trashed).inject(new) do |node_asset_array, xml_asset|
          node_asset_array << init_from_xml(nil, xml_asset)
        end
        assets.xml_path = xml_path
        assets.node_id = node_id
        assets
      end
      
    end
    
    attr_accessor :xml_path
    attr_accessor :node_id
    
    
    def initialize(attrs=[])
      super(attrs)
    end
    
    def <<(asset)
      raise InvalidAssetError.new unless asset.is_a?(NodeAsset)
      asset.xml_path = @xml_path
      super(asset)
    end
    
    def save_all(xml_doc,attrs)
      #TODO: raise CantSaveAssetBeforeNode.new if @node_id.nil?
      return xml_doc if size == 0
      each do |asset|
        next if asset.persisted?
        asset.parent_node_id = attrs[:node_id]
        asset.xml_path = @xml_path.sub("//nodes/node[@id='']","//nodes/node[@id='#{attrs[:node_id]}']")
        asset.xml_doc = xml_doc
        xml_doc = asset.xml_doc if asset.save
      end
      xml_doc
    end
    
  end
end
