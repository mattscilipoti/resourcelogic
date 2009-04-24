module Resourcelogic
  module Self
    def self.included(klass)
      klass.class_eval do
        extend Config
        add_acts_as_resource_module(UrlParts)
        add_acts_as_resource_module(Reflection)
      end
    end
    
    module Config
      def model_name(value = nil)
        config(:model_name, value, controller_name.singularize.underscore)
      end
      
      def object_name(value = nil)
        config(:object_name, value, controller_name.singularize.underscore)
      end
    end
    
    module UrlParts
      private
        # Used internally to provide the options to smart_url from Urligence.
        #
        def collection_url_parts(action = nil, url_params = {})
          [action] + contexts_url_parts + [model_name.to_s.pluralize.to_sym, url_params]
        end
        
        # Used internally to provide the options to smart_url from Urligence.
        #
        def object_url_parts(action = nil, *alternate_object_or_params)
          alternate_object, url_params = identify_object_or_params(alternate_object_or_params)
          url_object = alternate_object || (param && object)
          object_parts = url_object ? [model_name.to_sym, url_object] : model_name.to_sym
          [action] + contexts_url_parts + [object_parts, url_params]
        end
        
        def identify_object_or_params(object_or_params)
          obj = nil
          url_params = nil
          if object_or_params.size > 1
            url_params = object_or_params.last if object_or_params.last.is_a?(Hash)
            obj = object_or_params.first
          elsif object_or_params.first.is_a?(Hash)
            url_params = object_or_params.first
          else
            obj = object_or_params.first
          end
          [obj, url_params]
        end
    end
    
    module Reflection
      def self.included(klass)
        klass.helper_method :model_name, :collection, :object
      end
      
      private
        # Convenience method for the class level model_name method
        def model_name
          self.class.model_name
        end
        
        # Convenience method for the class level object_name method
        def object_name
          self.class.object_name
        end
        
        # The current model for the resource.
        def model # :doc:
          model_name.to_s.camelize.constantize
        end
        
        # The collection for the resource.
        def collection # :doc:
          end_of_association_chain.all
        end

        # The current paremter than contains the object identifier.
        def param # :doc:
          params[:id]
        end
        
        # The parameter hash that contains the object attributes.
        def object_params
          params["#{object_name}"]
        end
        
        # The current member being used. If no param is present, it will look for
        # a current_#{object_name} method. For example, if you have a UsersController
        # and its a singleton controller, meaning no identifier is needed, this will
        # look for a current_user method. If this is not the behavioru you want, simply
        # overwrite this method.
        def object # :doc:
          return @object if defined?(@object)
          if param.nil? && respond_to?("current_#{object_name}", true)
            @object = send("current_#{object_name}")
          else
            @object = end_of_association_chain.find(param)
          end
        end
        
        # The singleton module will override this when included.
        def singleton?
          false
        end
    end
  end
end