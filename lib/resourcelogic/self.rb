module Resourcelogic
  module Self
    def self.included(klass)
      klass.class_eval do
        extend Config
        add_acts_as_resource_module(Urls)
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
      
      def route_name(value = nil)
        config(:route_name, value, controller_name.singularize.underscore)
      end
    end
    
    module Urls
      def self.included(klass)
        klass.helper_method :object_url, :object_path, :hash_for_object_url, :hash_for_object_path, :edit_object_url, :edit_object_path, :hash_for_edit_object_url,
          :hash_for_edit_object_path, :new_object_url, :new_object_path, :hash_for_new_object_url, :hash_for_new_object_path, :collection_url, :collection_path,
          :hash_for_collection_url, :hash_for_collection_path
      end
      
      private
        def object_url(*objects) # :doc:
          smart_url *object_url_options(nil, objects)
        end
        
        def object_path(*objects)
          smart_path *object_url_options(nil, objects)
        end
        
        def hash_for_object_url(*objects)
          hash_for_smart_url *object_url_options(nil, objects)
        end
        
        def hash_for_object_path(*objects)
          hash_for_smart_path *object_url_options(nil, objects)
        end
        
        def edit_object_url(*objects)
          smart_url *object_url_options(:edit, objects)
        end
        
        def edit_object_path(*objects)
          smart_path *object_url_options(:edit, objects)
        end
        
        def hash_for_edit_object_url(*objects)
          hash_for_smart_url *object_url_options(:edit, objects)
        end
        
        def hash_for_edit_object_path(*objects)
          hash_for_smart_path *object_url_options(:edit, objects)
        end
    
        def new_object_url(url_params = {})
          smart_url *new_object_url_options(url_params)
        end
    
        def new_object_path(url_params = {})
          smart_path *new_object_url_options(url_params)
        end
    
        def hash_for_new_object_url(url_params = {})
          hash_for_smart_url *new_object_url_options(url_params)
        end
    
        def hash_for_new_object_path(url_params = {})
          hash_for_smart_path *new_object_url_options(url_params)
        end
    
        def collection_url(url_params = {})
          smart_url *collection_url_options(url_params)
        end
    
        def collection_path(url_params = {})
          smart_path *collection_url_options(url_params)
        end
    
        def hash_for_collection_url(url_params = {})
          hash_for_smart_url *collection_url_options(url_params)
        end
    
        def hash_for_collection_path(url_params = {})
          hash_for_smart_path *collection_url_options(url_params)
        end
    
        # Used internally to provide the options to smart_url from Urligence.
        #
        def collection_url_options(url_params = {})
          contexts_url_parts + [route_name.to_s.pluralize.to_sym, url_params]
        end
    
        # Used internally to provide the options to smart_url from Urligence.
        #
        def object_url_options(action_prefix = nil, alternate_object_or_params = nil)
          alternate_object = nil
          url_params = nil
          case alternate_object_or_params
          when Array
            url_params = alternate_object_or_params.last if alternate_object_or_params.last.is_a?(Hash)
            alternate_object = alternate_object_or_params.first
          when Hash
            url_params = alternate_object_or_params
          else
            alternate_object = alternate_object_or_params
          end
          
          [action_prefix] + contexts_url_parts + [[route_name.to_sym, alternate_object || (param ? object : nil)], url_params]
        end
        
        # Used internally to provide the options to smart_url from Urligence.
        #
        def new_object_url_options(url_params = {})
          [:new] + contexts_url_parts + [route_name.to_sym, url_params]
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
        
        # Convenience method for the class level route_name method
        def route_name
          self.class.route_name
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
    end
  end
end