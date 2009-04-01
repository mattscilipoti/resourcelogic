module Resourcelogic
  module Sibling
    def self.included(klass)
      klass.class_eval do
        add_acts_as_resource_module(Urls)
      end
    end
    
    module Urls
      def self.included(klass)
        klass.helper_method :new_sibling_url, :new_sibling_path, :edit_sibling_url, :edit_sibling_path,
          :sibling_url, :sibling_path, :sibling_collection_url, :sibling_collection_path
      end
      
      private
        def new_sibling_url(sibling_name, url_params = {})
          smart_url *new_sibling_url_options(sibling_name, url_params)
        end
        
        def new_sibling_path(sibling_name, url_params = {})
          smart_path *new_sibling_url_options(sibling_name, url_params)
        end
        
        def edit_sibling_url(sibling, url_params = {})
          smart_url *sibling_url_options(sibling, :edit, url_params)
        end
        
        def edit_sibling_path(sibling, url_params = {})
          smart_path *sibling_url_options(sibling, :edit, url_params)
        end
        
        def sibling_url(sibling, url_params = {})
          smart_url *sibling_url_options(sibling, url_params)
        end
        
        def sibling_path(sibling, url_params = {})
          smart_path *sibling_url_options(sibling, url_params)
        end
        
        def sibling_collection_url(sibling_name, url_params = {})
          smart_url *sibling_collection_url_options(sibling_name, url_params)
        end
        
        def sibling_collection_path(sibling_name, url_params = {})
          smart_path *sibling_collection_url_options(sibling_name, url_params)
        end
        
        def new_sibling_url_options(sibling_name, url_params = {})
          [:new] + namespaces + [parent_url_options, sibling_name, url_params]
        end
        
        def sibling_url_options(sibling, *action_prefix_or_params)
          action_prefix, url_params = identify_action_prefix_or_params(action_prefix_or_params)
          [action_prefix] + namespaces + [parent_url_options, [sibling.class.name.underscore.to_sym, sibling], url_params]
        end
        
        def sibling_collection_url_options(sibling_name, url_params = {})
          namespaces + [parent_url_options, sibling_name, url_params]
        end
    end
  end
end