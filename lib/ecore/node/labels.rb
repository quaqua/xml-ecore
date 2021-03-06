module Ecore

  module Labels

    module ClassMethods
    
      # create scope with given :name
      # for given :class_name
      def scope(name,attrs={})
        plural = attrs[:as] ? attrs[:as].to_s : name.to_s.pluralize
        __send__(:define_method, "add_#{name}") do |val|
          raise TypeError.new('not a Ecore::Node given') unless val.is_a?(Ecore::Node)
          eval("val.add_#{self.class.name.underscore}(self)")
        end
        __send__(:define_method, "remove_#{name}") do |val|
          raise TypeError.new('not a Ecore::Node given') unless val.is_a?(Ecore::Node)
          eval("val.remove_#{self.class.name.underscore}(self)")
        end
        raise TypeError.new('not a Ecore::Node class given') unless class_eval(name.to_s.classify).new.is_a?(Ecore::Node)
        __send__(:define_method, "#{plural}") do 
          raise NotSavedYetError.new("node hasn't been saved yet") if new_record?
          if instance_variable_get("@#{plural}_cache").nil?
            klass = eval(name.to_s.classify)
            instance_variable_set("@#{plural}_cache", eval("#{klass}.find(@session, :#{self.class.name.underscore}_node_ids.contains => @id)"))
          end
          instance_variable_get("@#{plural}_cache")
        end
        __send__(:define_method, "clear_#{plural}_cache") { instance_variable_set("@#{plural}_cache", nil) }
        
      end
      
      def has_labels(name,attrs={})
        other_class_plural = attrs[:through] ? attrs[:trough].to_s : self.name.to_s.underscore.pluralize
        __send__(:define_method, "#{name}_node_ids=") { |val| instance_variable_set("@#{name}_node_ids",val.to_s) }
        __send__(:define_method, "#{name}_node_ids") { instance_variable_get("@#{name}_node_ids") }
        __send__(:define_method, "add_#{name}") do |val|
          raise TypeError.new('not a Ecore::Node given') unless val.is_a?(Ecore::Node)
          add_label_to("#{name}_node_ids", val.id)
          eval("val.clear_#{other_class_plural}_cache")
        end
        __send__(:define_method, "remove_#{name}") do |val|
          raise TypeError.new('not a Ecore::Node given') unless val.is_a?(Ecore::Node)
          remove_label_from("#{name}_node_ids", val.id)
          eval("val.clear_#{other_class_plural}_cache")
        end
        self.index_attributes ||= []
        self.index_attributes << "#{name}_node_ids" unless self.index_attributes.include?("#{name}_node_ids")
      end
      
      
    end
    
    module InstanceMethods
            
      # adds given node as a label. First node
      # in labels array will be primary label
      # force primary label by passing :primary_label
      #   node.add_label(node_to_label_this_node_with, :primary_label)
      def add_label( node )
        raise SecurityTransgression.new("not a node object") unless node.is_a?(Ecore::Node)
        add_label_to("label_node_ids", node.id)
      end
      
      # removes given node as a label
      def remove_label( node )
        raise SecurityTransgression.new("not a node object") unless node.is_a?(Ecore::Node)
        remove_label_from("label_node_ids", node_id)
      end
          
      # returns all nodes, this node is labeled with
      def labels(attrs={:all => true})
        @label_node_ids.split(',').inject(Array.new) do |res, n_id| 
          node = Ecore::Node.find( @session, :id => n_id )
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
        label = Ecore::Node.find( @session, :id => @label_node_ids.split(',').first )
        label.is_a?(Ecore::Node) ? label : nil
      end
      
      
      private
      
      def add_label_to(attr_name, node_id, type=:default)
        tmp_labels = []
        tmp_labels = eval("@#{attr_name}").split(',') if eval("@#{attr_name}")
        tmp_labels.delete( node_id )
        if type == :primary
          tmp_labels.insert(0, node_id)
        else
          tmp_labels << node_id
        end
        instance_variable_set("@#{attr_name}",tmp_labels.join(','))
      end
      
      def remove_label_from(attr_name, node_id)
        tmp_labels = eval("@#{attr_name}").split(',') if eval("@#{attr_name}")
        tmp_labels.delete( node_id )
        instance_variable_set("@#{attr_name}",tmp_labels.join(','))
      end
      
    end
    
  end
  
end
