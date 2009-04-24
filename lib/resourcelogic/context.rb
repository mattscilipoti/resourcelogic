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
        klass.helper_method :context, :contexts, :contexts_url_parts, :contextual_views, :contextual_views?, :context_template_name
      end
      
      private
        def context
          @context ||= contexts.last
        end
        
        def contexts
          return @contexts if defined?(@contexts)
          path_parts = request.path.split("/")
          path_parts.shift
          @contexts = []
          path_parts.each_with_index do |part, index|
            break if model_name_from_path_part(part.split(".").first) == model_name.to_sym
            @contexts << (part.to_i > 0 ? @contexts.pop.to_s.singularize.to_sym : part.underscore.to_sym)
          end
          @contexts
        end
        
        def contexts_url_parts
          return @contexts_url_parts if @contexts_url_parts
          path_parts = request.path.split("/")
          path_parts.shift
          @contexts_url_parts = []
          path_parts.each_with_index do |part, index|
            break if model_name_from_path_part(part.split(".").first) == model_name.to_sym
            if part.to_i > 0
              @contexts_url_parts << [model_name_from_path_part(@contexts_url_parts.pop), part.to_i]
            else
              @contexts_url_parts << part.underscore.to_sym
            end
          end
          @contexts_url_parts
        end
        
        def model_name_from_path_part(part)
          part = part.to_s.singularize
          model_name_from_route_alias(part) || part.to_sym
        end
        
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