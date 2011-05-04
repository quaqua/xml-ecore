require 'nokogiri'
require File::expand_path('../../mutex',__FILE__)

module Ecore

  XML_NODE_VERSION = "1.2" unless Ecore.const_defined?(:XML_NODE_VERSION)
  
  module AtomXMLActions
   
    module ClassMethods
    
      include Nokogiri
      
      attr_accessor :relative_filename
      
      # set the filename to be used to store this kind of node objects.
      # if different file is chosen, it can't be find with Ecore::Node.find any longer
      # default is 'nodes.xml'
      def repos_filename(filename)
        self.relative_filename = filename
      end
      
      # returns the xml file storing the repository
      def repos_file(relative_filename=(relative_filename||Ecore::Node.relative_filename))
        filename = ::File::join(Ecore::ENV[:repos_path],relative_filename)
        create_repos_file( filename )
      end
      
      # return the xml trash file keeping deleted xml nodes
      def trash_file(relative_filename=(relative_filename||Ecore::Node.relative_filename))
        filename = ::File::join(Ecore::ENV[:repos_path],"trashed_#{relative_filename}")
        create_repos_file( filename )
      end
      
      # creates a new repository file
      def create_repos_file( filename )
        return filename if ::File::exists?(filename)
        d = XML::Document.new
        d.encoding = 'UTF-8'
        d.root = XML::Node.new('nodes',d)
        d.root['ecoreXMLVersion'] = Ecore::XML_NODE_VERSION
        ::File.open(filename, File::RDWR|File::CREAT, 0644) {|f| d.write_xml_to f }
        Ecore::log.info("CREATED xml-repos file: '#{filename}' in #{Ecore::ENV[:repos_path]}")
        filename
      end
      
      def read_xml_doc(file=repos_file)
        doc = nil
        ::File::open(file, File::RDONLY, 0644) do |f| 
          doc = XML::parse f
        end
        doc
      end
      
      def write_xml_doc(doc, file=repos_file)
        ::File::open(file, File::RDWR|File::TRUNC, 0644) do |f|
          f.flock(File::LOCK_EX)
          doc.write_xml_to f
        end
      end
      
      private
    
      def find_xml(session, attrs, trashed=nil)
        doc = read_xml_doc((trashed ? trash_file : repos_file))
        doc.search(format_xml_query(attrs))
      end
      
      def format_xml_query(attrs,str="//nodes/node")
        str = attrs.delete(:xml_path) if attrs.is_a?(Hash) and attrs.has_key?(:xml_path)
        if attrs.is_a?(String)
          str = attrs
        elsif (attrs.is_a?(Symbol) and attrs == :all) or (attrs.is_a?(Hash) and attrs[:all])
          str << "[@class_name='#{name}']" if name != "Ecore::Node" and name != "Ecore::NodeAssetArray"
        else
          str << "["
          str << "(@class_name='#{name}')" if name != "Ecore::Node" and name != "Ecore::NodeAssetArray"
          attrs.each_pair do |k,v|
            str << " and " if str.rindex("[") != str.size-1
            v = v.to_f if v.is_a?(Time)
            if v.is_a?(Array)
              str << "("
              v.map{ |or_elem| str << create_xpath_snippet(k,or_elem) ; str << " or " unless or_elem == v.last }
              str << ")"
            else
              str << create_xpath_snippet(k,v)
            end
          end
          str << "]"
        end
        Ecore::log.info("ECORE QUERYING for: #{str}")
        str
      end
      
      def create_xpath_snippet(k,v)
        str = ""
        if k.to_s.include?("__contains_ci")
          str << "(contains(translate(@#{k.cleanup},'ABCDEFGHIJKLMNOPQRSTUVWXYZ','abcdefghijklmnopqrstuvwxyz'), '#{v.downcase}'))"
        elsif k.to_s.include?("__contains")
          str << "(contains(@#{k.cleanup}, '#{v.downcase}'))"
        elsif k.to_s.include?("__gt")
          str << "(@#{k.cleanup} > #{v})"
        elsif k.to_s.include?("__ge")
          str << "(@#{k.cleanup} >= #{v})"
        elsif k.to_s.include?("__lt")
          str << "(@#{k.cleanup} < #{v})"
        elsif k.to_s.include?("__le")
          str << "(@#{k.cleanup} <= #{v})"
        else
          str << "(@#{k}='#{v.to_s}')"
        end
        str
      end
      
      def init_from_xml(session, xml_node, trashed=:false)
        attrs = xml_node.attributes.keys.inject(Hash.new) { |hash, key| hash[key.to_sym] = xml_node[key] ; hash }
        attrs.merge!(:trashed => true) if trashed == :trashed
        eval("#{xml_node.attributes['class_name']}.new(attrs.merge(:session => session, :id => '#{xml_node.attributes['id']}'))")
      end
        
    end
    
    module InstanceMethods
    
      include Nokogiri
      
      def read_xml_doc(file=self.class.repos_file)
        self.class.read_xml_doc(file)
      end
      
      def write_xml_doc(doc, file=self.class.repos_file)
        self.class.write_xml_doc(doc, file)
      end
      
      def create_xml_node(doc,attrs={:node_name => "node", :xml_path => "//nodes"})
        create_unique_id(doc)
        node = XML::Node.new(attrs[:node_name],doc)
        node['id'] = @id
        node['class_name'] = self.class.name
        if doc.search(attrs[:xml_path]).size == 0
          doc.search(attrs[:xml_path].sub("/#{attrs[:node_name].pluralize}",'')).first << XML::Node.new(attrs[:node_name].pluralize,doc)
        end
        doc.search(attrs[:xml_path]).first << node
        doc
      end
      
      def create_unique_id(doc, xml_path="//nodes/node[@id='#{@id}']")
        generate_id
        while doc.root.xpath(xml_path).size > 0
          generate_id
        end
      end
            
      def generate_id
        @id = Digest::SHA256::hexdigest(Time.now.to_f.to_s)[0..7]
      end
      
      def update_xml_node(xml_node)
        raise NodeDisapearedError.new("couldn't find node with id #{@id} any more. lost") if xml_node.nil?
        to_hash.each_pair do |k,v|
          xml_node[k.to_s] = (v.is_a?(Time) ? v = v.to_f : v).to_s
        end
        xml_node
      end
          
      def to_hash
        hash = all_attrs.inject(Hash.new) { |hash, attribute| hash[attribute] = instance_variable_get("@#{attribute}") ; hash }
        if @acl
          hash.merge(:acl => @acl.keys.inject(String.new){ |str, key| str << "#{key}:#{@acl[key].privileges}," ; str })
        else
          hash
        end
      end
      
      def parse_xml_attrs(attrs)
        @new_record = false
        @id = attrs.delete(:id)
        acl = attrs.delete(:acl)
        parse_xml_acl_attrs(acl) if acl
        attrs
      end
      
      def parse_xml_acl_attrs(acl)
        acl.split(',').map do |ace_str| 
          @acl << Ace.new(:user_id => ace_str.split(':')[0], :privileges => ace_str.split(':')[1])
        end
      end
   
    end
    
  end
end
