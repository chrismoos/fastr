module Fastr  
  class Settings
    include Fastr::Log
    
    attr_accessor :cache_templates
    
    def initialize(app)
      @app = app
      @cache_templates = true
    end
    
    def log_level=(level)
      Fastr::Log.level = level
    end
  end
end