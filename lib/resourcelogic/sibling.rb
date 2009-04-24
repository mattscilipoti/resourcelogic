module Resourcelogic
  module Sibling
    def self.included(klass)
      klass.class_eval do
        add_acts_as_resource_module(Urls)
      end
    end
    
    module Urls
      private
        def sibling_url_parts(action = nil, sibling = nil, url_params = {})
          [action] + contexts_url_parts + [sibling.is_a?(Symbol) ? sibling : [sibling.class.name.underscore.to_sym, sibling], url_params]
        end
        
        def sibling_collection_url_parts(action = nil, sibling_name = nil, url_params = {})
          [action] + contexts_url_parts + [sibling_name, url_params]
        end
    end
  end
end