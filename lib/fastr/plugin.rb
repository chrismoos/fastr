module Fastr
  module Plugin
    include Fastr::Log

    PLUGIN_PATH = "custom/plugins"

    def self.load(app)
      logger.debug "Loading plugins..."

      if File.directory? "#{app.app_path}/#{PLUGIN_PATH}"
        load_plugins_dir(app)
      end
    end

    def self.load_plugins_dir(app)
      Dir.foreach("#{app.app_path}/#{PLUGIN_PATH}") do |filename|
        if filename != '.' and filename != '..'
          load_plugin(app, filename, "#{app.app_path}/#{PLUGIN_PATH}/#{filename}")
        end
      end
    end

    def self.load_plugin(app, name, dir)
      plugin_name = "#{name.camelcase}Plugin"
      logger.debug "Loading plugin #{plugin_name}..."

      begin
        require("#{dir}/plugin.rb")
        m = Module.const_get(plugin_name)

        if File.directory? "#{dir}/lib"
          Dir.glob(File.join("#{dir}/lib/**", "*.rb")).each { |f| require("#{f}") }
        end

        app.plugins << m
      rescue => e
        logger.error "Unable to load plugin: #{e}"
      end
    end
  end
end
