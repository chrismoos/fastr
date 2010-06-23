module Fastr
  # The router manages the routes for an application.
  #
  # Routes are configured in the <b>app/config/routes.rb</b> file.
  #
  # = Example
  #
  #   router.draw do |route|
  #     route.for '/:controller/:action'
  #     route.for '/home/:action', :action => '[A-Za-z]+'
  #     route.for '/test', :to => 'home#index'
  #   end
  #
  # @author Chris Moos
  class Router
    include Fastr::Log
    
    # The routes for this router.
    # @return [Array]
    attr_accessor :routes
    
    # The full path to the routes file.
    # @return [String]
    attr_accessor :route_file
    
    def initialize(app)
      @app = app
      self.routes = []
      self.route_file = "#{@app.app_path}/app/config/routes.rb"
      setup_watcher
    end
    
    # Searches the routes for a match given a Rack env.
    #
    # {#match} looks in the {#routes} to find a match.
    #
    # This method looks at PATH_INFO in +env+ to get the current request's path.
    #
    # == Return
    #
    # No Match:
    #
    #   {:error => :not_found}
    #
    # Match:
    #
    #   {:ok => {:controller => 'controller', :action => 'action', :var => 'value'}}
    #
    # @param env [Hash]
    # @return [Hash]
    def match(env)
      self.routes.each do |info|
        
        # If the route didn't specify method(s) to limit by, then all HTTP methods are valid.
        # If the route specified method(s), we check the request's HTTP method and validate
        # that it exists in that list.
        next unless info[:methods].nil? or info[:methods].include?(env["REQUEST_METHOD"].downcase.to_sym)
        
        match = env['PATH_INFO'].match(info[:regex])

        # See if a route matches
        if not match.nil?

          # Map any parameters in our matched string
          vars = {}
          
          info[:vars].each_index do |i|
            var = info[:vars][i]
            vars[var] = match[i+1]
          end

          return {:ok => vars.merge!(info[:hash]) }
        end
      end
      
      {:error => :not_found}
    end
    
    # Loads the routes from {#route_file} and evaluates it within the context of {Fastr::Router}.
    def load
      log.debug "Loading routes from: #{self.route_file}"
      self.routes = []
      
      file = File.open(self.route_file)
      @app.instance_eval(file.read)
    end
    
    # Adds a route for a path and arguments.
    #
    # @param path [String]
    # @param args [Array]
    def for(path, *args)
      arg = args[0]
      log.debug "Adding route, path: #{path}, args: #{args.inspect}"

      match = get_regex_for_route(path, arg)
      hash = get_to_hash(arg)
      route_info = {:regex => match[:regex], :args => arg, :vars => match[:vars], :hash => hash}
      
      # Add the HTTP methods for this route if they exist in options
      route_info[:methods] = arg[:methods] if not arg.nil? and arg.has_key? :methods
      
      self.routes.push(route_info)
    end
    
    # Evaluates the block in the context of the router.
    def draw(&block)
      block.call(self)
    end
    
    private 
    
    def get_to_hash(args)
      hash = {}
      return hash if args.nil?
      if args.has_key? :to
        match = args[:to].match(/(\w+)#(\w+)/)
        hash.merge!(:controller => match[1], :action => match[2]) if not match.nil?
      end
      hash
    end
    
    def get_regex_for_route(path, args)
      vars = []
      regexRoute = path
      
      args = {} if args.nil?
      
      path.scan(/:(\w+)/).each do |var|
        match = '\w+'
        varName = var[0]
        
        if args.has_key? varName.to_sym
          match = args[varName.to_sym]
        end
          regexRoute.gsub!(":#{varName}", "(#{match.to_s})")
        vars.push(varName.to_sym)
      end
      {:regex => "^#{regexRoute}$", :vars => vars}
    end
    
    def setup_watcher
      this = self
      Handler.send(:define_method, :router) do 
        this
      end
      
      EM.watch_file(self.route_file, Handler)
    end
    
    module Handler
      def file_modified
        router.log.info "Routes changed, reloading."
        router.load
      end
    end
  end
end