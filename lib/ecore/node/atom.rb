require 'active_model'

libdir = File::dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

require 'node/errors'
require 'node/types'
require 'node/hooks'
require 'node/array'
require 'node/validations'
require 'node/labels'
require 'node/symbol'
require 'node/xml_actions/atom_xml_actions'

module Ecore

  class NodeAtom
  
    attr_reader :id
    attr_accessor :session
    attr_accessor :primary_label_id
    
    # active_record compatibility to use restful rendering
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    
    # Types (like string, integer, time, ...)
    include Ecore::Types::InstanceMethods
    extend Ecore::Types::ClassMethods
    
    # Hooks (before, after)
    include Ecore::Hooks::InstanceMethods
    extend Ecore::Hooks::ClassMethods
    
    # Validations
    include Ecore::Validations::InstanceMethods
    extend Ecore::Validations::ClassMethods
    
    #Labels
    include Ecore::Labels::InstanceMethods
    extend Ecore::Labels::ClassMethods
    
    # Common XML Actions
    extend Ecore::AtomXMLActions::ClassMethods
    include Ecore::AtomXMLActions::InstanceMethods
    
    string      :name, :required => true, :index => true
    string      :created_by, :index => true
    string      :updated_by, :index => true
    time        :mtime, :index => true
    time        :ctime, :index => true
    string      :label_node_ids, :index => true
    
    before      :save, lambda{ self.mtime = Time.now ; self.updated_by = @session.user.id if @session and @session.is_a?(Ecore::Session) }
    before      :create, lambda{ self.ctime = Time.now ; self.created_by = @session.user.id if @session and @session.is_a?(Ecore::Session) }
    
    class << self
    
      # creates a new node and saves it
      # e.g.:
      #   Ecore::Node.create( session, :name => 'test', :status => 3 )
      def create(session, attrs)
        node = new(attrs)
        node if node.save(session)
      end
    
    end
    
    def initialize(attrs={})
      @session = attrs.delete(:session)
      attrs[:id] ? ( attrs = parse_xml_attrs(attrs) ; @new_record = false ) : @new_record = true
      update_attributes(attrs,true)
      @persisted = !@new_record
      @trashed = true if attrs[:trashed]
    end
    
    # returns if current node is new (has not been saved to the repository yet).
    # this method uses the term "record" due to active_record (rails) compatibility
    def new_record?
      @new_record
    end
    
    # returns if the current node is up-to-date with repository. As soon as an attribute
    # is changed, persisted? will return false
    def persisted?
      @persisted
    end
        
    # returns if a node is currently deleted (can't be found with normal find method)
    def deleted?
      @trashed
    end
    
    # updates current node and it's indexes
    # with given attributes and saves it. 
    # returns true, if all operations succeed
    def update_attributes( attrs, skip_save=false )
      if attrs.is_a?(Hash)
        attrs.each_pair do |attr,value|
          send(:"#{attr}=", value) if respond_to?(:"#{attr}=") # : raise(UnknownAttributeError, "unknown attribute: #{attr}")
        end 
        save unless skip_save
      else
        false
      end
    end
    
    # deletes a node if privileges grant it
    # returns true if deletion was successful
    # deletes a node permanently if :permanently is given as option
    # node.delete(:permanently)
    def delete(permanently=:keep)
      raise SecurityTransgression.new if Ecore::ENV[:sessions] and (@session.nil? or (@session and !can_delete?))
      delete_from_xml(permanently == :permanently)
    end
    
    # deletes this node and runs before and after
    # hooks if any
    def destroy
      run_hooks(:when => :before, :action => :destroy)
      if delete
        run_hooks(:when => :after, :action => :destroy)
        return true
      end
      false
    end
      
    # restores a deleted node
    # to fetch a deleted node, use:
    #   Ecore::Node.find(session, :name => 'node_name', :trashed)
    def restore
      restore_from_xml
    end

    
  end
end
