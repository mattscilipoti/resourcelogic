# Nested and Polymorphic Resource Helpers
#
module Resourcelogic
  module Context
    def self.included(klass)
      klass.class_eval do
        extend Config
        add_acts_as_resource_module(Methods)
      end
    end
    
    module Config
      def contextual_views(value = nil)
        config(:contextual_views, value)
      end

      def contextual_views?
        !contextual_views.blank?
      end
    end
    
    module Methods
      def self.included(klass)
        klass.helper_method :context, :contexts, :contextual_views, :contextual_views?, :context_template_name
      end
      
      private
        def context
          @context ||= (parent? && (parent_alias || parent_model_name)) || (contexts.last && (contexts.last.is_a?(Array) ? contexts.last.first : contexts.last))
        end
      
        # Returns all of the current namespaces of the current controller, symbolized, in array form.
        def contexts
          return @contexts if @contexts
          path_parts = request.path.split("/")
          path_parts.shift
          @contexts = []
          path_parts.each_with_index do |part, index|
            part = part.split(".").first if (index + 1) == path_parts.size # for formats: blah.html or blah.js
            break if [(parent_alias || parent_model_name).to_s.pluralize, (parent_alias || parent_model_name).to_s, route_name.to_s.pluralize].include?(part.underscore)
            if part.to_i > 0
              @contexts << [@contexts.pop.to_s.singularize.to_sym, part]
            else
              @contexts << part.underscore.to_sym
            end
          end
          @contexts
        end
        alias_method :namespaces, :contexts
        
        def contextual_views?
          self.class.contextual_views?
        end
        
        def contextual_views
          self.class.contextual_views
        end
        
        def context_template_name(name)
          sub_folder = contextual_views.is_a?(Hash) && contextual_views.key?(context) ? contextual_views[context] : context
          sub_folder ||= "root"
          "#{controller_name}/#{sub_folder}/#{name}"
        end
        
        def default_template_name(action_name = self.action_name)
          if contextual_views?
            context_template_name(action_name)
          else
            super
          end
        end
    end
    
    module Partials
      def _pick_partial_template(partial_path)
        partial_path = context_template_name(partial_path) if respond_to?(:contextual_views?) && contextual_views? && !partial_path.include?("/")
        super
      end
    end
  end
end


module ActionView
  class Base
    include Resourcelogic::Context::Partials
  end
end