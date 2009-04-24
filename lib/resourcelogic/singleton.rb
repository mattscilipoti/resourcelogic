# Nested and Polymorphic Resource Helpers
#
module Resourcelogic
  module Singleton
    def self.included(klass)
      klass.class_eval do
        extend Config
      end
    end
    
    module Config
      def singleton(value = nil)
        include Methods if value == true
        config(:singleton, value)
      end
      
      def singleton?
        singleton == true
      end
    end
    
    module Methods
      def self.included(klass)
        klass.class_eval do  
          methods_to_undefine = [:index, :collection, :load_collection]
          methods_to_undefine.each { |method| undef_method(method) if method_defined?(method) }
        end
      end
      
      private
        # Used to fetch the current object in a singleton controller.
        #
        # By defult this method is able to fetch the current object for resources nested with the :has_one association only. (i.e. /users/1/image # => @user.image)
        # In other cases you should override this method and provide your custom code to fetch a singleton resource object, like using a session hash.
        #
        # class AccountsController < ResourceController::Singleton
        #   private
        #     def object
        #       @object ||= Account.find(session[:account_id])
        #     end
        #   end
        #  
        def object
          @object ||= parent? ? end_of_association_chain : nil
        end

        # Returns the :has_one association proxy of the parent. (i.e. /users/1/image # => @user.image)
        #  
        def parent_association
          @parent_association ||= parent_object.send(model_name.to_sym)
        end
  
        # Used internally to provide the options to smart_url in a singleton controller.
        #  
        def object_url_parts(action = nil, alternate_object = nil)
          [action] + contexts_url_parts + [model_name.to_sym]
        end
  
        # Builds the object, but doesn't save it, during the new, and create action.
        #
        def build_object
          @object ||= singleton_build_object_base.send parent? ? "build_#{model_name}".to_sym : :new, object_params
        end
    
        # Singleton controllers don't build off of association proxy, so we can't use end_of_association_chain here
        #
        def singleton_build_object_base
          parent? ? parent_object : model
        end
        
        def singleton?
          self.class.singleton?
        end
    end
  end
end
