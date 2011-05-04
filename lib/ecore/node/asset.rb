libdir = File::dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'atom'
require 'xml_actions/asset_xml_actions'
require 'asset/errors'

module Ecore
  class NodeAsset < NodeAtom
  
    # XMLActions
    include Ecore::AssetXMLActions::InstanceMethods
    
    attr_accessor   :xml_path
    attr_accessor   :xml_doc
    
    string   :parent_node_id
    
    # saves an asset to the given xml_path. An asset can't be saved alone. it can only saved along
    # with an associated Node
    #
    #   Ecore::Node.new.assets << Ecore::NodeAsset.new
    # should be the way to go. With this operation, the node_id will be saved to the asset as well and
    # the asset knows, where to store itself
    #
    # returns true if all validations, hooks and saving succeeded
    def save
      if do_validation
        run_before_hooks
        save_to_xml
      	run_after_hooks
      	true
      else
        false
      end
    end
        
    # returns all nodes, this node is labeled with
    def labels(attrs={:all => true})
      @label_node_ids.split(',').inject(Array.new) do |res, n_id|
        node = Ecore::NodeAssetArray.find(attrs.merge(:xml_path => "//nodes/node[@id='#{@parent_node_id}']/assets",
                                                      :id => n_id))
        attrs.each_pair do |k,v|
          res << node if (k == :all or (node.respond_to?(k) and node.send(k) == v)) and node and (!Ecore::ENV[:sessions] or node.can_read?)
        end
        res
      end
    end
    
    # for hierarchical compatibility, first node in labels will be used as 
    # primary label, respectively as parent 
    def primary_label
      raise SecurityTransgression.new('no session given') if Ecore::ENV[:sessions] and @session.nil?
      label = Ecore::NodeAssetArray.find(:xml_path => "//nodes/node[@id='#{@parent_node_id}']/assets",
                                        :id => @label_node_ids.split(',').first )
      label.is_a?(Ecore::NodeAsset) ? label : nil
    end
    
    # returns all nodes, labeld with this node
    def subassets
      Ecore::NodeAssetArray.find( :xml_path => "//nodes/node[@id='#{@parent_node_id}#]/assets",
                                  :label_node_ids.contains => @id )
    end
    
    # returns this asset's parent node
    def node
      Ecore::Node.find(@session, :id => @parent_node_id)
    end
    
  end
end
