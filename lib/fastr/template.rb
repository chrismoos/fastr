require 'json'

module Fastr
  module Template
    EXTENSIONS = {} unless defined?(EXTENSIONS)
    TEMPLATE_CACHE = {} unless defined?(TEMPLATE_CACHE)
    
    def self.included(kls)
      kls.extend(ClassMethods)
    end
    
    module ClassMethods
      
    end
    
    # Finds the engine for a particular path.
    # 
    # ==== Parameters
    # path<String>:: The path of the file to find an engine for.
    #
    # ==== Returns
    # Class:: The engine.
    def engine_for(path)
      path = File.expand_path(path)      
      EXTENSIONS[path.match(/\.([^\.]*)$/)[1]]
    end
    
    # Get all known template extensions
    #
    # ==== Returns
    #   Array:: Extension strings.
    def template_extensions
      EXTENSIONS.keys
    end
    
    # Registers the extensions that will trigger a particular templating
    # engine.
    # 
    # ==== Parameters
    # engine<Class>:: The class of the engine that is being registered
    # extensions<Array[String]>:: 
    #   The list of extensions that will be registered with this templating
    #   language
    #
    # ==== Raises
    # ArgumentError:: engine does not have a compile_template method.
    #
    # ==== Returns
    # nil
    #
    # ==== Example
    #   Fastr::Template.register_extensions(Fastr::Template::Erubis, ["erb"])
    def self.register_extensions(engine, extensions)
      raise ArgumentError, "The class you are registering does not have a result method" unless
        engine.respond_to?(:result)
      extensions.each{|ext| EXTENSIONS[ext] = engine }
      Fastr::Controller.class_eval <<-HERE
        include #{engine}::Mixin
      HERE
    end
    
    def render(kind, tpl, opts={})
      case kind.to_sym
      when :template then
        render_template(tpl, opts)
      when :partial then
        render_template_to_string(tpl, opts)
      when :text then
        render_text(tpl, opts)
      when :json then
        render_json(tpl, opts)
      else
        raise ArgumentError, "Unknown render type: #{kind.inspect}"
      end
    end
    
    def render_template(tpl_path, opts={})
      unless engine = engine_for(tpl_path)
        raise ArgumentError, "No template engine registered for #{tpl_path}"
      end
      
      @headers = {"Content-Type" => "text/html"}.merge(opts[:headers] || {})
      @response_code = opts[:response_code] || 200
      
      [ @response_code, @headers, [render_template_to_string(tpl_path, opts)] ]
    end
    
    def render_template_to_string(tpl_path, opts={})
      @vars = opts[:vars] || {}
      engine.result(tpl_path, binding())
    end
    
    def render_text(text, opts={})
      @headers = {"Content-Type" => "text/plain"}.merge(opts[:headers] || {})
      @response_code = opts[:response_code] || 200
      [ @response_code, @headers, [text] ]
    end
    
    def render_json(obj, opts={})
      @headers = {"Content-Type" => "application/json"}.merge(opts[:headers] || {})
      @response_code = opts[:response_code] || 200
      [ @response_code, @headers, [obj.to_json.to_s] ]
    end

  end
end