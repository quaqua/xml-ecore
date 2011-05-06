libdir = File::dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'node/atom'
require 'node/xml_actions/node_xml_actions'
require 'security/acl'

module Ecore
  
  # a node in the ecore content repository is equal to
  # a document in a object oriented database
  # Derive a Contact, Task, Event, whatsoever from Ecore::Node
  # 
  # Contact < Ecore::Node
  #   string  :firstname
  #   string  :lastname
  #   integer :age
  # end
  #
  class Node < NodeAtom
    
    # XMLActions
    include Ecore::NodeXMLActions::InstanceMethods
    
    # Access Control List
    include Ecore::AclSimplifications
    
    repos_filename  'nodes.xml'
    
    attr_accessor :acl
    
    before      :create, lambda{ self.acl << { :user => @session.user, :privileges => 'rwsd' } if @session and @session.is_a?(Ecore::Session) }
    before      :save, lambda{ add_label_id(primary_label_id, :primary) if primary_label_id }
    
    class << self
    
      # finds nodes on which given session has access on. returns a node array
      #
      # returns an Array of nodes. nothing has to be unique, names can
      # be redundant, as anything else. the node only has a unique id
      #
      #   Ecore::Node.find(session, :name => 'mynode')
      #
      # find all nodes with "ugo" if given session has access
      # 
      #   Ecore::Node.find(session, :name.contains => "ugo")
      #
      # only return nodes of type MyNode
      #
      #   MyNode.find(session, :name.contains => "ugo")
      #
      # look up nodes with name "mynode" and status 0 or 2
      #
      #   MyNode.find(session, :name => "mynode", :status => [0,2])
      #
      # find all nodes in the repository (the session has access on)
      #
      #   Ecore::Node.find( session, :all )
      # 
      def find(session, attrs, trashed=:no)
        return if attrs.is_a?(Hash) and attrs[:id] and attrs[:id].empty?
        @@cache ||= {}
        read_only = ((attrs.is_a?(Hash) and attrs.has_key?(:read_only)) ? attrs.delete(:read_only) : false)
        raise SecurityTransgression.new("session is missing") if Ecore::ENV[:sessions] and session.nil? and !read_only
        if Ecore::ENV[:caching] and attrs.is_a?(Hash) and attrs.has_key?(:id) and @@cache.has_key?(attrs[:id])
          if node = @@cache[attrs[:id]]
            if node.is_a?(Ecore::NodeAtom)
              node.session = session
              return node if node.can_read?
            end
          end
        end
        nodes = find_xml(session, attrs, trashed==:trashed).inject(Ecore::NodeArray.new) do |arr, xml_node| 
          n = init_from_xml(session, xml_node, trashed)
          arr << n if read_only or n.can_read?
          arr
        end
        if Ecore::ENV[:caching] and attrs.is_a?(Hash) and attrs.has_key?(:id) and nodes.size > 0
          @@cache = {} if @@cache.keys.size > (Ecore::ENV[:max_cache_size] || 100)
          @@cache[attrs[:id]] = nodes.first
          Ecore::log.debug("added node #{nodes.first.name} to CACHE size: #{@@cache.size}")
        end
        return nodes.first if attrs.is_a?(Hash) and attrs[:id]
        nodes
      end
      
      # alias for find(nil, :any_attrs => any_value, :read_only => true)
      def find_readonly(attrs)
        find(nil, attrs.merge(:read_only => true))
      end
      
    end
    
    # initializes a new node with given attributes
    #
    #   Ecore::Node.new(:name => 'test', :status => 2)
    # initializees a new node (but doesn't save it yet)
    def initialize(attrs={})
      @acl = (attrs.has_key?(:acl) ? restore_xml_acl(attrs.delete(:acl)) : Acl.new)
      @label_node_ids = ""
      super(attrs)
      @primary_label_id = @label_node_ids.split(',').first if @label_node_ids.size > 0
    end
    
    # saves the current node to the repository. If no session was given up till now, at latest here, a session
    # is required.
    #
    # returns true if all validations, hooks and saving succeeded
    def save(session=nil)
      @session = session unless session.nil?
      raise SecurityTransgression.new("session is nil") if Ecore::ENV[:sessions] and @session.nil?
      raise SecurityTransgression if (@session and !new_record? and !can_write?)
      if do_validation
        run_before_hooks
        save_to_xml
      	run_after_hooks
      	@@cache.delete(@id) if Ecore::ENV[:caching] and self.class.respond_to?(:cache) and @@cache.is_a?(Hash) and @@cache.has_key?(@id)
      	true
      else
        false
      end
    end
    
    # returns all nodes, labeld with this node
    def subnodes
      Ecore::Node.find( @session, :label_node_ids.contains => @id )
    end
    
    # returns all predecessor primary_labels (as nodes) until on top
    def ancestors(labels=[])
      ancs = []
      if primary_label and !labels.include?(primary_label.id)
        ancs << primary_label
        ancs = primary_label.ancestors(labels << primary_label.id) + ancs
      end
      ancs
    end

    # returns the creator (as user object)    
    def creator
      Ecore::User.find_readonly(:id => @created_by)
    end
    
    # returns the updater (as user object)
    def updater
      Ecore::User.find_readonly(:id => @updated_by)
    end

      
  end
  
end
