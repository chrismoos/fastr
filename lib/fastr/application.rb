require 'logger'

module Fastr  
  class Application
    include Fastr::Log

    attr_accessor :router, :app_path
    
    def initialize(path)
      self.app_path = path
      
      @booting = true
      boot
    end
    
    def dispatch(env)
      return [500, {}, "Server Not Ready"] if @booting
      
      begin 
        do_dispatch(env)
      rescue Exception => e
        bt = e.backtrace.join("\n")
        [500, {}, "Exception: #{e}\n\n#{bt}"]
      end
    end
    
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
        obj = Module.const_get(klass).new
        
        ret = obj.send(action)
        
        #[200, {}, "ok"]
        ret
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
        rescue Fastr::Error => e
          log.error "#{e}"
          puts e.backtrace
          log.fatal "Exiting due to previous errors..."
          exit(1)
        end
      end
    end
    
    def setup_router
      self.router = Fastr::Router.new(self)
      self.router.load
    end
  
    def load_app_classes
      log.debug "Loading application classes..."
      Dir["#{self.app_path}/app/controllers/*.rb"].each do |f|
        log.debug "Loading: #{f}"
        load(f)
      end
    end
    
    def setup_watcher
      this = self
      Handler.send(:define_method, :app) do 
        this
      end
      
      Dir["#{self.app_path}/app/controllers/*.rb"].each do |f|
        EM.watch_file(f, Handler)
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