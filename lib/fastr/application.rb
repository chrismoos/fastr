require 'logger'
require 'cgi'
require 'mime/types'

module Fastr  
  # This class represents a fastr application.
  # @author Chris Moos
  class Application
    include Fastr::Log
    
    # The file that contains application settings.
    SETTINGS_FILE = "app/config/settings.rb"
    
    # The file that is evaluated when fastr finishes booting.
    INIT_FILE = "app/config/init.rb"
    
    # The folder containing static content.
    PUBLIC_FOLDER = "public"

    # The router for this application.
    # @return [Fastr::Router]
    attr_accessor :router
    
    # The full path the application's path.
    # @return [String]
    attr_accessor :app_path
    
    # The settings for this application.
    # @return [Fastr::Settings]
    attr_accessor :settings
    
    # The list of plugins enabled for this application.
    # @return [Array]
    attr_accessor :plugins

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
      self.plugins = []
      @booting = true
      boot
    end
    
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
    
    def plugin_after_dispatch(env, response)
      new_response = response
      
      self.plugins.each do |plugin|
        if plugin.respond_to? :after_dispatch
          new_response = plugin.send(:after_dispatch, self, env, response)
        end
      end
      
      new_response
    end
    
    def plugin_after_boot
      self.plugins.each do |plugin|
        if plugin.respond_to? :after_boot
          new_env = plugin.send(:after_boot, self)
        end
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
        vars = route[:ok]        
        controller = vars[:controller]
        action = vars[:action]
        
        raise Fastr::Error.new("Controller and action not present in route") if controller.nil? or action.nil?
        
        
        klass = "#{controller.capitalize}Controller"
        
        log.info "Routing to controller: #{klass}, action: #{action}"
        
        obj = Module.const_get(klass).new
        setup_controller(obj, env, vars)
        
        code, hdrs, body = *obj.send(action)

        # Merge headers with anything specified in the controller
        hdrs.merge!(obj.headers)
        
        [code, hdrs, body]
      else
        [404, {"Content-Type" => "text/plain"}, "404 Not Found: #{path}"]
      end
    end
    
    private
    
    def dispatch_public(env, path)
      path = "#{self.app_path}/#{PUBLIC_FOLDER}/#{path[1..(path.length - 1)]}"
      if not File.directory? path and File.exists? path
        f = File.open(path)
        hdrs = {}
        
        type = MIME::Types.type_for(File.basename(path))
        
        hdrs["Content-Type"] = type.to_s if not type.nil?
        
        return [200, hdrs, f.read]
      else
        return nil
      end
    end
    
    def setup_controller(controller, env, vars)
      controller.env = env
      controller.params = vars
      controller.headers = {}

      CGI::parse(env['QUERY_STRING']).each do |k,v|
        if v.length == 1
          controller.params[k] = v[0]
        else
          controller.params[k] = v
        end
      end
      
      controller.cookies = get_cookies(env)
      
      
      controller.app = self
    end
    
    def get_cookies(env)
      if env.has_key? "HTTP_COOKIE"
        cookies = env['HTTP_COOKIE'].split(';')
        c = {}
        cookies.each do |cookie|
          info = cookie.strip.split("=")
          if info.length == 2
            c[info[0].strip] = info[1].strip 
          end
        end
        c
      else
        {}
      end
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
          Fastr::Plugin.load(self)
          load_app_classes
          setup_router
          setup_watcher
          
          log.info "Application loaded successfully."
          
          @booting = false
          
          plugin_after_boot
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