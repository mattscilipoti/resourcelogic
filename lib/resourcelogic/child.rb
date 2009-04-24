module Resourcelogic
  module Child
    def self.included(klass)
      klass.class_eval do
        add_acts_as_resource_module(Urls)
      end
    end
    
    module Urls
      private
        # The following should work
        #
        #   child_path(obj)
        #   child_path(obj, :id => 2) # where obj is then replaced by the obj with id 2
        #   child_path(:child_name, :id => 2) # where this is a literal build of the url
        def child_url_parts(action = nil, child = nil, url_params = {})
          [action] + contexts_url_parts + [singleton? ? model_name.to_sym : [model_name.to_sym, current_object_to_use(url_params)], [child.is_a?(Symbol) ? child : child.class.name.underscore.to_sym, child], url_params]
        end
        
        def child_collection_url_parts(action = nil, child_name = nil, url_params = {})
          [action] + contexts_url_parts + [singleton? ? model_name.to_sym : [model_name.to_sym, current_object_to_use(url_params)], child_name, url_params]
        end
        
        def current_object_to_use(url_params)
          (url_params.key?("#{model_name}_id".to_sym) && url_params["#{model_name}_id".to_sym]) || (param && object)
        end
    end
  end
end