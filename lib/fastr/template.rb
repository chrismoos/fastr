require 'haml'
require 'json'

module Fastr
  module Template
    @@tpl_cache = {}
    
    
    def self.included(kls)
      kls.extend(ClassMethods)
    end
    
    module ClassMethods
      
    end
    
    def render(type, *args)
      method = "render_#{type}".to_sym
      if self.respond_to? method
        self.send(method, args)
      else  
        raise Exception.new("No render found for: #{type}")
      end
    end
    
    def render_text(*args)
      [200, {"Content-Type" => 'text/plain'}, [args[0]]]
    end
    
    def render_json(*args)
      [200, {"Content-Type" => 'application/json'}, args[0][0].to_json.to_s]
    end
    
    def render_haml(args)
      tpl = args[0][:template]
      
      if @@tpl_cache.has_key? tpl
        haml_engine = @@tpl_cache[tpl]
      else
        tpl_data = File.read("app/views/#{tpl}.haml")
        haml_engine = Haml::Engine.new(tpl_data)
        @@tpl_cache[tpl] = haml_engine if self.app.settings.cache_templates
      end

      resp = haml_engine.render(self)
      
      [200, {"Content-Type" => "text/html"}, [resp]]
    end
  end
end