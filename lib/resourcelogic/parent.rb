module Resourcelogic
  module Parent
    def self.included(klass)
      klass.class_eval do
        extend Config
        add_acts_as_resource_module(Urls)
        add_acts_as_resource_module(Reflection)
      end
    end
    
    module Config
      def belongs_to(name = nil, options = {})
        @belongs_to ||= {}
        if name.nil?
          @belongs_to
        else
          @belongs_to[name.to_sym] = options
        end
      end
    end
    
    module Urls
      def self.included(klass)
        klass.helper_method :new_parent_url, :new_parent_path, :edit_parent_url, :edit_parent_path, :parent_url, :parent_path,
          :parent_collection_url, :parent_collection_path
      end
      
      private
        def new_parent_url(url_params = {})
          smart_url *([:new] + namespaces + [parent_url_options, url_params])
        end
        
        def new_parent_path(url_params = {})
          smart_path *([:new] + namespaces + [parent_url_options, url_params])
        end
        
        def edit_parent_url(url_params = {})
          smart_url *([:edit] + namespaces + [parent_url_options, url_params])
        end
        
        def edit_parent_path(url_params = {})
          smart_path *([:edit] + namespaces + [parent_url_options, url_params])
        end
        
        def parent_url(url_params = {})
          smart_url *(namespaces + [parent_url_options, url_params])
        end
        
        def parent_path(url_params = {})
          smart_path *(namespaces + [parent_url_options, url_params])
        end
        
        def parent_collection_url(url_params = {})
          smart_url *(namespaces + [parent_model_name.to_s.pluralize.to_sym, url_params])
        end
        
        def parent_collection_path(url_params = {})
          smart_path *(namespaces + [parent_model_name.to_s.pluralize.to_sym, url_params])
        end
        
        def parent_url_options
          if parent?
            parent_name = (parent_alias || parent_model_name).to_sym
            parent_singleton? ? parent_name : [parent_name, parent_object]
          else
            nil
          end
        end
    end
    
    module Reflection
      def self.included(klass)
        klass.helper_method :parent?, :parent_model_name, :parent_object
      end
      
      private
        def belongs_to
          self.class.belongs_to
        end
      
        # Returns the relevant association proxy of the parent. (i.e. /posts/1/comments # => @post.comments)
        #
        def parent_association
          @parent_association ||= parent_object.send(model_name.to_s.pluralize.to_sym)
        end
      
        def parent_alias
          return @parent_alias if @parent_alias
          parent_from_params? || parent_from_request?
          @parent_alias
        end
  
        # Returns the type of the current parent
        #
        def parent_model_name
          return @parent_model_name if @parent_model_name
          parent_from_params? || parent_from_request?
          @parent_model_name
        end
  
        # Returns the type of the current parent extracted from params
        #    
        def parent_from_params?
          return @parent_from_params if defined?(@parent_from_params)
          belongs_to.each do |model_name, options|
            if !params["#{model_name}_id".to_sym].nil?
              @parent_model_name = model_name
              @parent_alias = options[:as]
              return @parent_from_params = true
            end
          end
          @parent_from_params = false
        end
  
        # Returns the type of the current parent extracted form a request path
        #    
        def parent_from_request?
          return @parent_from_request if defined?(@parent_from_request)
          belongs_to.each do |model_name, options|
            if request.path.split('/').include?((options[:as] && options[:as].to_s) || model_name.to_s)
              @parent_model_name = model_name
              @parent_alias = options[:as]
              return @parent_from_request = true
            end
          end
          @parent_from_request = false
        end
  
        # Returns true/false based on whether or not a parent is present.
        #
        def parent?
          !parent_model_name.nil?
        end
  
        # Returns true/false based on whether or not a parent is a singleton.
        #    
        def parent_singleton?
          !parent_from_params?
        end
  
        # Returns the current parent param, if there is a parent. (i.e. params[:post_id])
        def parent_param
          params["#{parent_model_name}_id".to_sym]
        end
  
        # Like the model method, but for a parent relationship.
        # 
        def parent_model
          @parent_model ||= parent_model_name.to_s.camelize.constantize
        end
  
        # Returns the current parent object if a parent object is present.
        #
        def parent_object
          return @parent_object if defined?(@parent_object)
          if parent?
            if parent_singleton? && respond_to?("current_#{parent_model_name}", true)
              @parent_object = send("current_#{parent_model_name}")
            else
              @parent_object = parent_model.find(parent_param)
            end
          else
            @parent_object = nil
          end
        end
  
        # If there is a parent, returns the relevant association proxy.  Otherwise returns model.
        #
        def end_of_association_chain
          parent? ? parent_association : model
        end
    end
  end
end