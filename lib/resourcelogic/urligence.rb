module Resourcelogic
  module Urligence
    def self.included(klass)
      klass.helper_method :smart_url, :smart_path, :hash_for_smart_url, :hash_for_smart_path
    end
    
    def smart_url(*url_parts)
      url_params = url_parts.extract_options!
      url_parts.push(:url)
      url_parts.push(url_params)
      urligence(*url_parts)
    end
  
    def smart_path(*url_parts)
      url_params = url_parts.extract_options!
      url_parts.push(:path)
      url_parts.push(url_params)
      urligence(*url_parts)
    end
  
    def hash_for_smart_url(*url_parts)
      urligence(*url_parts.unshift(:hash_for).push(:url).push({:type => :hash}))
    end
  
    def hash_for_smart_path(*url_parts)
      urligence(*url_parts.unshift(:hash_for).push(:path).push({:type => :hash}))
    end
  
    def urligence(*url_parts)
      url_parts = cleanup_url_parts(url_parts)
      url_fragments = extract_url_fragments(url_parts)
      url_objects = extract_url_objects(url_parts)
    
      if url_parts.first != :hash_for
        send url_fragments.join("_"), *url_objects
      else
        url_params = url_objects.extract_options!
        params = {}
        url_objects.each_with_index do |obj, i|
          key = i == (url_objects.size - 1) ? :id : (obj.is_a?(Array) ? "#{obj.first}_id".to_sym : "#{obj.class.name.underscore}_id".to_sym)
          params.merge!((obj.is_a?(Array)) ? {key => obj[1].to_param} : {key => obj.to_param})
        end
  
        params.merge!(url_params)
        send url_fragments.join("_"), params
      end
    end
  
    private
      # The point of this method is to replace any object if a url param is passed. For example:
      #
      #   [:admin, [:user, user_object], {:user_id => 4}]
      #
      # The "user_object" should be replaced by user with id 4, since we are explicitly saying we want to use User.find(4).
      # The last part is the url_params.
      #
      # This also pluralizes path names if the obj is nil. Example:
      #
      #   [:user, nil]
      #
      # No param was passed to replace the nil object as in the example above, so it should be:
      #
      #   :users
      #
      # This is needed for contextual development. Take modifying a resource from another, but a
      # parent resource is not needed. For example:
      #
      #   payments/credit_cards
      #
      # You can manage and select a credit card from the credit cards resource but a payment object
      # is not needed. In a sense you are just creating a "payments" context.
      def cleanup_url_parts(url_parts)
        url_parts = url_parts.compact
        url_params = url_parts.last.is_a?(Hash) ? url_parts.last : {}
        non_symbol_object_total = url_parts.select { |object| !object.is_a?(Symbol) }.size - 1
        non_symbol_object_count = 0
        new_url_parts = []
        url_parts.each do |object|
          non_symbol_object_count += 1 if !object.is_a?(Symbol)
          if !object.is_a?(Array)
            new_url_parts << object
          else
            klass = object.first.to_s.camelize.constantize rescue nil
            klass_name = klass ? klass.name.underscore : nil
            key = (non_symbol_object_count == non_symbol_object_total) ? :id : "#{object.first}_id".to_sym
            obj = (url_params.key?(key) ? ((!klass && url_params[key]) || (url_params[key] && klass.find(url_params.delete(key)))) : object[1])
            new_url_parts << (obj.nil? ? object.first.to_s.pluralize.to_sym : [object.first, obj])
          end
        end
        new_url_parts
      end
  
  
      def extract_url_fragments(url_parts)
        fragments = url_parts.collect do |obj|
          if obj.is_a?(Symbol)
            obj
          elsif obj.is_a?(Array)
            obj.first
          elsif !obj.is_a?(Hash)
            obj.class.name.underscore.to_sym
          end
        end
        fragments.compact
      end
    
      def extract_url_objects(url_parts)
        url_parts.flatten.select { |obj| !obj.is_a?(Symbol) }
      end
  end
end