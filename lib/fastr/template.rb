require 'haml'

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
    
    def render_text(txt)
      [200, {"Content-Type" => 'text/plain'}, txt]
    end
    
    def render_haml(args)
      tpl = args[0][:template]
      
      if @@tpl_cache.has_key? tpl
        haml_engine = @@tpl_cache[tpl]
      else
        tpl_data = File.read("app/views/#{tpl}.haml")
        haml_engine = Haml::Engine.new(tpl_data)
        @@tpl_cache[tpl] = haml_engine
      end
      
      
      resp = haml_engine.render
      
      [200, {"Content-Type" => "text/html"}, resp]
    end
  end
end