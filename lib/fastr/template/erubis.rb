require 'erubis'

module Fastr
  module Template
    class Erubis
      
      def self.result(tpl_path, _binding, hash_data={})
        eval hash_data.collect{ |k,v| "@#{k} = hash_data[#{k.inspect}];"}.join, _binding
        eruby = Fastr::Template::TEMPLATE_CACHE[tpl_path]
        unless eruby
          eruby = Erubis::Eruby.new(File.read("app/views/#{tpl_path}"))
          Fastr::Template::TEMPLATE_CACHE[tpl_path] = eruby
        end
        eruby.result(_binding)
      end

      module Mixin
      end

      Fastr::Template.register_extensions(self, %w[erb])

    end # Erubis
  end # Template
end # Fastr