module Ecore
  module Validations
  
    module ClassMethods
    
      attr_accessor :validations
      
      # validates attribute for specific properties. if type was
      # set with option(:nil => false), a validates :presence, :fieldname
      # has been setup automatically
      # e.g.:
      # validates :presence, :firstname
      def validates( type, name )
        self.validations ||= []
        case type
        when :presence || :required
          self.validations << "(@#{name}.nil? or (@#{name}.is_a?(String) && @#{name}.empty?)) ? (@errors[:#{name}] = ['#{name} is required'] ; false) : true"
        when :email_format
          self.validations << "(@#{name} && @#{name}.size > 0 && @#{name}.match(/^([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})$/i).nil?) ? (@errors[:#{name}] = ['#{name} is not a valid email address'] ; false) : true"
        end
      end
      
      def validation_attrs
        attrs = []
        klass = self
        while klass.new.is_a?(Ecore::NodeAtom)
          attrs = klass.validations + attrs if klass.validations
          klass = klass.superclass
        end
        attrs
      end
      
    end
    
    module InstanceMethods
    
      attr_accessor :errors
      
      # perform all queued validations
      def do_validation
        @errors ||= {}
        self.class.validation_attrs.each do |validation|
          return false unless eval(validation)
        end
        true
      end
      
    end

  end
end
