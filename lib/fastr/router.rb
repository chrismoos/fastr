module Fastr
  class Router
    include Fastr::Log
    
    attr_accessor :routes, :route_file
    
    def initialize(app)
      @app = app
      self.routes = []
      self.route_file = "#{@app.app_path}/app/config/routes.rb"
      setup_watcher
    end
    
    def match(env)
      self.routes.each do |info|
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
    
    def load
      log.debug "Loading routes from: #{self.route_file}"
      self.routes = []
      
      begin
        file = File.open(self.route_file)
        @app.instance_eval(file.read)
      rescue => e
        raise Fastr::Error.new("Unable to load routes: #{e}")
      end
    end
    
    def for(path, args)
      log.debug "Adding route, path: #{path}, args: #{args.inspect}"

      match = get_regex_for_route(path, args)
      hash = get_to_hash(args)
      
      self.routes.push({:regex => match[:regex], :args => args, :vars => match[:vars], :hash => hash})
    end
    
    def draw(&block)
      block.call(self)
    end
    
    def file_modified
      puts "changed!"
    end
    
    private 
    
    def get_to_hash(args)
      hash = {}
      
      if args.has_key? :to
        match = args[:to].match(/(\w+)#(\w+)/)
        hash.merge!(:controller => match[1], :action => match[2]) if not match.nil?
      end
      hash
    end
    
    def get_regex_for_route(path, args)
      vars = []
      regexRoute = path
      
      path.scan(/:(\w+)/).each do |var|
        match = '\w+'
        varName = var[0]
        
        if args.has_key? varName.to_sym
          match = args[varName.to_sym]
        end
          regexRoute.gsub!(":#{var}", "(#{match.to_s})")
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