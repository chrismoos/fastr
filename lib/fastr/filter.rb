module Fastr
  module Filter        
    include Fastr::Log
    
    def self.included(kls)
      kls.extend(ClassMethods)
    end
    
    # Run through all the before filters and maybe return a response.
    #
    # @param controller [Fastr::Controller] The controller instance for the action
    # @param klass [Class] The controller class for the action
    # @param action [Symbol] The action that the filters should run for
    # @param response [Array] 
    # @return [Hash] The new response
    def self.run_before_filters(controller, klass, action)
      new_response = nil
      get_filters_for_action(klass, :before, action).each do |filter|
        new_response = execute_filter(filter, controller)
      end
      new_response
    end
    
    # Run the response through all after filters and return the new response.
    #
    # @param controller [Fastr::Controller] The controller instance for the action
    # @param klass [Class] The controller class for the action
    # @param action [Symbol] The action that the filters should run for
    # @param response [Array] 
    # @return [Array] The new response
    def self.run_after_filters(controller, klass, action, response)
      new_response = response
      get_filters_for_action(klass, :after, action).each do |filter|
        new_response = execute_filter(filter, controller, new_response)
      end
      new_response
    end
    
    # Executes a filter.
    # 
    # @param filter [Hash]
    # @param obj [Object]
    # @param args
    # @return [Object]
    def self.execute_filter(filter, obj, *args)
      if args.length == 0
        state = nil
      else
        state = *args
      end
      
      filter[:methods].each do |method|
        if args.length == 0
          state = obj.send(method)
        else
          state = obj.send(method, state)
        end
      end
      
      return state
    end
    
    # Get all the filters for an action.
    #
    # @param klass [Class] The class for the action
    # @param type [Symbol] Type of filters
    # @param action [Symbol] The action for the class
    # @return [Array]
    def self.get_filters_for_action(klass, type, action)
      get_filters(klass, type).find_all { |f| run_filter?(f, action) }
    end
    
    # Gets the filters for a class.
    #
    # @param klass [Class] The class to get the filters from
    # @param type [Symbol] The type of filters to get
    # @return [Array]
    def self.get_filters(klass, type)
      filter_var = "@filters_#{type}".to_sym
      if klass.instance_variable_defined? filter_var
        return klass.instance_variable_get(filter_var)
      else
        return []
      end
    end
    
    
    
    def self.run_filter?(filter, action)
      return true if filter.has_key? :all and filter[:all] == true
      return true if filter.has_key? :only and filter[:only].include? action
      return true if filter.has_key? :except and not filter[:except].include? action
      return false
    end
    
    # Halt the filter chain and return a response.
    # @param response [Hash] Rack response
    def filter_stop(response)
      response
    end
    
    # Continue through the filter chain
    def filter_continue
      nil
    end
    
    module ClassMethods
      def before_filter(*args)
        add_filter(:before, *args)
      end
      
      def after_filter(*args)
        add_filter(:after, *args)
      end
      
      private
      
      def add_filter(type, *args)
        methods = []
        options = {}
        args.each do |arg|
          if arg.kind_of? Symbol
            methods << arg
          elsif arg.kind_of? Hash
            options = arg
          end
        end
        setup_filter(methods, options, type)
      end
      
      def setup_filter(methods, options, type)
        filter_var = "@filters_#{type}".to_sym
        
        if self.instance_variable_defined? filter_var
          f = self.instance_variable_get(filter_var)
        else
          f = []
          self.instance_variable_set(filter_var, f)
        end

        if options.has_key? :only and options[:only].kind_of? Array
          f << {:methods => methods, :only => options[:only]}
        elsif options.has_key? :except and options[:except].kind_of? Array
          f << {:methods => methods, :except => options[:except]}
        else
          f << {:methods => methods, :all => true}
        end
      end
    end
  end
end