require 'haml'

module Fastr
  module Template
    class Haml
      
      def self.result(tpl_path, _binding)
        engine = Fastr::Template::TEMPLATE_CACHE[tpl_path]
        unless engine
          engine = ::Haml::Engine.new(File.read("app/views/#{tpl_path}"))
          Fastr::Template::TEMPLATE_CACHE[tpl_path] = engine
        end
        engine.render(_binding)
      end

      module Mixin
      end

      Fastr::Template.register_extensions(self, %w[haml])

    end # Haml
  end # Template
end # Fastr