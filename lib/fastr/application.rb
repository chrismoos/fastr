require 'logger'
require 'cgi'

module Fastr  
  class Application
    include Fastr::Log
    
    SETTINGS_FILE = "app/config/settings.rb"
    INIT_FILE = "app/config/init.rb"

    attr_accessor :router, :app_path, :settings

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
      self.settings = Fastr::Settings.new(self)
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
        setup_controller(obj, env)
        
        obj.send(action)
      else
        [404, {"Content-Type" => "text/plain"}, "404 Not Found: #{path}"]
      end
    end
    
    private
    
    def setup_controller(controller, env)
      controller.env = env
      controller.params = CGI::parse(env['QUERY_STRING'])
      controller.app = self
    end
    
    #
    # This is used to initialize the application.
    # It runs in a thread because startup depends on EventMachine running
    #
    def boot
      Thread.new do
        sleep 1 until EM.reactor_running?
        
        begin
          log.info "Loading application..."
          
          load_settings
          load_app_classes
          setup_router
          setup_watcher
          
          log.info "Application loaded successfully."
          
          @booting = false
          
          app_init
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
    
    def app_init
      return if not File.exists? INIT_FILE
      
      init_file = File.open(INIT_FILE)
      self.instance_eval(init_file.read)
    end
    
    def load_settings
      return if not File.exists? SETTINGS_FILE
      
      config_file = File.open(SETTINGS_FILE)
      self.instance_eval(config_file.read)
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
    
    def config
      return self.settings
    end
    
    module Handler
      def file_modified
        app.log.debug "Reloading file: #{path}"
        load(path)
      end
    end
  end
end