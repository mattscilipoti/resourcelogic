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
      private
        def parent_url_parts(action = nil, url_params = {})
          [action] + contexts_url_parts + [url_params]
        end
        
        def parent_collection_url_parts(action = nil, url_params = {})
          [action] + contexts_url_parts + [url_parts.pop.first.to_s.pluralize.to_sym, url_params]
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
          return @parent_alias if defined?(@parent_alias)
          parent_from_path?
          @parent_alias
        end
        
        # Returns the type of the current parent
        #
        def parent_model_name
          return @parent_model_name if defined?(@parent_model_name)
          parent_from_path?
          @parent_model_name
        end
        
        # Returns the type of the current parent extracted form a request path
        #    
        def parent_from_path?
          return @parent_from_path if defined?(@parent_from_path)
          belongs_to.each do |model_name, options|
            request.path.split('/').reverse.each do |path_part|
              ([model_name] + (route_aliases[model_name] || [])).each_with_index do |possible_name, index|
                if [possible_name.to_s, possible_name.to_s.pluralize].include?(path_part)
                  @parent_model_name = model_name
                  @parent_alias = index > 0 ? possible_name : nil
                  return @parent_from_path = true
                end
              end
            end
          end
          @parent_from_path = false
        end
        
        # Returns true/false based on whether or not a parent is present.
        #
        def parent?
          !parent_model_name.nil?
        end
        
        # Returns true/false based on whether or not a parent is a singleton.
        #
        def parent_singleton?
          parent_param.nil?
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