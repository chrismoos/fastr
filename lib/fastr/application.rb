require 'logger'

module Fastr  
  class Application
    include Fastr::Log

    attr_accessor :router, :app_path
    
    # These are resources we are watching to change.
    # They will be reloaded upon change.
    @@load_paths = {
      :controller => "app/controllers/*.rb",
      :model => "app/models/*.rb",
      :lib => "lib/*.rb"
    }

    # Sets the application's initial state to booting and then kicks off the boot.
    def initialize(path)
      self.app_path = path
      @booting = true
      boot
    end
    
    # Convenience wrapper for do_dispatch
    # This is the heart of the server, called indirectly by a Rack aware server. 
    def dispatch(env)
      return [500, {}, "Server Not Ready"] if @booting
      
      begin 
        do_dispatch(env)
      rescue Exception => e
        bt = e.backtrace.join("\n")
        [500, {}, "Exception: #{e}\n\n#{bt}"]
      end
    end
    
    # Route, instantiate controller, return response from controller's action.
    def do_dispatch(env)
      path = env['PATH_INFO']
      
      log.debug "Checking for routes that match: #{path}"
      route = router.match(env)

      if route.has_key? :ok
        vars = route[:ok]        
        controller = vars[:controller]
        action = vars[:action]
        
        raise Fastr::Error.new("Controller and action not present in route") if controller.nil? or action.nil?
        
        
        klass = "#{controller.capitalize}Controller"
        
        log.info "Routing to controller: #{klass}, action: #{action}"
        
        obj = Module.const_get(klass).new
        obj.env = env
        
        obj.send(action)
      else
        [404, {"Content-Type" => "text/plain"}, "404 Not Found: #{path}"]
      end
    end
    
    private
    
    #
    # This is used to initialize the application.
    # It runs in a thread because startup depends on EventMachine running
    #
    def boot
      Thread.new do
        sleep 1 until EM.reactor_running?
        
        begin
          load_app_classes
          setup_router
          setup_watcher
          
          @booting = false
        rescue Exception => e
          log.error "#{e}"
          puts e.backtrace
          log.fatal "Exiting due to previous errors..."
          exit(1)
        end
      end
    end
    
    # Initializes the router and loads the routes.
    def setup_router
      self.router = Fastr::Router.new(self)
      self.router.load
    end
  
    # Loads all application classes. Called on startup.
    def load_app_classes
      @@load_paths.each do |name, path|
        log.debug "Loading #{name} classes..."
        
        Dir["#{self.app_path}/#{path}"].each do |f|
          log.debug "Loading: #{f}"
          load(f)
        end
      end
    end
    
    
    # Watch for any file changes in the load paths.
    def setup_watcher
      this = self
      Handler.send(:define_method, :app) do 
        this
      end
      
      @@load_paths.each do |name, path|
        Dir["#{self.app_path}/#{path}"].each do |f|
          EM.watch_file(f, Handler)
        end
      end
    end
    
    module Handler
      def file_modified
        app.log.info "Reloading file: #{path}"
        load(path)
      end
    end
  end
end