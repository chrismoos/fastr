require 'fastr/test/logger'
require 'eventmachine'

module Fastr
  module Test
    module Controller
      def self.included(klass)
        klass.extend(ClassMethods)
        set_defaults(klass)
      end
      
      # Sets up the test class.
      def self.set_defaults(klass)
        regex = Regexp.new(/^(\w+)ControllerTest$/)
        match = regex.match(klass.to_s)
        
        if not match.nil?
          klass.instance_variable_set(:@controller_class, match[1].to_s.uncamelcase)
        end
      end
      
      # Runs a test application.
      #
      # @param The code to run.
      def run_test_app(&block)
        EM.kqueue = true if EM.kqueue?
        EM.epoll = true if EM.epoll?
        EM.run do
          app_path = Dir.pwd
          app = Fastr::Test::Application.new(app_path)
          app.boot
          setup_dumb_router(app)
          return block.call(app)
        end
      end
      
      # Sets up a router that has one route. We will always use / when calling dispatch.
      def setup_dumb_router(app)
        app.router.for '/', :to => "dummy#index"
      end
      
      def get(action, options={})
        make_request(:get, action, options)
      end
      
      def post(action, options={})
        make_request(:post, action, options)
      end
      
      def make_request(method, action, options={})
        run_test_app do |app|
          env = {"PATH_INFO" => "/", "REQUEST_METHOD" => method.to_s.upcase}
          case method
          when :get then
            env['QUERY_STRING'] = Fastr::HTTP.build_query_string(options[:params]) if options[:params]
          when :post then
            env['rack.input'] = StringIO.new(Fastr::HTTP.build_query_string(options[:params])) if options[:params]
          end
          
          app.route = {:ok => {:controller => get_controller_class, :action => action}}
          app.dispatch(env)
        end
      end
      
      def get_controller_class
        klass = self.class.instance_variable_get(:@controller_class)
        raise Exception.new("No controller set. Use set_controller.") if klass.nil?
        return klass
      end
      
      module ClassMethods
        def set_controller(controller)
          @controller_class = controller.to_s
        end
      end
    end
  end
end