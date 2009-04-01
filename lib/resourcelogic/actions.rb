module Resourcelogic
  module Actions
    ACTIONS           = [:index, :show, :new_action, :create, :edit, :update, :destroy].freeze
    FAILABLE_ACTIONS  = ACTIONS - [:index, :new_action, :edit].freeze
    
    def self.included(klass)
      klass.class_eval do
        extend Config
        ACTIONS.each do |action|
          class_scoping_reader action, FAILABLE_ACTIONS.include?(action) ? FailableActionOptions.new : ActionOptions.new
        end
        add_acts_as_resource_module(Methods)
      end
    end
    
    module Config
      def actions(*opts)
        config = {}
        config.merge!(opts.pop) if opts.last.is_a?(Hash)
        
        all_actions = (false && singleton? ? Resourcelogic::SINGLETON_ACTIONS : Resourcelogic::Actions::ACTIONS) - [:new_action] + [:new]
        
        actions_to_remove = []
        if opts.first == :none
          actions_to_remove = all_actions
        else
          actions_to_remove += all_actions - opts unless opts.first == :all
          actions_to_remove += [*config[:except]] if config[:except]
          actions_to_remove.uniq!
        end

        actions_to_remove.each { |action| undef_method(action) if method_defined?(action) }
      end
    end
    
    module Methods
      def new
        build_object
        load_object
        before :new_action
        response_for :new_action
      end
    
      def create
        build_object
        load_object
        before :create
        if object.save
          after :create
          set_flash :create
          response_for :create
        else
          after :create_fails
          set_flash :create_fails
          response_for :create_fails
        end
      end
    
      def edit
        load_object
        before :edit
        response_for :edit
      end

      def update
        load_object
        object.attributes = object_params
        before :update
        if object.save
          after :update
          set_flash :update
          response_for :update
        else
          after :update_fails
          set_flash :update_fails
          response_for :update_fails
        end
      end

      def destroy
        load_object
        before :destroy
        object.destroy
        after :destroy
        set_flash :destroy
        response_for :destroy
      rescue DestroyNotAllowed
        after :destroy_fails
        set_flash :destroy_fails
        response_for :destroy_fails
      end
    
      def show
        load_object
        before :show
        response_for :show
      rescue ActiveRecord::RecordNotFound
        response_for :show_fails
      end
    
      def index
        load_collection
        before :index
        response_for :index
      end
      
      private
        # Used to actually pass the responses along to the controller's respond_to method.
        #
        def response_for(action)
          begin
            respond_to do |wants|
              options_for(action).response.each do |method, block|
                if block.nil?
                  wants.send(method)
                else
                  wants.send(method) { instance_eval(&block) }
                end
              end
            end
          rescue ActionController::DoubleRenderError
          end
        end

        # Calls the after callbacks for the action, if one is present.
        #
        def after(action)
          invoke_callbacks *options_for(action).after
        end

        # Calls the before block for the action, if one is present.
        #
        def before(action)
          invoke_callbacks *self.class.send(action).before
        end
  
        # Sets the flash and flash_now for the action, if it is present.
        #
        def set_flash(action)
          set_normal_flash(action)
          set_flash_now(action)
        end
  
        # Sets the regular flash (i.e. flash[:notice] = '...')
        #
        def set_normal_flash(action)
          if f = options_for(action).flash
            flash[:notice] = f.is_a?(Proc) ? instance_eval(&f) : options_for(action).flash
          end
        end
  
        # Sets the flash.now (i.e. flash.now[:notice] = '...')
        #
        def set_flash_now(action)
          if f = options_for(action).flash_now
            flash.now[:notice] = f.is_a?(Proc) ? instance_eval(&f) : options_for(action).flash_now
          end
        end
  
        # Returns the options for an action, which is a symbol.
        #
        # Manages splitting things like :create_fails.
        #
        def options_for(action)
          action = action == :new_action ? [action] : "#{action}".split('_').map(&:to_sym)
          options = self.class.send(action.first)
          options = options.send(action.last == :fails ? :fails : :success) if Resourcelogic::Actions::FAILABLE_ACTIONS.include? action.first
  
          options
        end
  
        def invoke_callbacks(*callbacks)
          unless callbacks.empty?
            callbacks.select { |callback| callback.is_a? Symbol }.each { |symbol| send(symbol) }
    
            block = callbacks.detect { |callback| callback.is_a? Proc }
            instance_eval &block unless block.nil?
          end
        end
        
        def load_parent
          instance_variable_set "@#{parent_model_name}", parent_object if parent?
        end
        
        def build_object
          return @object if @object
          @object = end_of_association_chain.send parent? ? :build : :new
          @object.attributes = object_params
          @object
        end
    
        # Used internally to load the member object in to an instance variable @#{model_name} (i.e. @post)
        #
        def load_object
          load_parent
          instance_variable_set "@#{object_name}", object
        end
    
        # Used internally to load the collection in to an instance variable @#{model_name.pluralize} (i.e. @posts)
        #
        def load_collection
          load_parent
          instance_variable_set "@#{object_name.to_s.pluralize}", collection
        end
    end
  end
end
