require 'time'
require File::expand_path( '../validations', __FILE__ )

module Ecore

  # defines types to be used within
  # Ecore::Node
  # default options are
  # :required => true         this attribute can be nil
  # :index => false      this attribute will not get indexed in ferret
  # :unique => false     this attribute must not be unique within the given class
  module Types

    module ClassMethods

      attr_accessor :time_attributes, :hidden_class, :attributes, :index_attributes

      # defines a string attribute
      # string :name, options
      def string(name,options={})
        generate_attr(name.to_sym, :string, options)
      end
      
      # defines a text attribute
      # text :name, options
      def text(name,options={})
        generate_attr(name.to_sym, :string, options)
      end
      
      # defines an array attribute
      # array :name, options
      def array(name,options={})
        generate_attr(name.to_sym, :array, options)
      end
      
      # defines an integer attribute
      # integer :name, options
      def integer(name,options={})
        generate_attr(name.to_sym, :integer, options)
      end
      
      # defines an integer attribute
      # float :name, options
      def float(name,options={})
        generate_attr(name.to_sym, :float, options)
      end
      
      # defines a time attribute
      # time :name, options
      def time(name,options={})
        generate_attr(name.to_sym, :time, options)
      end
      
      # defines a boolean attribute
      # boolean :name, options
      def boolean(name,options={})
        generate_attr(name.to_sym, :boolean, options)
      end
      
      # marks this node as hidden
      def hidden(boolean)
        self.hidden_class = boolean
      end

      private

      def generate_attr(name, type, options)
        raise TypeError.new("options must be Hash not #{options.class}") unless options.is_a?(Hash)
        if options[:index]
          self.index_attributes ||= []
          self.index_attributes << name unless self.index_attributes.include?(name)
        else
          self.attributes ||= []
          self.attributes << name unless self.attributes.include?(name)
        end
        if options[:required]
          validates :presence, name
        end
        if options[:unique]
        end

        case type
        when :string then
          __send__(:define_method, "#{name}=") { |val|
            @persisted = false 
            instance_variable_set("@#{name}",val.to_s) }
        when :boolean then
          __send__(:define_method, "#{name}=") { |val|
            @persisted = false
            set_val = false
            if val.is_a?(String)
              set_val = true if val == 'true' or val == 't' or val == '1'
            elsif val.is_a?(Fixnum)
              set_val = true if val == 1
            elsif val.is_a?(TrueClass)
              set_val = true
            end
            instance_variable_set("@#{name}",set_val) }
        when :integer then
          __send__(:define_method, "#{name}=") { |val| 
            @persisted = false
            instance_variable_set("@#{name}",val.to_i) }
        when :array then
          __send__(:define_method, "#{name}=") { |val|
            @persisted = false
            if val.is_a?(Array)
              instance_variable_set("@#{name}",val)
            else
              raise TypeError.new('not an array object')
            end
            }
        when :float then
          __send__(:define_method, "#{name}=") { |val| 
            @persisted = false
            instance_variable_set("@#{name}",val.to_f) }
        when :time then
          __send__(:define_method, "#{name}=") { |val| 
            @persisted = false
              if val.is_a?(Time)
                instance_variable_set("@#{name}",val)
              elsif val.is_a?(String) and val.match(/^\d*.\d*$/)
                instance_variable_set("@#{name}",Time.at(val.to_f))
              elsif val.is_a?(String)
                instance_variable_set("@#{name}",Time.parse(val))
              end
            }
        end

        __send__(:define_method, "#{name}") { instance_variable_get("@#{name}") }
      end

    end # ClassMethods

    module InstanceMethods

      def hidden
        return self.class.hidden_class
      end
      
      def all_attrs
        attrs_collector = []
        klass = self.class
        while klass.new.is_a?(Ecore::NodeAtom)
          attrs_collector = klass.index_attributes + attrs_collector if klass.index_attributes
          attrs_collector = klass.attributes + attrs_collector if klass.attributes
          klass = klass.superclass
        end
        attrs_collector
      end
      
      def index_attrs
        attrs_collector = []
        klass = self.class
        while klass.new.is_a?(Ecore::NodeAtom)
          attrs_collector = klass.index_attributes + attrs_collector if klass.index_attributes
          klass = klass.superclass
        end
        attrs_collector
      end
    
    end # InstanceMethods

  end
end
