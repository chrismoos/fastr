require 'logger'
require 'cgi'
require 'mime/types'

module Fastr
  # This class represents a fastr application.
  # @author Chris Moos
  class Application
    include Fastr::Log
    include Fastr::Dispatch

    # The file that contains application settings.
    SETTINGS_FILE = "app/config/settings.rb"

    # The file that is evaluated when fastr finishes booting.
    INIT_FILE = "app/config/init.rb"

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

    def plugin_after_boot
      self.plugins.each do |plugin|
        if plugin.respond_to? :after_boot
          new_env = plugin.send(:after_boot, self)
        end
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
          log.info "Loading application..."
          app_init
          load_settings
          Fastr::Plugin.load(self)
          load_app_classes
          setup_router
          setup_watcher

          log.info "Application loaded successfully."

          @booting = false

          plugin_after_boot
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
      settings_file = "#{self.app_path}/#{SETTINGS_FILE}"
      return if not File.exists? settings_file

      config_file = File.open(settings_file)
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
        reload(path)
      end

      def reload(path)
        filename = File.basename(path)

        # Is it a controller?
        match = /^((\w+)_controller).rb$/.match(filename)
        reload_controller(match[1]) if not match.nil?

        load(path)
      end

      def reload_controller(name)
        Object.send(:remove_const, name.camelcase.to_sym)
      end
    end
  end
end
