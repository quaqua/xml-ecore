module Ecore
  module Hooks

    module ClassMethods

      attr_accessor :before_save_hooks, :after_save_hooks,
                    :before_create_hooks, :after_create_hooks,
                    :before_destroy_hooks, :after_destroy_hooks

      # setup hooks to [] or Ecore::Node.hooks if subclassed
      def setup_hooks
        self.before_save_hooks = []
        self.after_save_hooks = []
        self.before_create_hooks = []
        self.after_create_hooks = []
        self.before_destroy_hooks = []
        self.after_destroy_hooks = []
      end

      # setup a before hook
      # e.g.:
      # before :save, :method_name
      # before :save do
      #   things here
      # end
      def before(action, method=nil, &block)
        if action.to_sym == :save
          add_save_before(method,&block)
        elsif action.to_sym == :create
          add_create_before(method,&block)
        elsif action.to_sym == :destroy
          add_destroy_before(method,&block)
        end
      end

      # setup an after hook
      # will be called after an object has called :save, :create, :load
      # e.g.:
      # after :save, :method_name
      # after :create do
      #   things here
      # end
      def after(action, method=nil, &block)
        if action.to_sym == :save
          add_save_after(method,&block)
        elsif action.to_sym == :create
          add_create_after(method,&block)
        elsif action.to_sym == :destroy
          add_destroy_after(method,&block)
        end
      end

      private

      def add_save_before(method, &block)
        self.before_save_hooks ||= []
        if method
          self.before_save_hooks.push(method) unless self.before_save_hooks.include?(method)
        else
          self.before_save_hooks.push(lambda &block) unless self.before_save_hooks.include?(lambda &block)
        end
      end

      def add_save_after(method, &block)
        self.after_save_hooks ||= []
        if method
          self.after_save_hooks.push(method) unless self.after_save_hooks.include?(method)
        else
          self.after_save_hooks.push(lambda &block) unless self.after_save_hooks.include?(lambda &block)
        end
      end
      
      def add_create_before(method, &block)
        self.before_create_hooks ||= []
        if method
          self.before_create_hooks.push(method) unless self.before_create_hooks.include?(method)
        else
          self.before_create_hooks.push(lambda &block) unless self.before_create_hooks.include?(lambda &block)
        end
      end

      def add_create_after(method, &block)
        self.after_create_hooks ||= []
        if method
          self.after_create_hooks.push(method) unless self.after_create_hooks.include?(method)
        else
          self.after_create_hooks.push(lambda &block) unless self.after_create_hooks.include?(lambda &block)
        end
      end
      
      def add_destroy_before(method, &block)
        self.before_destroy_hooks ||= []
        if method
          self.before_destroy_hooks.push(method) unless self.before_destroy_hooks.include?(method)
        else
          self.before_destroy_hooks.push(lambda &block) unless self.before_destroy_hooks.include?(lambda &block)
        end
      end

      def add_destroy_after(method, &block)
        self.after_destroy_hooks ||= []
        if method
          self.after_destroy_hooks.push(method) unless self.after_destroy_hooks.include?(method)
        else
          self.after_destroy_hooks.push(lambda &block) unless self.after_destroy_hooks.include?(lambda &block)
        end
      end
      
    end # ClassMethods

    module InstanceMethods

      def run_hooks(option)
        eval_str = "#{option[:when].to_s}_#{option[:action].to_s}_hooks"
        hook_collector = []
        klass = self.class
        while klass.new.is_a?(Ecore::NodeAtom)
          hook_collector = klass.class_eval(eval_str) + hook_collector if klass.class_eval(eval_str)
          klass = klass.superclass
        end
        hook_collector.each do |hook|
          instance_eval(&hook)
        end
      end
      
      def run_before_hooks
        if self.new_record?
          run_hooks(:when => :before, :action => :create) 
          @run_after_create_hook = true
        else
          @run_after_create_hook = false
        end 
        run_hooks(:when => :before, :action => :save)
      end
      
      def run_after_hooks
        if @run_after_create_hook
          run_hooks(:when => :after, :action => :create) if @run_after_create_hook
        end
        run_hooks(:when => :after, :action => :save)
      end

    end

  end # InstanceMethods

end
