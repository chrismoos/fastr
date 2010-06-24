module Fastr
  module Test
    class Application < Fastr::Application
      include Fastr::Log
      
      attr_accessor :route
      
      def boot
        load_settings
        Fastr::Plugin.load(self)
        load_app_classes
        setup_router

        @booting = false
        
        plugin_after_boot
        app_init
      end
      
      def dispatch_controller(route, env)
        super(self.route, env)
      end
    end
  end
end