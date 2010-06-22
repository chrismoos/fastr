module AsyncRecord
  module Connection
    ROOT = File.expand_path(File.dirname(__FILE__))
    
    autoload :MySQL,    "#{ROOT}/connections/mysql"
    
    class Base
      def connect; end
    end
  end
end