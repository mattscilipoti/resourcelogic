module Resourcelogic # :nodoc:
  module Base # :nodoc:
    def self.included(klass)
      klass.class_eval do
        extend ClassMethods
      end
    end
    
    module ClassMethods
      def acts_as_resource(&block)
        yield self if block_given?
        acts_as_resource_modules.each { |mod| include mod }
        init_default_actions
      end
      
      def init_default_actions
        index.wants.html
        edit.wants.html
        new_action.wants.html
        
        show do
          wants.html
          failure.wants.html { render :text => "#{model_name.to_s.singularize.humanize} not found." }
        end
        
        create do
          flash { "#{model_name.to_s.singularize.humanize} successfully created!" }
          wants.html { redirect_to object_url }
          failure.wants.html { render :action => "new" }
        end
        
        update do
          flash { "#{model_name.to_s.singularize.humanize} successfully updated!" }
          wants.html { redirect_to object_url }
          failure.wants.html { render :action => "edit" }
        end
        
        destroy do
          flash { "#{model_name.to_s.singularize.humanize} successfully removed!" }
          wants.html { redirect_to collection_url }
        end
      end
      
      # Since this part of Authlogic deals with another class, ActiveRecord, we can't just start including things
      # in ActiveRecord itself. A lot of these module includes need to be triggered by the acts_as_authentic method
      # call. For example, you don't want to start adding in email validations and what not into a model that has
      # nothing to do with Authlogic.
      #
      # That being said, this is your tool for extending Authlogic and "hooking" into the acts_as_authentic call.
      def add_acts_as_resource_module(mod, action = :append)
        modules = acts_as_resource_modules
        case action
        when :append
          modules << mod
        when :prepend
          modules = [mod] + modules
        end
        modules.uniq!
        write_inheritable_attribute(:acts_as_resource_modules, modules)
      end
      
      # This is the same as add_acts_as_authentic_module, except that it removes the module from the list.
      def remove_acts_as_resource_module(mod)
        write_inheritable_attribute(:acts_as_resource_modules, acts_as_resource_modules - [mod])
        acts_as_resource_modules
      end
      
      private
        def acts_as_resource_modules
          key = :acts_as_resource_modules
          inheritable_attributes.include?(key) ? read_inheritable_attribute(key) : []
        end
        
        def config(key, value, default_value = nil, read_value = nil)
          if value == read_value
            inheritable_attributes.include?(key) ? read_inheritable_attribute(key) : default_value
          else
            write_inheritable_attribute(key, value)
          end
        end
    end
  end
end

if defined?(::ActionController)
  module ::ActionController
    class Base
      extend Resourcelogic::Accessors
      include Resourcelogic::Base
      include Resourcelogic::Actions
      include Resourcelogic::Child
      include Resourcelogic::Context
      include Resourcelogic::Parent
      include Resourcelogic::Self
      include Resourcelogic::Sibling
      include Resourcelogic::Singleton
      include Resourcelogic::Urligence
    end
  end
end