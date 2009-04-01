module Resourcelogic
  module Child
    def self.included(klass)
      klass.class_eval do
        add_acts_as_resource_module(Urls)
      end
    end
    
    module Urls
      def self.included(klass)
        klass.helper_method :new_child_url, :new_child_path, :edit_child_url, :edit_child_path,
          :child_url, :child_path, :child_collection_url, :child_collection_path
      end
      
      private
        def new_child_url(child_name, url_params = {})
          smart_url *new_child_url_options(child_name, url_params)
        end
        
        def new_child_path(child_name, url_params = {})
          smart_path *new_child_url_options(child_name, url_params)
        end
        
        def edit_child_url(child, url_params = {})
          smart_url *child_url_options(child, :edit, url_params)
        end
        
        def edit_child_path(child, url_params = {})
          smart_path *child_url_options(child, :edit, url_params)
        end
        
        def child_url(child, url_params = {})
          smart_url *child_url_options(child, url_params)
        end
        
        # The following should work
        #
        #   child_path(obj)
        #   child_path(obj, :id => 2) # where obj is then replaced by the obj with id 2
        #   child_path(:child_name, :id => 2) # where this is a literal build of the url
        def child_path(child, url_params = {})
          smart_path *child_url_options(child, url_params)
        end
        
        def child_collection_url(child_name, url_params = {})
          smart_url *child_collection_url_options(child_name, url_params)
        end
        
        def child_collection_path(child_name, url_params = {})
          smart_path *child_collection_url_options(child_name, url_params)
        end
        
        def new_child_url_options(child_name, url_params = {})
          object_url_options(:new) + [child_name, url_params]
        end
        
        def child_url_options(child, *action_prefix_or_params)
          action_prefix, url_params = identify_action_prefix_or_params(action_prefix_or_params)
          object_url_options(action_prefix) + [[child.is_a?(Symbol) ? child : child.class.name.underscore.to_sym, child], url_params]
        end
        
        def child_collection_url_options(child_name, url_params = {})
          object_url_options + [child_name, url_params]
        end
        
        def find_object_for_child(url_params = {})
          key = "#{model_name}_id".to_sym
          url_params.key?(key) ? end_of_association_chain.find(url_params[key]) : object
        end
        
        def find_child_name(child)
          name = args.first.class.name.underscore.to_sym
          return name if model.reflect_on_association(name)
          
          name = name.to_s.pluralize
        end
        
        def identify_action_prefix_or_params(action_prefix_or_params)
          action_prefix_or_params = action_prefix_or_params.first if action_prefix_or_params.is_a?(Array) && action_prefix_or_params.size <= 1
          action_prefix = nil
          url_params = {}
          case action_prefix_or_params
          when Array
            url_params = action_prefix_or_params.last if action_prefix_or_params.last.is_a?(Hash)
            action_prefix = action_prefix_or_params.first
          when Symbol
            action_prefix = action_prefix_or_params
          when Hash
            url_params = action_prefix_or_params
          end
          [action_prefix, url_params]
        end
    end
  end
end