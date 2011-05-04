# DEPRECATED
# due to lack of jruby/java compatitbility
require 'libxml'

module Ecore

  XML_NODE_VERSION = "1.0" unless Ecore.const_defined?(:XML_NODE_VERSION)
  
  module XMLActions
  
    module ClassMethods
    
      include LibXML
    
      attr_accessor :relative_filename
      
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
        d.encoding = XML::Encoding::UTF_8
        d.root = XML::Node.new('ecore-repository')
        d.root['version'] = Ecore::XML_NODE_VERSION
        d.root << XML::Node.new("nodes")
        d.save(filename)
        Ecore::log.info("CREATED xml-repos file: '#{filename}' in #{Ecore::ENV[:repos_path]}")
        filename
      end
      
      private
    
      def find_xml(session, attrs, trashed)
        ::File::open((trashed ? trash_file : repos_file), "r") do |f|
          doc = XML::Parser.io(f).parse
          xml_nodes = doc.find(format_xml_query(attrs))
          a = xml_nodes.inject(Ecore::NodeArray.new){ |arr, xml_node| n = init_from_xml(session, xml_node); (arr << n if n.can_read?) ; arr }
        end
      end
      
      def format_xml_query(attrs)
        str = "//nodes/node["
        if attrs.is_a?(String)
          str = attrs
        elsif attrs.is_a?(Symbol) and attrs == :all
          str = "//nodes/node"
          str << "[@class_name='#{name}']" if name != "Ecore::Node"
        else
          str = "//nodes/node["
          str << "(@class_name='#{name}')" if name != "Ecore::Node"
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
        if k == :id
          str << "(@id='#{v}')"
        elsif k.to_s.include?("__contains")
          str << "contains(#{k.cleanup},'#{v}')"
        elsif k.to_s.include?("__gt")
          str << "(#{k.cleanup} > #{v})"
        elsif k.to_s.include?("__ge")
          str << "(#{k.cleanup} >= #{v})"
        elsif k.to_s.include?("__lt")
          str << "(#{k.cleanup} < #{v})"
        elsif k.to_s.include?("__le")
          str << "(#{k.cleanup} <= #{v})"
        else
          str << "(#{k}='#{v.to_s}')"
        end
        str
      end
      
      def init_from_xml(session, xml_node)
        attrs = xml_node.children.inject(Hash.new) { |hash, child| hash[child.name.to_sym] = child.content ; hash }
        eval("#{xml_node.attributes['class_name']}.new(attrs.merge(:session => session, :id => '#{xml_node.attributes['id']}'))")
      end
        
    end
    
    module InstanceMethods
    
      include LibXML
      
      # saves current node to xml file by hashing the node's public attributes
      # and attaches acl.
      def save_to_xml
        ::File::open(self.class.repos_file, File::RDWR|File::CREAT, 0644) do |f| 
          f.flock(File::LOCK_EX)
          doc = XML::Parser.io(f).parse
          doc = create_xml_node(doc) if new_record?
          doc.root.find_first("//nodes") << update_xml_node(doc.find_first("//nodes/node[@id='#{@id}']"))
          doc.save(self.class.repos_file)
          @new_record, @persisted = false, true
        end
      end
      
      def delete_from_xml(permanently)
        ::File::open(self.class.repos_file, File::RDWR|File::CREAT, 0644) do |f| 
          f.flock(File::LOCK_EX)
          doc = XML::Parser.io(f).parse
          trashed_node = doc.root.find_first("//nodes/node[@id='#{@id}']").remove!
          return true if permanently
          ::File::open(self.class.trash_file, File::RDWR|File::CREAT, 0644) do |trash_f|
            trash_f.flock(File::LOCK_EX)
            trash_doc = XML::Parser.io(trash_f).parse
            trash_doc.root.find_first("//nodes") << trashed_node
            trash_doc.save(self.class.trash_file)
          end
          doc.save(self.class.repos_file)
          true
        end
      end
      
      def restore_from_xml
        ::File::open(self.class.trash_file, File::RDWR|File::CREAT, 0644) do |f| 
          f.flock(File::LOCK_EX)
          doc = XML::Parser.io(f).parse
          trashed_node = doc.root.find_first("//nodes/node[@id='#{@id}']").remove!
          ::File::open(self.class.repos_file, File::RDWR|File::CREAT, 0644) do |restore_f|
            restore_f.flock(File::LOCK_EX)
            restore_doc = XML::Parser.io(restore_f).parse
            restore_doc.root.find_first("//nodes") << trashed_node
            restore_doc.save(self.class.repos_file)
          end
          doc.save(self.class.trash_file)
          true
        end
      end
      
      private
      
      def create_xml_node(doc)
        create_unique_id(doc)
        node = XML::Node.new("node")
        node['id'] = @id
        node['class_name'] = self.class.name
        doc.root.find_first("//nodes") << node
        doc
      end
      
      def create_unique_id(doc)
        generate_id
        while doc.root.find_first("//nodes/node[@id='#{@id}']")
          generate_id
        end
      end
            
      def generate_id
        @id = Digest::SHA256::hexdigest(Time.now.to_f.to_s)[0..7]
      end
      
      def update_xml_node(xml_node)
        raise NodeDisapearedError.new("couldn't find node with id #{@id} any more. lost") if xml_node.nil?
        to_hash.each_pair do |k,v|
          attrib = xml_node.find_first("#{k}")
          ( attrib = XML::Node.new(k.to_s) ; xml_node << attrib ) if attrib.nil?
          attrib.content = (v.is_a?(Time) ? v = v.to_f : v).to_s
        end
        xml_node
      end
          
      def to_hash
        attrs = Ecore::Node.attributes
        attrs |= self.class.attributes if self.class.attributes and ! self.class.attributes.empty?
        hash = attrs.inject(Hash.new) { |hash, attribute| hash[attribute] = instance_variable_get("@#{attribute}") ; hash }
        hash.merge(:acl => @acl.keys.inject(String.new){ |str, key| str << "#{key}:#{@acl[key].privileges}," ; str })
      end
      
      def parse_xml_attrs(attrs)
        @new_record = false
        @id = attrs.delete(:id)
        acl = attrs.delete(:acl)
        acl.split(',').map { |ace_str| @acl << Ace.new(:user_id => ace_str.split(':')[0], :privileges => ace_str.split(':')[1]) } if acl
        attrs
      end
      
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
