module Fastr  
  class Settings
    include Fastr::Log
    
    def initialize(app)
      @app = app
    end
    
    def log_level=(level)
      Fastr::Log.level = level
    end
  end
end