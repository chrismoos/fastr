module Fastr
  module Dispatch
    # The folder containing static content.
    PUBLIC_FOLDER = "public"
    
    # Convenience wrapper for do_dispatch
    # This is the heart of the server, called indirectly by a Rack aware server. 
    # 
    # @param env [Hash]
    # @return [Array]
    def dispatch(env)
      return [500, {}, "Server Not Ready"] if @booting
      
      begin 
        new_env = plugin_before_dispatch(env)
        plugin_after_dispatch(new_env, do_dispatch(new_env))
      rescue Exception => e
        bt = e.backtrace.join("\n")
        [500, {}, "Exception: #{e}\n\n#{bt}"]
      end
    end
    
    # Route, instantiate controller, return response from controller's action.
    def do_dispatch(env)      
      path = env['PATH_INFO']
      
      # Try to serve a public file
      ret = dispatch_public(env, path)
      return ret if not ret.nil?
      
      log.debug "Checking for routes that match: #{path}"
      route = router.match(env)

      if route.has_key? :ok
        dispatch_controller(route, env)
      else
        [404, {"Content-Type" => "text/plain"}, ["404 Not Found: #{path}"]]
      end
    end
    
    def dispatch_controller(route, env)
      vars = route[:ok]        
      controller = vars[:controller]
      action = vars[:action].to_sym
      
      raise Fastr::Error.new("Controller and action not present in route") if controller.nil? or action.nil?
      
      
      klass = "#{controller.camelcase}Controller"
      
      log.info "Routing to controller: #{klass}, action: #{action}"
      
      klass_inst = Module.const_get(klass)
      obj = klass_inst.new
      setup_controller(obj, env, vars)
      
      # Run before filters
      response = Fastr::Filter.run_before_filters(obj, klass_inst, action)
      
      # No before filters halted, send to action
      if response.nil?
        response = obj.send(action)
      end

      # Run after filters
      response = Fastr::Filter.run_after_filters(obj, klass_inst, action, response)
      
      code, hdrs, body = *response

      # Merge headers with anything specified in the controller
      hdrs.merge!(obj.headers)
      
      [code, hdrs, body]
    end
    
    def dispatch_public(env, path)
      path = "#{self.app_path}/#{PUBLIC_FOLDER}/#{path[1..(path.length - 1)]}"
      if not File.directory? path and File.exists? path
        f = File.open(path)
        hdrs = {}
        
        type = MIME::Types.type_for(File.basename(path))
        
        hdrs["Content-Type"] = type.to_s if not type.nil?
        
        return [200, hdrs, [f.read]]
      else
        return nil
      end
    end
    
    # Sets up a controller for a request.
    def setup_controller(controller, env, vars)
      controller.env = env
      controller.headers = {}
      
      setup_controller_params(controller, env, vars)

      controller.cookies = Fastr::HTTP.parse_cookies(env)      
      controller.app = self
    end
    
    # Populate the parameters based on the HTTP method.
    def setup_controller_params(controller, env, vars)
      if Fastr::HTTP.method?(env, :get)
        controller.get_params = Fastr::HTTP.parse_query_string(env['QUERY_STRING'])
        controller.params = controller.get_params.merge(vars)
      elsif Fastr::HTTP.method?(env, :post)
        controller.post_params = {}
        controller.post_params = Fastr::HTTP.parse_query_string(env['rack.input'].read) if env['rack.input']
        controller.params = controller.post_params.merge(vars)
      else
        controller.params = vars
      end
    end
    
    # Runs before_dispatch in all plugins.
    #
    # @param env [Hash]
    # @return [Hash]
    def plugin_before_dispatch(env)
      new_env = env
      
      self.plugins.each do |plugin|
        if plugin.respond_to? :before_dispatch
          new_env = plugin.send(:before_dispatch, self, env)
        end
      end
      
      new_env
    end
    
    # Runs after_dispatch in all plugins.
    #
    # @param env [Hash]
    # @return [Hash]
    def plugin_after_dispatch(env, response)
      new_response = response
      
      self.plugins.each do |plugin|
        if plugin.respond_to? :after_dispatch
          new_response = plugin.send(:after_dispatch, self, env, response)
        end
      end
      
      new_response
    end
  end
end